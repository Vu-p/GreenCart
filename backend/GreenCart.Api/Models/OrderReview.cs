namespace GreenCart.Api.Models;

public sealed class OrderReview
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid OrderId { get; set; }
    public Order? Order { get; set; }
    public Guid UserId { get; set; }
    public User? User { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public ICollection<ProductReview> ProductReviews { get; set; } = new List<ProductReview>();
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
