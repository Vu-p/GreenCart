using System.Text.Json;
using GreenCart.Api.Data;
using GreenCart.Api.Hubs;
using GreenCart.Api.Models;
using GreenCart.Api.Options;
using GreenCart.Api.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using PayOS.Exceptions;
using PayOS.Models.Webhooks;

namespace GreenCart.Api.Controllers;

[ApiController]
[Route("api/payments/payos")]
public sealed class PayOsPaymentsController(
    AppDbContext dbContext,
    IPayOsPaymentService payOsPayments,
    IOptions<PayOsOptions> payOsOptions,
    IHubContext<OrderHub> orderHub,
    ILogger<PayOsPaymentsController> logger) : ControllerBase
{
    [HttpPost("webhook")]
    public async Task<IActionResult> Webhook(Webhook webhook, CancellationToken cancellationToken)
    {
        WebhookData data;
        try
        {
            data = await payOsPayments.VerifyWebhookAsync(webhook);
        }
        catch (WebhookException ex)
        {
            logger.LogWarning(ex, "Rejected payOS webhook because signature verification failed.");
            return BadRequest(new { message = "Invalid payOS webhook signature." });
        }

        var order = await LoadOrderByPayOsCodeAsync(data.OrderCode, cancellationToken);
        if (order is null)
        {
            logger.LogInformation("Ignoring payOS webhook for unknown order code {OrderCode}.", data.OrderCode);
            return Ok();
        }

        var expectedAmount = payOsPayments.ToPayOsAmount(order.Total);
        if (data.Amount != expectedAmount)
        {
            logger.LogWarning(
                "Rejected payOS webhook for order {OrderNumber}: expected {ExpectedAmount}, got {WebhookAmount}.",
                order.OrderNumber,
                expectedAmount,
                data.Amount);
            return BadRequest(new { message = "Payment amount does not match the order total." });
        }

        if (webhook.Success && data.Code == "00")
        {
            await MarkOrderPaidAsync(order, data.PaymentLinkId, cancellationToken);
        }

        return Ok();
    }

    [HttpGet("return")]
    public async Task<IActionResult> Return([FromQuery] long? orderCode, [FromQuery] Guid? orderId, CancellationToken cancellationToken)
    {
        var order = await LoadOrderAsync(orderCode, orderId, cancellationToken);
        if (order is null || order.PayOsOrderCode is null)
        {
            return Redirect(payOsOptions.Value.AppCancelUrl);
        }

        var paymentStatus = await payOsPayments.GetPaymentStatusAsync(order.PayOsOrderCode.Value);
        if (paymentStatus.IsPaid)
        {
            await MarkOrderPaidAsync(order, paymentStatus.PaymentLinkId, cancellationToken);
            return Redirect(BuildAppUrl(payOsOptions.Value.AppSuccessUrl, order));
        }

        if (paymentStatus.IsCancelled)
        {
            await MarkOrderCancelledAsync(order, paymentStatus.PaymentLinkId, cancellationToken);
        }

        return Redirect(BuildAppUrl(payOsOptions.Value.AppCancelUrl, order));
    }

    [HttpGet("cancel")]
    public async Task<IActionResult> Cancel([FromQuery] long? orderCode, [FromQuery] Guid? orderId, CancellationToken cancellationToken)
    {
        var order = await LoadOrderAsync(orderCode, orderId, cancellationToken);
        if (order is null)
        {
            return Redirect(payOsOptions.Value.AppCancelUrl);
        }

        await MarkOrderCancelledAsync(order, order.PayOsPaymentLinkId, cancellationToken);
        return Redirect(BuildAppUrl(payOsOptions.Value.AppCancelUrl, order));
    }

    private async Task<Order?> LoadOrderAsync(long? orderCode, Guid? orderId, CancellationToken cancellationToken)
    {
        var query = BaseOrderQuery();
        if (orderId is not null)
        {
            return await query.SingleOrDefaultAsync(order => order.Id == orderId, cancellationToken);
        }

        return orderCode is null
            ? null
            : await query.SingleOrDefaultAsync(order => order.PayOsOrderCode == orderCode, cancellationToken);
    }

    private Task<Order?> LoadOrderByPayOsCodeAsync(long orderCode, CancellationToken cancellationToken) =>
        BaseOrderQuery().SingleOrDefaultAsync(order => order.PayOsOrderCode == orderCode, cancellationToken);

    private IQueryable<Order> BaseOrderQuery() =>
        dbContext.Orders
            .Include(order => order.Items)
            .Include(order => order.Review);

    private async Task MarkOrderPaidAsync(Order order, string? paymentLinkId, CancellationToken cancellationToken)
    {
        if (order.PaymentStatus == PaymentStatuses.Paid)
        {
            return;
        }

        order.PaymentStatus = PaymentStatuses.Paid;
        order.Status = order.Status == OrderStatuses.Pending ? OrderStatuses.Confirmed : order.Status;
        order.PayOsPaymentLinkId = string.IsNullOrWhiteSpace(paymentLinkId) ? order.PayOsPaymentLinkId : paymentLinkId;
        order.UpdatedAt = DateTimeOffset.UtcNow;

        await SaveOrderPaymentEventAsync(order, "OrderPaymentPaid", cancellationToken);
    }

    private async Task MarkOrderCancelledAsync(Order order, string? paymentLinkId, CancellationToken cancellationToken)
    {
        if (order.PaymentStatus == PaymentStatuses.Paid || order.Status == OrderStatuses.Cancelled)
        {
            return;
        }

        await RestoreReservedStockAsync(order, cancellationToken);
        order.PaymentStatus = PaymentStatuses.Cancelled;
        order.Status = OrderStatuses.Cancelled;
        order.PayOsPaymentLinkId = string.IsNullOrWhiteSpace(paymentLinkId) ? order.PayOsPaymentLinkId : paymentLinkId;
        order.UpdatedAt = DateTimeOffset.UtcNow;

        await SaveOrderPaymentEventAsync(order, "OrderPaymentCancelled", cancellationToken);
    }

    private async Task RestoreReservedStockAsync(Order order, CancellationToken cancellationToken)
    {
        foreach (var item in order.Items.Where(item => item.ProductId is not null))
        {
            var product = await dbContext.Products.SingleOrDefaultAsync(product => product.Id == item.ProductId, cancellationToken);
            if (product is not null)
            {
                product.Stock += item.Quantity;
            }
        }
    }

    private async Task SaveOrderPaymentEventAsync(Order order, string eventType, CancellationToken cancellationToken)
    {
        var payload = JsonSerializer.Serialize(new
        {
            order.Id,
            order.OrderNumber,
            order.Status,
            order.PaymentStatus,
            order.UpdatedAt
        });

        dbContext.RealtimeEvents.Add(new RealtimeEvent
        {
            UserId = order.UserId,
            OrderId = order.Id,
            Type = eventType,
            Payload = payload
        });

        dbContext.Notifications.Add(new Notification
        {
            UserId = order.UserId,
            Title = eventType == "OrderPaymentPaid" ? "Thanh toán thành công" : "Đã hủy thanh toán",
            Message = eventType == "OrderPaymentPaid" 
                ? $"Đơn hàng {order.OrderNumber} đã được thanh toán thành công qua PayOS." 
                : $"Thanh toán cho đơn hàng {order.OrderNumber} đã bị hủy.",
            Type = "Payment",
            ReferenceId = order.Id
        });

        await dbContext.SaveChangesAsync(cancellationToken);
        await orderHub.Clients.Group(OrderHub.OrderGroup(order.Id.ToString())).SendAsync(eventType, payload, cancellationToken);
        await orderHub.Clients.Group(OrderHub.OrderGroup(order.OrderNumber)).SendAsync(eventType, payload, cancellationToken);
        await orderHub.Clients.Group(OrderHub.UserGroup(order.UserId.ToString())).SendAsync(eventType, payload, cancellationToken);
        await orderHub.Clients.Group(OrderHub.UserGroup(order.UserId.ToString())).SendAsync("ReceiveNotification", new
        {
            title = eventType == "OrderPaymentPaid" ? "Thanh toán thành công" : "Đã hủy thanh toán",
            message = eventType == "OrderPaymentPaid" 
                ? $"Đơn hàng {order.OrderNumber} đã được thanh toán thành công qua PayOS." 
                : $"Thanh toán cho đơn hàng {order.OrderNumber} đã bị hủy.",
            type = "Payment",
            referenceId = order.Id
        }, cancellationToken);
    }

    private static string BuildAppUrl(string baseUrl, Order order)
    {
        var separator = baseUrl.Contains('?') ? '&' : '?';
        return string.Concat(
            baseUrl,
            separator,
            "orderId=",
            Uri.EscapeDataString(order.Id.ToString()),
            "&orderNumber=",
            Uri.EscapeDataString(order.OrderNumber));
    }
}
