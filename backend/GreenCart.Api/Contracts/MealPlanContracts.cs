namespace GreenCart.Api.Contracts;

public sealed record MealPlanResponse(
    Guid Id,
    string Name,
    string? Description,
    string? ImageUrl,
    int Minutes,
    string Category
);

public sealed record MealPlanIngredientResponse(
    Guid Id,
    Guid ProductId,
    string ProductName,
    string QuantityLabel,
    decimal Price,
    int Stock
);

public sealed record MealPlanDetailResponse(
    Guid Id,
    string Name,
    string? Description,
    string? ImageUrl,
    int Minutes,
    string Category,
    IReadOnlyList<MealPlanIngredientResponse> Ingredients
);

public sealed record AddMealPlanIngredientsRequest(
    List<Guid> IngredientIds,
    bool AddAll
);