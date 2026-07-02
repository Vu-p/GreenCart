using System;
using System.Linq;
using System.Security.Claims;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using GreenCart.Api.Contracts;
using GreenCart.Api.Data;
using GreenCart.Api.Hubs;
using GreenCart.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace GreenCart.Api.Controllers;

[ApiController]
public sealed class SubstitutionsController(AppDbContext dbContext, IHubContext<OrderHub> orderHub) : ControllerBase
{
    [Authorize(Roles = UserRoles.Admin)]
    [HttpPost("api/admin/orders/{orderId:guid}/substitutions")]
    public async Task<ActionResult<OrderSubstitutionResponse>> ProposeSubstitution(
        Guid orderId,
        ProposeSubstitutionRequest request,
        CancellationToken cancellationToken)
    {
        var order = await dbContext.Orders
            .Include(o => o.Items)
            .SingleOrDefaultAsync(o => o.Id == orderId, cancellationToken);
        if (order is null)
        {
            return NotFound(new { message = "Order not found." });
        }

        var orderItem = order.Items.SingleOrDefault(i => i.Id == request.OrderItemId);
        if (orderItem is null)
        {
            return BadRequest(new { message = "Order item not found in this order." });
        }

        var originalProduct = await dbContext.Products.SingleOrDefaultAsync(p => p.Id == request.OriginalProductId, cancellationToken);
        var replacementProduct = await dbContext.Products.SingleOrDefaultAsync(p => p.Id == request.ReplacementProductId, cancellationToken);
        if (originalProduct is null || replacementProduct is null)
        {
            return BadRequest(new { message = "Product not found." });
        }

        var substitution = new Substitution
        {
            OrderId = orderId,
            OrderItemId = request.OrderItemId,
            OriginalProductId = request.OriginalProductId,
            ReplacementProductId = request.ReplacementProductId,
            Status = "PendingCustomerDecision",
            Note = request.Note
        };

        dbContext.Substitutions.Add(substitution);

        var payload = JsonSerializer.Serialize(new
        {
            substitution.Id,
            substitution.OrderId,
            substitution.OrderItemId,
            substitution.OriginalProductId,
            originalProductName = originalProduct.Name,
            substitution.ReplacementProductId,
            replacementProductName = replacementProduct.Name,
            replacementImageUrl = replacementProduct.ImageUrl,
            replacementPrice = replacementProduct.Price,
            substitution.Status,
            substitution.Note
        });

        dbContext.RealtimeEvents.Add(new RealtimeEvent
        {
            UserId = order.UserId,
            OrderId = order.Id,
            Type = "SubstitutionProposed",
            Payload = payload
        });

        await dbContext.SaveChangesAsync(cancellationToken);

        await orderHub.Clients.Group(OrderHub.OrderGroup(order.Id.ToString())).SendAsync("SubstitutionProposed", payload, cancellationToken);
        await orderHub.Clients.Group(OrderHub.OrderGroup(order.OrderNumber)).SendAsync("SubstitutionProposed", payload, cancellationToken);
        await orderHub.Clients.Group(OrderHub.UserGroup(order.UserId.ToString())).SendAsync("SubstitutionProposed", payload, cancellationToken);

        return Ok(ApiMappings.ToResponse(substitution));
    }

