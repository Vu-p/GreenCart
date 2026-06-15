using GreenCart.Api.Contracts;
using GreenCart.Api.Data;
using GreenCart.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace GreenCart.Api.Controllers;

[ApiController]
[Route("api/mealplans")]
public class MealPlansController : ControllerBase
{
    private readonly AppDbContext _db;

    public MealPlansController(AppDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<MealPlanResponse>>> GetAll()
    {
        var mealPlans = await _db.MealPlans
            .Select(x => new MealPlanResponse(
                x.Id,
                x.Name,
                x.Description,
                x.ImageUrl,
                x.Minutes,
                x.Category))
            .ToListAsync();

        return Ok(mealPlans);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<MealPlanDetailResponse>> GetById(Guid id)
    {
        var mealPlan = await _db.MealPlans
            .Include(x => x.Ingredients)
            .ThenInclude(x => x.Product)
            .FirstOrDefaultAsync(x => x.Id == id);

        if (mealPlan is null)
            return NotFound();

        var response = new MealPlanDetailResponse(
            mealPlan.Id,
            mealPlan.Name,
            mealPlan.Description,
            mealPlan.ImageUrl,
            mealPlan.Minutes,
            mealPlan.Category,
            mealPlan.Ingredients
                .Select(i =>
                    new MealPlanIngredientResponse(
                        i.Id,
                        i.ProductId,
                        i.Product!.Name,
                        i.QuantityLabel,
                        i.Product.Price,
                        i.Product.Stock))
                .ToList());

        return Ok(response);
    }

    [Authorize]
    [HttpPost("{id:guid}/cart-items")]
    public async Task<IActionResult> AddIngredientsToCart(
        Guid id,
        AddMealPlanIngredientsRequest request)
    {
        var userId = Guid.Parse(
            User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        var mealPlan = await _db.MealPlans
            .Include(x => x.Ingredients)
            .FirstOrDefaultAsync(x => x.Id == id);

        if (mealPlan is null)
            return NotFound();

        var ingredientIds = request.AddAll
            ? mealPlan.Ingredients.Select(x => x.Id).ToList()
            : request.IngredientIds;

        var ingredients = mealPlan.Ingredients
            .Where(x => ingredientIds.Contains(x.Id))
            .ToList();

        var cart = await _db.Carts
            .Include(x => x.Items)
            .FirstOrDefaultAsync(x => x.UserId == userId);

        if (cart is null)
        {
            cart = new Cart
            {
                UserId = userId
            };

            _db.Carts.Add(cart);
            await _db.SaveChangesAsync();
        }

        foreach (var ingredient in ingredients)
        {
            var product = await _db.Products
                .FirstOrDefaultAsync(x =>
                    x.Id == ingredient.ProductId);

            if (product is null)
                continue;

            if (product.Stock <= 0)
                continue;

            var cartItem = cart.Items
                .FirstOrDefault(x =>
                    x.ProductId == product.Id);

            if (cartItem is null)
            {
                cart.Items.Add(new CartItem
                {
                    ProductId = product.Id,
                    Quantity = 1
                });
            }
            else
            {
                cartItem.Quantity++;
            }
        }

        await _db.SaveChangesAsync();

        return Ok();
    }
}