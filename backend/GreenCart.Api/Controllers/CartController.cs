using System.Security.Claims;
using GreenCart.Api.Contracts;
using GreenCart.Api.Data;
using GreenCart.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GreenCart.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/cart")]
public sealed class CartController(AppDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<CartResponse>> GetCart(CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var cart = await LoadCartAsync(userId.Value, cancellationToken);
        return Ok(ApiMappings.ToResponse(cart));
    }

    [HttpPost("items")]
    public async Task<ActionResult<CartResponse>> AddItem(CartItemRequest request, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var product = await dbContext.Products.SingleOrDefaultAsync(product => product.Id == request.ProductId, cancellationToken);
        if (product is null)
        {
            return NotFound(new { message = "Product was not found." });
        }

        if (product.Stock <= 0)
        {
            return Conflict(new { message = "Product is out of stock." });
        }

        var cart = await dbContext.Carts.SingleOrDefaultAsync(cart => cart.UserId == userId.Value, cancellationToken);
        if (cart is null)
        {
            cart = new Cart { UserId = userId.Value };
            dbContext.Carts.Add(cart);
        }

        var item = await dbContext.CartItems
            .SingleOrDefaultAsync(item => item.CartId == cart.Id && item.ProductId == product.Id, cancellationToken);
        var nextQuantity = (item?.Quantity ?? 0) + request.Quantity;
        if (nextQuantity > product.Stock)
        {
            return Conflict(new { message = "Requested quantity exceeds available stock." });
        }

        if (item is null)
        {
            dbContext.CartItems.Add(new CartItem
            {
                CartId = cart.Id,
                ProductId = product.Id,
                Quantity = request.Quantity
            });
        }
        else
        {
            item.Quantity = nextQuantity;
            item.UpdatedAt = DateTimeOffset.UtcNow;
        }

        cart.UpdatedAt = DateTimeOffset.UtcNow;
        try
        {
            await dbContext.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateConcurrencyException)
        {
            return Conflict(new { message = "Cart changed while updating. Please retry." });
        }

        return Ok(ApiMappings.ToResponse(await LoadCartAsync(userId.Value, cancellationToken)));
    }

    [HttpPut("items/{productId:guid}")]
    public async Task<ActionResult<CartResponse>> UpdateItem(Guid productId, UpdateCartItemRequest request, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var cart = await LoadCartAsync(userId.Value, cancellationToken);
        var item = cart?.Items.SingleOrDefault(item => item.ProductId == productId);
        if (item is null || item.Product is null)
        {
            return NotFound(new { message = "Cart item was not found." });
        }

        if (request.Quantity > item.Product.Stock)
        {
            return Conflict(new { message = "Requested quantity exceeds available stock." });
        }

        item.Quantity = request.Quantity;
        item.UpdatedAt = DateTimeOffset.UtcNow;
        cart!.UpdatedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);

        return Ok(ApiMappings.ToResponse(await LoadCartAsync(userId.Value, cancellationToken)));
    }

    [HttpDelete("items/{productId:guid}")]
    public async Task<ActionResult<CartResponse>> RemoveItem(Guid productId, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var cart = await LoadCartAsync(userId.Value, cancellationToken);
        var item = cart?.Items.SingleOrDefault(item => item.ProductId == productId);
        if (item is null)
        {
            return NotFound(new { message = "Cart item was not found." });
        }

        dbContext.CartItems.Remove(item);
        cart!.UpdatedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);

        return Ok(ApiMappings.ToResponse(await LoadCartAsync(userId.Value, cancellationToken)));
    }

    [HttpDelete]
    public async Task<ActionResult<CartResponse>> ClearCart(CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var cart = await LoadCartAsync(userId.Value, cancellationToken);
        if (cart is not null)
        {
            dbContext.CartItems.RemoveRange(cart.Items);
            cart.UpdatedAt = DateTimeOffset.UtcNow;
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        return Ok(ApiMappings.ToResponse(await LoadCartAsync(userId.Value, cancellationToken)));
    }

    private async Task<Cart?> LoadCartAsync(Guid userId, CancellationToken cancellationToken) =>
        await dbContext.Carts
            .Include(cart => cart.Items)
            .ThenInclude(item => item.Product)
            .SingleOrDefaultAsync(cart => cart.UserId == userId, cancellationToken);

    private Guid? GetUserId()
    {
        var rawId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(rawId, out var userId) ? userId : null;
    }
}
