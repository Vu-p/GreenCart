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

    [Authorize(Roles = UserRoles.Admin)]
    [HttpPost("api/admin/orders/{orderId:guid}/items/{orderItemId:guid}/ai-substitute")]
    public async Task<ActionResult<object>> AiSubstituteItem(
        Guid orderId,
        Guid orderItemId,
        CancellationToken cancellationToken)
    {
        var order = await dbContext.Orders
            .Include(o => o.Items)
            .SingleOrDefaultAsync(o => o.Id == orderId, cancellationToken);
        if (order is null) return NotFound(new { message = "Không tìm thấy đơn hàng." });

        var orderItem = order.Items.SingleOrDefault(i => i.Id == orderItemId);
        if (orderItem is null) return BadRequest(new { message = "Không tìm thấy sản phẩm trong đơn hàng." });

        var originalProduct = await dbContext.Products.SingleOrDefaultAsync(p => p.Id == orderItem.ProductId, cancellationToken);
        var candidates = await dbContext.Products
            .AsNoTracking()
            .Where(p => p.Id != orderItem.ProductId && p.Stock > 0)
            .ToListAsync(cancellationToken);

        if (candidates.Count == 0)
        {
            return BadRequest(new { message = "⚠️ Hiện không có sản phẩm nào khác trong kho còn hàng để thay thế." });
        }

        var bestMatch = candidates
            .OrderByDescending(p => (originalProduct != null && p.CategoryId == originalProduct.CategoryId ? 50 : 0) +
                                    (originalProduct != null && p.IsOrganic == originalProduct.IsOrganic ? 25 : 0) -
                                    (originalProduct != null ? (double)Math.Abs(p.Price - originalProduct.Price) / 1000.0 : 0))
            .First();

        var note = $"🤖 AI GreenCart đề xuất: Thay '{orderItem.ProductName}' bằng '{bestMatch.Name}' (Cùng nhóm dinh dưỡng, giá {bestMatch.Price:N0}đ)";

        var substitution = new Substitution
        {
            OrderId = orderId,
            OrderItemId = orderItemId,
            OriginalProductId = orderItem.ProductId ?? Guid.Empty,
            ReplacementProductId = bestMatch.Id,
            Status = "PendingCustomerDecision",
            Note = note
        };

        dbContext.Substitutions.Add(substitution);

        dbContext.Notifications.Add(new Notification
        {
            UserId = order.UserId,
            Title = "🤖 AI Đề xuất đổi món",
            Message = $"Sản phẩm '{orderItem.ProductName}' trong đơn {order.OrderNumber} được AI gợi ý thay bằng '{bestMatch.Name}'.",
            Type = "Substitution",
            ReferenceId = order.Id
        });

        var payload = JsonSerializer.Serialize(new
        {
            substitution.Id,
            substitution.OrderId,
            substitution.OrderItemId,
            substitution.OriginalProductId,
            originalProductName = orderItem.ProductName,
            substitution.ReplacementProductId,
            replacementProductName = bestMatch.Name,
            replacementImageUrl = bestMatch.ImageUrl,
            replacementPrice = bestMatch.Price,
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
        await orderHub.Clients.Group(OrderHub.UserGroup(order.UserId.ToString())).SendAsync("ReceiveNotification", new
        {
            title = "🤖 AI Đề xuất đổi món",
            message = $"Sản phẩm '{orderItem.ProductName}' trong đơn {order.OrderNumber} được AI gợi ý thay bằng '{bestMatch.Name}'.",
            type = "Substitution",
            referenceId = order.Id
        }, cancellationToken);

        return Ok(ApiMappings.ToResponse(substitution));
    }

    [Authorize(Roles = UserRoles.Admin)]
    [HttpPost("api/admin/orders/{orderId:guid}/ai-auto-substitute")]
    public async Task<ActionResult<object>> AiAutoSubstituteOrder(
        Guid orderId,
        CancellationToken cancellationToken)
    {
        var order = await dbContext.Orders
            .Include(o => o.Items)
            .SingleOrDefaultAsync(o => o.Id == orderId, cancellationToken);
        if (order is null) return NotFound(new { message = "Không tìm thấy đơn hàng." });

        var allProducts = await dbContext.Products.AsNoTracking().ToListAsync(cancellationToken);
        var inStockCandidates = allProducts.Where(p => p.Stock > 0).ToList();

        if (inStockCandidates.Count == 0)
        {
            return BadRequest(new { message = "⚠️ Kho hàng hiện không có sản phẩm nào còn hàng để thay thế." });
        }

        var proposedCount = 0;
        foreach (var item in order.Items)
        {
            var orig = allProducts.FirstOrDefault(p => p.Id == item.ProductId);
            if (orig != null && orig.Stock <= 0)
            {
                var bestMatch = inStockCandidates
                    .Where(p => p.Id != item.ProductId)
                    .OrderByDescending(p => (p.CategoryId == orig.CategoryId ? 50 : 0) +
                                            (p.IsOrganic == orig.IsOrganic ? 25 : 0) -
                                            (double)Math.Abs(p.Price - orig.Price) / 1000.0)
                    .FirstOrDefault();

                if (bestMatch != null)
                {
                    var note = $"🤖 AI GreenCart tự động đề xuất thay '{item.ProductName}' (hết hàng) bằng '{bestMatch.Name}' (Cùng loại, giá {bestMatch.Price:N0}đ)";
                    var sub = new Substitution
                    {
                        OrderId = orderId,
                        OrderItemId = item.Id,
                        OriginalProductId = item.ProductId ?? Guid.Empty,
                        ReplacementProductId = bestMatch.Id,
                        Status = "PendingCustomerDecision",
                        Note = note
                    };
                    dbContext.Substitutions.Add(sub);
                    proposedCount++;
                }
            }
        }

        if (proposedCount == 0)
        {
            return Ok(new { message = "✅ Tất cả sản phẩm trong đơn hàng hiện đều còn đủ hàng trong kho, không cần thay thế." });
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        return Ok(new { message = $"🤖 AI đã tự động tạo {proposedCount} đề xuất thay thế cho các món hết hàng trong đơn!" });
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
