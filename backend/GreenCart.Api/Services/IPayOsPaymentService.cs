using GreenCart.Api.Models;
using PayOS.Models.Webhooks;

namespace GreenCart.Api.Services;

public interface IPayOsPaymentService
{
    long ToPayOsAmount(decimal amount);

    Task<PayOsPaymentLink> CreatePaymentLinkAsync(
        Order order,
        string returnUrl,
        string cancelUrl);

    Task<PayOsPaymentStatus> GetPaymentStatusAsync(long orderCode);

    Task<WebhookData> VerifyWebhookAsync(Webhook webhook);
}

public sealed record PayOsPaymentLink(
    string CheckoutUrl,
    string PaymentLinkId,
    string QrCode,
    long Amount,
    string ProviderStatus);

public sealed record PayOsPaymentStatus(
    string PaymentLinkId,
    long Amount,
    long AmountPaid,
    long AmountRemaining,
    string ProviderStatus,
    bool IsPaid,
    bool IsCancelled);
