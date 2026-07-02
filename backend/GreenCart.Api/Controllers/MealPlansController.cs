using System.Security.Claims;
using GreenCart.Api.Contracts;
using GreenCart.Api.Data;
using GreenCart.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GreenCart.Api.Controllers;

[ApiController]
[Route("api/meal-plans")]
public sealed class MealPlansController(AppDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<object>>> GetMealPlans(CancellationToken cancellationToken)
    {
        var plans = await dbContext.MealPlans
            .AsNoTracking()
            .Include(p => p.Ingredients)
            .OrderByDescending(p => p.IsFeatured)
            .ThenBy(p => p.Title)
            .ToListAsync(cancellationToken);

        return Ok(plans.Select(p => new
        {
            id = p.Id.ToString(),
            slug = ToSlug(p.Title),
            title = p.Title,
            subtitle = p.Description,
            minutes = p.PrepMinutes + p.CookMinutes,
            prepMinutes = p.PrepMinutes,
            cookMinutes = p.CookMinutes,
            servings = p.Servings,
            difficulty = p.Difficulty,
            imageUrl = p.ImageUrl,
            isFeatured = p.IsFeatured,
            calories = 520 // estimate for mobile UI compatibility
        }));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<object>> GetMealPlan(string id, CancellationToken cancellationToken)
    {
        Guid? guidId = Guid.TryParse(id, out var g) ? g : null;
        var plan = await dbContext.MealPlans
            .AsNoTracking()
            .Include(p => p.Ingredients)
            .ThenInclude(i => i.Product)
            .SingleOrDefaultAsync(p => (guidId != null && p.Id == guidId) || p.Title.ToLower() == id.ToLower() || p.Title.ToLower().Replace(" ", "-").Replace("&", "and") == id.ToLower(), cancellationToken);

        if (plan is null)
        {
            // fallback match if slug is slightly different
            var allPlans = await dbContext.MealPlans
                .AsNoTracking()
                .Include(p => p.Ingredients)
                .ThenInclude(i => i.Product)
                .ToListAsync(cancellationToken);
            plan = allPlans.FirstOrDefault(p => ToSlug(p.Title) == id.ToLower() || p.Id.ToString() == id);
        }

        if (plan is null)
        {
            return NotFound(new { message = "Meal plan not found." });
        }

        var steps = plan.Instructions.Split(['\n', '.'], StringSplitOptions.RemoveEmptyEntries)
            .Select(s => s.Trim())
            .Where(s => s.Length > 3)
            .ToList();

        return Ok(new
        {
            id = plan.Id.ToString(),
            slug = ToSlug(plan.Title),
            title = plan.Title,
            subtitle = plan.Description,
            minutes = plan.PrepMinutes + plan.CookMinutes,
            prepMinutes = plan.PrepMinutes,
            cookMinutes = plan.CookMinutes,
            servings = plan.Servings,
            difficulty = plan.Difficulty,
            imageUrl = plan.ImageUrl,
            calories = 520,
            ingredients = plan.Ingredients.OrderBy(i => i.SortOrder).Select(i => new
            {
                id = i.Id.ToString(),
                name = i.Product?.Name ?? "Unknown Ingredient",
                quantityLabel = i.QuantityText,
                productId = i.ProductId.ToString(),
                unitPrice = i.Product?.Price ?? 0,
                imageUrl = i.Product?.ImageUrl ?? "",
                stock = i.Product?.Stock ?? 0,
                required = !i.IsOptional
            }),
            steps
        });
    }

    [Authorize]
    [HttpPost("{id}/cart-items")]
    public async Task<ActionResult<CartResponse>> AddIngredientsToCart(string id, [FromBody] AddMealIngredientsRequest? request, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        Guid? guidId = Guid.TryParse(id, out var g) ? g : null;
        var allPlans = await dbContext.MealPlans
            .Include(p => p.Ingredients)
            .ThenInclude(i => i.Product)
            .ToListAsync(cancellationToken);
        var plan = allPlans.FirstOrDefault(p => (guidId != null && p.Id == guidId) || ToSlug(p.Title) == id.ToLower() || p.Id.ToString() == id);

        if (plan is null)
        {
            return NotFound(new { message = "Meal plan not found." });
        }

        var cart = await dbContext.Carts.Include(c => c.Items).SingleOrDefaultAsync(c => c.UserId == userId.Value, cancellationToken);
        if (cart is null)
        {
            cart = new Cart { UserId = userId.Value };
            dbContext.Carts.Add(cart);
        }

        var ingredientsToAdd = plan.Ingredients.AsEnumerable();
        if (request != null && !request.AddAll && request.IngredientIds?.Count > 0)
        {
            var targetIds = request.IngredientIds.Select(x => Guid.TryParse(x, out var gid) ? gid : Guid.Empty).ToHashSet();
            ingredientsToAdd = ingredientsToAdd.Where(i => targetIds.Contains(i.Id) || targetIds.Contains(i.ProductId));
        }

        foreach (var ing in ingredientsToAdd)
        {
            if (ing.Product != null && ing.Product.Stock > 0)
            {
                var existingItem = cart.Items.FirstOrDefault(ci => ci.ProductId == ing.ProductId);
                if (existingItem != null)
                {
                    if (existingItem.Quantity < ing.Product.Stock)
                    {
                        existingItem.Quantity += 1;
                    }
                }
                else
                {
                    cart.Items.Add(new CartItem
                    {
                        CartId = cart.Id,
                        ProductId = ing.ProductId,
                        Quantity = 1
                    });
                }
            }
        }

        cart.UpdatedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);

        var savedCart = await dbContext.Carts
            .Include(c => c.Items)
            .ThenInclude(i => i.Product)
            .SingleOrDefaultAsync(c => c.UserId == userId.Value, cancellationToken);

        return Ok(ApiMappings.ToResponse(savedCart!));
    }

    private static string ToSlug(string title) =>
        title.ToLowerInvariant().Replace(" & ", "-and-").Replace("&", "-and-").Replace(" ", "-");

    private Guid? GetUserId()
    {
        var rawId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(rawId, out var userId) ? userId : null;
    }
}

public sealed class AddMealIngredientsRequest
{
    public List<string>? IngredientIds { get; set; }
    public bool AddAll { get; set; } = true;
}
