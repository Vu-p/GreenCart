namespace GreenCart.Api.Models;

public sealed class Product
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public required string Name { get; set; }
    public required string Description { get; set; }
    public decimal Price { get; set; }
    public int Stock { get; set; }
    public required string ImageUrl { get; set; }
    public Guid CategoryId { get; set; }
    public Category? Category { get; set; }
    public bool IsOrganic { get; set; }
    public bool IsDeal { get; set; }
}
