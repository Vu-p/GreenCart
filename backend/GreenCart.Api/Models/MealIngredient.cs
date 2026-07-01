namespace GreenCart.Api.Models;

public sealed class MealIngredient
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public Guid MealPlanId { get; set; }
    public MealPlan? MealPlan { get; set; }
    public Guid ProductId { get; set; }
    public Product? Product { get; set; }
    public required string QuantityText { get; set; }
    public bool IsOptional { get; set; }
    public int SortOrder { get; set; }
}
