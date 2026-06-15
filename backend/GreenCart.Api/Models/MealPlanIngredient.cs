namespace GreenCart.Api.Models;

public sealed class MealPlanIngredient
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid MealPlanId { get; set; }

    public MealPlan MealPlan { get; set; } = null!;

    public Guid ProductId { get; set; }

    public Product Product { get; set; } = null!;

    public string QuantityLabel { get; set; } = "";
}