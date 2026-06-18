namespace GreenCart.Api.Models;

public sealed class Order
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public required string OrderNumber { get; set; }
    public Guid UserId { get; set; }
    public User? User { get; set; }
    public string Status { get; set; } = OrderStatuses.Confirmed;
    public string PaymentStatus { get; set; } = PaymentStatuses.Paid;
    public required string DeliveryAddress { get; set; }
    public string? DeliveryPhone { get; set; }
    public string? DeliverySlot { get; set; }
    public string? SubstitutionPreference { get; set; }
    public decimal Subtotal { get; set; }
    public decimal DeliveryFee { get; set; }
    public decimal Total { get; set; }
    public ICollection<OrderItem> Items { get; set; } = new List<OrderItem>();
    public OrderReview? Review { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedAt { get; set; } = DateTimeOffset.UtcNow;
}
