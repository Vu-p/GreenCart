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
[Route("api/checkout")]
public sealed class CheckoutController(AppDbContext dbContext) : ControllerBase
{
    [HttpPost("preview")]
    public async Task<ActionResult<CheckoutPreviewResponse>> Preview(CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var user = await dbContext.Users.AsNoTracking().SingleOrDefaultAsync(user => user.Id == userId.Value, cancellationToken);
        var cart = await LoadCartAsync(userId.Value, cancellationToken);
        var cartResponse = ApiMappings.ToResponse(cart);

        return Ok(new CheckoutPreviewResponse(
            cartResponse.Items,
            cartResponse.Subtotal,
            cartResponse.DeliveryFee,
            cartResponse.Total,
            user?.Address,
            user?.Phone,
            "Contact me before replacing out-of-stock items."));
    }

    [HttpPost]
    public async Task<ActionResult<OrderResponse>> Checkout(CheckoutRequest request, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);
        var cart = await LoadCartAsync(userId.Value, cancellationToken);
        if (cart is null || cart.Items.Count == 0)
        {
            return Conflict(new { message = "Cart is empty." });
        }

        foreach (var item in cart.Items)
        {
            if (item.Product is null)
            {
                return Conflict(new { message = "Cart contains an unavailable product." });
            }

            if (item.Quantity > item.Product.Stock)
            {
                return Conflict(new { message = $"{item.Product.Name} does not have enough stock." });
            }
        }

        var subtotal = cart.Items.Sum(item => item.Product!.Price * item.Quantity);
        var order = new Order
        {
            OrderNumber = await CreateOrderNumberAsync(cancellationToken),
            UserId = userId.Value,
            Status = OrderStatuses.Confirmed,
            PaymentStatus = PaymentStatuses.Paid,
            DeliveryAddress = request.DeliveryAddress.Trim(),
            DeliveryPhone = string.IsNullOrWhiteSpace(request.DeliveryPhone) ? null : request.DeliveryPhone.Trim(),
            SubstitutionPreference = string.IsNullOrWhiteSpace(request.SubstitutionPreference) ? null : request.SubstitutionPreference.Trim(),
            Subtotal = subtotal,
            DeliveryFee = ApiMappings.StandardDeliveryFee,
            Total = subtotal + ApiMappings.StandardDeliveryFee
        };

        foreach (var item in cart.Items)
        {
            var product = item.Product!;
            product.Stock -= item.Quantity;
            order.Items.Add(new OrderItem
            {
                ProductId = product.Id,
                ProductName = product.Name,
                ImageUrl = product.ImageUrl,
                UnitPrice = product.Price,
                Quantity = item.Quantity
            });
        }

        dbContext.Orders.Add(order);
        dbContext.CartItems.RemoveRange(cart.Items);
        cart.UpdatedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        var savedOrder = await LoadOrderAsync(userId.Value, order.Id, cancellationToken);
        return CreatedAtAction("GetOrder", "Orders", new { id = order.Id }, ApiMappings.ToResponse(savedOrder!));
    }

    [HttpPut("substitution")]
    public ActionResult<SubstitutionResponse> UpdateSubstitution(UpdateSubstitutionRequest request)
    {
        var preference = string.IsNullOrWhiteSpace(request.SubstitutionPreference)
            ? null
            : request.SubstitutionPreference.Trim();
        return Ok(new SubstitutionResponse(preference));
    }

    private async Task<Cart?> LoadCartAsync(Guid userId, CancellationToken cancellationToken) =>
        await dbContext.Carts
            .Include(cart => cart.Items)
            .ThenInclude(item => item.Product)
            .SingleOrDefaultAsync(cart => cart.UserId == userId, cancellationToken);

    private async Task<Order?> LoadOrderAsync(Guid userId, Guid orderId, CancellationToken cancellationToken) =>
        await dbContext.Orders
            .Include(order => order.Items)
            .Include(order => order.Review)
            .SingleOrDefaultAsync(order => order.UserId == userId && order.Id == orderId, cancellationToken);

    private async Task<string> CreateOrderNumberAsync(CancellationToken cancellationToken)
    {
        string orderNumber;
        do
        {
            orderNumber = $"GC-{Random.Shared.Next(1000, 9999)}";
        }
        while (await dbContext.Orders.AnyAsync(order => order.OrderNumber == orderNumber, cancellationToken));

        return orderNumber;
    }

    private Guid? GetUserId()
    {
        var rawId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(rawId, out var userId) ? userId : null;
    }
}
