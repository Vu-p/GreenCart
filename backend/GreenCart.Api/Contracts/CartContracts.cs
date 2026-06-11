using System.ComponentModel.DataAnnotations;

namespace GreenCart.Api.Contracts;

public sealed record CartItemRequest(
    [Required] Guid ProductId,
    [Range(1, 999)] int Quantity);

public sealed record UpdateCartItemRequest([Range(1, 999)] int Quantity);

public sealed record CartResponse(
    IReadOnlyList<CartItemResponse> Items,
    decimal Subtotal,
    decimal DeliveryFee,
    decimal Total);

public sealed record CartItemResponse(
    Guid ProductId,
    string ProductName,
    string ImageUrl,
    decimal UnitPrice,
    int Quantity,
    decimal LineTotal,
    int Stock);
