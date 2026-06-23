using GreenCart.Api.Models;
using GreenCart.Api.Options;
using Microsoft.Extensions.Options;
using PayOS;
using PayOS.Models.V2.PaymentRequests;
using PayOS.Models.Webhooks;

namespace GreenCart.Api.Services;

public sealed class PayOsPaymentService(
    IOptions<PayOsOptions> options,
    ILogger<PayOsPaymentService> logger) : IPayOsPaymentService
{
    public long ToPayOsAmount(decimal amount)
    {
        var multiplier = options.Value.AmountMultiplier <= 0 ? 1m : options.Value.AmountMultiplier;
        return decimal.ToInt64(decimal.Round(amount * multiplier, 0, MidpointRounding.AwayFromZero));
    }

    public async Task<PayOsPaymentLink> CreatePaymentLinkAsync(
        Order order,
        string returnUrl,
        string cancelUrl)
    {
        if (order.PayOsOrderCode is null)
        {
            throw new InvalidOperationException("Order is missing a payOS order code.");
        }

        var amount = ToPayOsAmount(order.Total);
        using var client = CreateClient();
        var response = await client.PaymentRequests.CreateAsync(new CreatePaymentLinkRequest
        {
            OrderCode = order.PayOsOrderCode.Value,
            Amount = amount,
            Description = CreateDescription(order.OrderNumber),
            ReturnUrl = returnUrl,
            CancelUrl = cancelUrl,
            BuyerPhone = order.DeliveryPhone,
            BuyerAddress = order.DeliveryAddress,
            Items =
            [
                new PaymentLinkItem
                {
                    Name = $"GreenCart {order.OrderNumber}",
                    Quantity = 1,
                    Price = amount,
                    Unit = "order"
                }
            ]
        });

        return new PayOsPaymentLink(
            response.CheckoutUrl,
            response.PaymentLinkId,
            response.QrCode,
            response.Amount,
            response.Status.ToString());
    }

    public async Task<PayOsPaymentStatus> GetPaymentStatusAsync(long orderCode)
    {
        using var client = CreateClient();
        var paymentLink = await client.PaymentRequests.GetAsync(orderCode);
        return new PayOsPaymentStatus(
            paymentLink.Id,
            paymentLink.Amount,
            paymentLink.AmountPaid,
            paymentLink.AmountRemaining,
            paymentLink.Status.ToString(),
            paymentLink.Status == PaymentLinkStatus.Paid,
            paymentLink.Status is PaymentLinkStatus.Cancelled or PaymentLinkStatus.Expired or PaymentLinkStatus.Failed);
    }

    public async Task<WebhookData> VerifyWebhookAsync(Webhook webhook)
    {
        using var client = CreateClient();
        return await client.Webhooks.VerifyAsync(webhook);
    }

    private PayOSClient CreateClient()
    {
        var payOsOptions = options.Value;
        if (string.IsNullOrWhiteSpace(payOsOptions.ClientId) ||
            string.IsNullOrWhiteSpace(payOsOptions.ApiKey) ||
            string.IsNullOrWhiteSpace(payOsOptions.ChecksumKey))
        {
            throw new InvalidOperationException("PayOS credentials are missing. Configure PayOS:ClientId, PayOS:ApiKey, and PayOS:ChecksumKey.");
        }

        return new PayOSClient(new PayOS.PayOSOptions
        {
            ClientId = payOsOptions.ClientId,
            ApiKey = payOsOptions.ApiKey,
            ChecksumKey = payOsOptions.ChecksumKey,
            PartnerCode = string.IsNullOrWhiteSpace(payOsOptions.PartnerCode) ? null : payOsOptions.PartnerCode,
            Logger = logger,
            LogLevel = LogLevel.Warning
        });
    }

    private static string CreateDescription(string orderNumber)
    {
        var normalized = new string(orderNumber.Where(char.IsLetterOrDigit).ToArray()).ToUpperInvariant();
        return normalized.Length <= 9 ? normalized : normalized[..9];
    }
}
