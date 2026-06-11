namespace GreenCart.Api.Models;

public sealed class ProductReview
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid OrderReviewId { get; set; }
    public OrderReview? OrderReview { get; set; }
    public Guid ProductId { get; set; }
    public Product? Product { get; set; }
    public int Rating { get; set; }
    public string? Comment { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}
