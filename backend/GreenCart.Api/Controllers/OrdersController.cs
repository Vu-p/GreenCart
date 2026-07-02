using System.Security.Claims;
using GreenCart.Api.Contracts;
using GreenCart.Api.Data;
using GreenCart.Api.Models;
using GreenCart.Api.Options;
using GreenCart.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;

namespace GreenCart.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/orders")]
public sealed class OrdersController(
    AppDbContext dbContext,
    IPayOsPaymentService payOsPayments,
    IOptions<PayOsOptions> payOsOptions) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<OrderResponse>>> GetOrders(CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var orders = (await BaseOrderQuery()
            .Where(order => order.UserId == userId.Value)
            .ToListAsync(cancellationToken))
            .OrderByDescending(order => order.CreatedAt)
            .ToList();

        return Ok(orders.Select(ApiMappings.ToResponse).ToList());
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<OrderResponse>> GetOrder(string id, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var order = await FindOrderAsync(userId.Value, id, cancellationToken);
        return order is null ? NotFound() : Ok(ApiMappings.ToResponse(order));
    }

    [HttpPost("{id}/repay")]
    public async Task<ActionResult<CheckoutPaymentResponse>> RepayOrder(string id, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var order = await FindOrderAsync(userId.Value, id, cancellationToken);
        if (order is null)
        {
            return NotFound();
        }

        if (order.PaymentStatus == PaymentStatuses.Paid || order.Status == OrderStatuses.Cancelled)
        {
            return Conflict(new { message = "Order is already paid or cancelled." });
        }

        if (order.PayOsOrderCode is null)
        {
            order.PayOsOrderCode = await CreatePayOsOrderCodeAsync(cancellationToken);
        }

        var returnUrl = AppendQueryString(ResolvePayOsUrl(payOsOptions.Value.ReturnUrl, "return"), "orderId", order.Id.ToString());
        var cancelUrl = AppendQueryString(ResolvePayOsUrl(payOsOptions.Value.CancelUrl, "cancel"), "orderId", order.Id.ToString());
        var paymentLink = await payOsPayments.CreatePaymentLinkAsync(order, returnUrl, cancelUrl);
        
        order.PayOsPaymentLinkId = paymentLink.PaymentLinkId;
        order.PayOsCheckoutUrl = paymentLink.CheckoutUrl;
        order.UpdatedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new CheckoutPaymentResponse(
            ApiMappings.ToResponse(order),
            paymentLink.CheckoutUrl,
            paymentLink.PaymentLinkId,
            paymentLink.QrCode,
            order.PayOsOrderCode.Value));
    }

    [HttpPost("{id}/cancel")]
    public async Task<ActionResult<OrderResponse>> CancelOrder(string id, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var order = await FindOrderAsync(userId.Value, id, cancellationToken);
        if (order is null)
        {
            return NotFound();
        }

        if (order.Status is OrderStatuses.Delivering or OrderStatuses.Completed or OrderStatuses.Cancelled)
        {
            return Conflict(new { message = "Order cannot be cancelled at this stage." });
        }

        order.Status = OrderStatuses.Cancelled;
        order.PaymentStatus = PaymentStatuses.Cancelled;
        order.UpdatedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);

        return Ok(ApiMappings.ToResponse(order));
    }

    private IQueryable<Order> BaseOrderQuery() =>
        dbContext.Orders
            .Include(order => order.Items)
            .Include(order => order.Review);

    private async Task<Order?> FindOrderAsync(Guid userId, string id, CancellationToken cancellationToken)
    {
        var query = BaseOrderQuery().Where(order => order.UserId == userId);
        return Guid.TryParse(id, out var orderId)
            ? await query.SingleOrDefaultAsync(order => order.Id == orderId, cancellationToken)
            : await query.SingleOrDefaultAsync(order => order.OrderNumber == id, cancellationToken);
    }

    private Guid? GetUserId()
    {
        var rawId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(rawId, out var userId) ? userId : null;
    }

    private async Task<long> CreatePayOsOrderCodeAsync(CancellationToken cancellationToken)
    {
        long orderCode;
        do
        {
            orderCode = (DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1000) + Random.Shared.Next(100, 999);
        }
        while (await dbContext.Orders.AnyAsync(order => order.PayOsOrderCode == orderCode, cancellationToken));

        return orderCode;
    }

    private string ResolvePayOsUrl(string? configuredUrl, string action)
    {
        if (!string.IsNullOrWhiteSpace(configuredUrl))
        {
            return configuredUrl;
        }

        return $"{Request.Scheme}://{Request.Host}{Request.PathBase}/api/payments/payos/{action}";
    }

    private static string AppendQueryString(string url, string key, string value)
    {
        var separator = url.Contains('?') ? '&' : '?';
        return $"{url}{separator}{Uri.EscapeDataString(key)}={Uri.EscapeDataString(value)}";
    }
}
