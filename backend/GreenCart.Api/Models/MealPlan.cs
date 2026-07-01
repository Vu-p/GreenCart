namespace GreenCart.Api.Models;

public sealed class MealPlan
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public required string Title { get; set; }
    public required string Description { get; set; }
    public required string ImageUrl { get; set; }
    public int PrepMinutes { get; set; }
    public int CookMinutes { get; set; }
    public int Servings { get; set; }
    public required string Difficulty { get; set; }
    public required string Instructions { get; set; }
    public bool IsFeatured { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public ICollection<MealIngredient> Ingredients { get; set; } = new List<MealIngredient>();
}