    [Authorize]
    [HttpPost("api/orders/{orderId:guid}/substitutions/{substitutionId:guid}/accept")]
    public async Task<ActionResult<OrderSubstitutionResponse>> AcceptSubstitution(
        Guid orderId,
        Guid substitutionId,
        CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var order = await dbContext.Orders
            .Include(o => o.Items)
            .SingleOrDefaultAsync(o => o.Id == orderId && o.UserId == userId, cancellationToken);
        if (order is null)
        {
            return NotFound(new { message = "Order not found." });
        }

        var substitution = await dbContext.Substitutions
            .SingleOrDefaultAsync(s => s.Id == substitutionId && s.OrderId == orderId, cancellationToken);
        if (substitution is null)
        {
            return NotFound(new { message = "Substitution proposal not found." });
        }

        if (substitution.Status != "PendingCustomerDecision")
        {
            return BadRequest(new { message = "Substitution is already resolved." });
        }

        var replacementProduct = await dbContext.Products.SingleOrDefaultAsync(p => p.Id == substitution.ReplacementProductId, cancellationToken);
        if (replacementProduct is null)
        {
            return BadRequest(new { message = "Replacement product is no longer available." });
        }

        var orderItem = order.Items.SingleOrDefault(i => i.Id == substitution.OrderItemId);
        if (orderItem is null)
        {
            return BadRequest(new { message = "Order item not found." });
        }

        orderItem.ProductId = replacementProduct.Id;
        orderItem.ProductName = replacementProduct.Name;
        orderItem.ImageUrl = replacementProduct.ImageUrl;
        orderItem.UnitPrice = replacementProduct.Price;

        order.Subtotal = order.Items.Sum(item => item.UnitPrice * item.Quantity);
        order.Total = order.Subtotal + order.DeliveryFee;
        order.UpdatedAt = DateTimeOffset.UtcNow;

        substitution.Status = "Accepted";
        substitution.UpdatedAt = DateTimeOffset.UtcNow;

        var payload = JsonSerializer.Serialize(new
        {
            substitution.Id,
            substitution.OrderId,
            substitution.Status,
            Order = ApiMappings.ToResponse(order)
        });

        dbContext.RealtimeEvents.Add(new RealtimeEvent
        {
            UserId = order.UserId,
            OrderId = order.Id,
            Type = "SubstitutionAccepted",
            Payload = payload
        });

        await dbContext.SaveChangesAsync(cancellationToken);

        await orderHub.Clients.Group(OrderHub.OrderGroup(order.Id.ToString())).SendAsync("SubstitutionAccepted", payload, cancellationToken);
        await orderHub.Clients.Group(OrderHub.OrderGroup(order.OrderNumber)).SendAsync("SubstitutionAccepted", payload, cancellationToken);

        return Ok(ApiMappings.ToResponse(substitution));
    }

    [Authorize]
    [HttpPost("api/orders/{orderId:guid}/substitutions/{substitutionId:guid}/decline")]
    public async Task<ActionResult<OrderSubstitutionResponse>> DeclineSubstitution(
        Guid orderId,
        Guid substitutionId,
        CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var order = await dbContext.Orders
            .SingleOrDefaultAsync(o => o.Id == orderId && o.UserId == userId, cancellationToken);
        if (order is null)
        {
            return NotFound(new { message = "Order not found." });
        }

        var substitution = await dbContext.Substitutions
            .SingleOrDefaultAsync(s => s.Id == substitutionId && s.OrderId == orderId, cancellationToken);
        if (substitution is null)
        {
            return NotFound(new { message = "Substitution proposal not found." });
        }

        if (substitution.Status != "PendingCustomerDecision")
        {
            return BadRequest(new { message = "Substitution is already resolved." });
        }

        substitution.Status = "Declined";
        substitution.UpdatedAt = DateTimeOffset.UtcNow;

        var payload = JsonSerializer.Serialize(new
        {
            substitution.Id,
            substitution.OrderId,
            substitution.Status
        });

        dbContext.RealtimeEvents.Add(new RealtimeEvent
        {
            UserId = order.UserId,
            OrderId = order.Id,
            Type = "SubstitutionDeclined",
            Payload = payload
        });

        await dbContext.SaveChangesAsync(cancellationToken);

        await orderHub.Clients.Group(OrderHub.OrderGroup(order.Id.ToString())).SendAsync("SubstitutionDeclined", payload, cancellationToken);
        await orderHub.Clients.Group(OrderHub.OrderGroup(order.OrderNumber)).SendAsync("SubstitutionDeclined", payload, cancellationToken);

        return Ok(ApiMappings.ToResponse(substitution));
    }

    private Guid? GetUserId()
    {
        var rawId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(rawId, out var userId) ? userId : null;
    }
}
