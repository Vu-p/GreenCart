using System.ComponentModel.DataAnnotations;

namespace GreenCart.Api.Contracts;

public sealed record CheckoutPreviewResponse(
    IReadOnlyList<CartItemResponse> Items,
    decimal Subtotal,
    decimal DeliveryFee,
    decimal Total,
    string? DeliveryAddress,
    string? DeliveryPhone,
    string? SubstitutionPreference);

public sealed record CheckoutRequest(
    [Required, MinLength(5), MaxLength(500)] string DeliveryAddress,
    [MaxLength(32)] string? DeliveryPhone,
    [MaxLength(120)] string? DeliverySlot,
    [MaxLength(500)] string? SubstitutionPreference);

public sealed record CheckoutPaymentResponse(
    OrderResponse Order,
    string CheckoutUrl,
    string PaymentLinkId,
    string QrCode,
    long PayOsOrderCode);

public sealed record UpdateSubstitutionRequest([MaxLength(500)] string? SubstitutionPreference);

public sealed record SubstitutionResponse(string? SubstitutionPreference);
