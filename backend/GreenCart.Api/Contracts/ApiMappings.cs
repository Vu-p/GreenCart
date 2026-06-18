using GreenCart.Api.Models;

namespace GreenCart.Api.Contracts;

public static class ApiMappings
{
    public const decimal StandardDeliveryFee = 2.90m;

    public static ProductResponse ToResponse(Product product) =>
        new(
            product.Id,
            product.Name,
            product.Description,
            product.Price,
            product.Stock,
            product.ImageUrl,
            product.CategoryId,
            product.Category?.Name ?? string.Empty,
            product.IsOrganic,
            product.IsDeal);

    public static CartResponse ToResponse(Cart? cart)
    {
        var items = cart?.Items
            .Where(item => item.Product is not null)
            .Select(ToResponse)
            .ToList() ?? [];
        var subtotal = items.Sum(item => item.LineTotal);
        var deliveryFee = items.Count == 0 ? 0 : StandardDeliveryFee;
        return new CartResponse(items, subtotal, deliveryFee, subtotal + deliveryFee);
    }

    public static CartItemResponse ToResponse(CartItem item)
    {
        var product = item.Product ?? throw new InvalidOperationException("Cart item product was not loaded.");
        return new CartItemResponse(
            product.Id,
            product.Name,
            product.ImageUrl,
            product.Price,
            item.Quantity,
            product.Price * item.Quantity,
            product.Stock);
    }

    public static OrderResponse ToResponse(Order order) =>
        new(
            order.Id,
            order.OrderNumber,
            order.Status,
            order.PaymentStatus,
            order.DeliveryAddress,
            order.DeliveryPhone,
            order.DeliverySlot,
            order.SubstitutionPreference,
            order.Subtotal,
            order.DeliveryFee,
            order.Total,
            order.Items.Select(ToResponse).ToList(),
            order.CreatedAt,
            order.UpdatedAt,
            order.Review is not null);

    public static OrderItemResponse ToResponse(OrderItem item) =>
        new(
            item.Id,
            item.ProductId,
            item.ProductName,
            item.ImageUrl,
            item.UnitPrice,
            item.Quantity,
            item.UnitPrice * item.Quantity);

    public static OrderReviewResponse ToResponse(OrderReview review) =>
        new(
            review.Id,
            review.OrderId,
            review.Rating,
            review.Comment,
            review.ProductReviews
                .Select(productReview => new ProductReviewResponse(
                    productReview.Id,
                    productReview.ProductId,
                    productReview.Rating,
                    productReview.Comment,
                    productReview.CreatedAt))
                .ToList(),
            review.CreatedAt);
}
