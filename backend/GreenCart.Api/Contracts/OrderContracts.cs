namespace GreenCart.Api.Contracts;

public sealed record OrderResponse(
    Guid Id,
    string OrderNumber,
    string Status,
    string PaymentStatus,
    string DeliveryAddress,
    string? DeliveryPhone,
    string? SubstitutionPreference,
    decimal Subtotal,
    decimal DeliveryFee,
    decimal Total,
    IReadOnlyList<OrderItemResponse> Items,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    bool HasReview);

public sealed record OrderItemResponse(
    Guid Id,
    Guid? ProductId,
    string ProductName,
    string ImageUrl,
    decimal UnitPrice,
    int Quantity,
    decimal LineTotal);

public sealed record UpdateOrderStatusRequest(string Status);
