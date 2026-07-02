namespace GreenCart.Api.Models;

public sealed class ProductSubstitution
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid OrderId { get; set; }
    public Order? Order { get; set; }
    public Guid OrderItemId { get; set; }
    public OrderItem? OrderItem { get; set; }
    public Guid OriginalProductId { get; set; }
    public Product? OriginalProduct { get; set; }
    public Guid ReplacementProductId { get; set; }
    public Product? ReplacementProduct { get; set; }
    public string Status { get; set; } = "PendingCustomerDecision";
    public string? Note { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
