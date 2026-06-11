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
[Route("api/orders")]
public sealed class OrdersController(AppDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<OrderResponse>>> GetOrders(CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var orders = await BaseOrderQuery()
            .Where(order => order.UserId == userId.Value)
            .OrderByDescending(order => order.CreatedAt)
            .ToListAsync(cancellationToken);

        return Ok(orders.Select(ApiMappings.ToResponse).ToList());
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<OrderResponse>> GetOrder(string id, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var order = await FindOrderAsync(userId.Value, id, cancellationToken);
        return order is null ? NotFound() : Ok(ApiMappings.ToResponse(order));
    }

    [HttpPost("{id}/cancel")]
    public async Task<ActionResult<OrderResponse>> CancelOrder(string id, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var order = await FindOrderAsync(userId.Value, id, cancellationToken);
        if (order is null)
        {
            return NotFound();
        }

        if (order.Status is OrderStatuses.Delivering or OrderStatuses.Completed or OrderStatuses.Cancelled)
        {
            return Conflict(new { message = "Order cannot be cancelled at this stage." });
        }

        order.Status = OrderStatuses.Cancelled;
        order.UpdatedAt = DateTimeOffset.UtcNow;
        await dbContext.SaveChangesAsync(cancellationToken);

        return Ok(ApiMappings.ToResponse(order));
    }

    private IQueryable<Order> BaseOrderQuery() =>
        dbContext.Orders
            .Include(order => order.Items)
            .Include(order => order.Review);

    private async Task<Order?> FindOrderAsync(Guid userId, string id, CancellationToken cancellationToken)
    {
        var query = BaseOrderQuery().Where(order => order.UserId == userId);
        return Guid.TryParse(id, out var orderId)
            ? await query.SingleOrDefaultAsync(order => order.Id == orderId, cancellationToken)
            : await query.SingleOrDefaultAsync(order => order.OrderNumber == id, cancellationToken);
    }

    private Guid? GetUserId()
    {
        var rawId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(rawId, out var userId) ? userId : null;
    }
}
