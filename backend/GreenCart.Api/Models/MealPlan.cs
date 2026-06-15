namespace GreenCart.Api.Models;
public sealed class MealPlan
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public required string Name { get; set; }

    public string? Description { get; set; }

    public int Minutes { get; set; }

    public string Category { get; set; } = "";

    public string? ImageUrl { get; set; }

    public ICollection<MealPlanIngredient> Ingredients { get; set; }
        = new List<MealPlanIngredient>();
}