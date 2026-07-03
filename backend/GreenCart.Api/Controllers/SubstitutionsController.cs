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

        var eventData = new
        {
            id = substitution.Id,
            orderId = substitution.OrderId,
            orderItemId = substitution.OrderItemId,
            originalProductId = substitution.OriginalProductId,
            originalProductName = originalProduct.Name,
            replacementProductId = substitution.ReplacementProductId,
            replacementProductName = replacementProduct.Name,
            replacementImageUrl = replacementProduct.ImageUrl,
            replacementPrice = replacementProduct.Price,
            status = substitution.Status,
            note = substitution.Note
        };
        var payload = JsonSerializer.Serialize(eventData);

        dbContext.RealtimeEvents.Add(new RealtimeEvent
        {
            UserId = order.UserId,
            OrderId = order.Id,
            Type = "SubstitutionProposed",
            Payload = payload
        });

        await dbContext.SaveChangesAsync(cancellationToken);

        await orderHub.Clients.Group(OrderHub.OrderGroup(order.Id.ToString())).SendAsync("SubstitutionProposed", eventData, cancellationToken);
        await orderHub.Clients.Group(OrderHub.OrderGroup(order.OrderNumber)).SendAsync("SubstitutionProposed", eventData, cancellationToken);
        await orderHub.Clients.Group(OrderHub.UserGroup(order.UserId.ToString())).SendAsync("SubstitutionProposed", eventData, cancellationToken);

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
            .OrderByDescending(p => ScoreCulinaryMatch(originalProduct, p))
            .First();

        var priceDiff = originalProduct != null ? originalProduct.Price - bestMatch.Price : 0;
        var clusterReason = GetCulinaryClusterReason(originalProduct, bestMatch);
        var note = priceDiff > 0
            ? $"🤖 AI Culinary Match: Thay '{orderItem.ProductName}' bằng '{bestMatch.Name}' ({clusterReason}, GIÁ RẺ HƠN giúp bạn TIẾT KIỆM {priceDiff:N0}đ!)"
            : $"🤖 AI Culinary Match: Thay '{orderItem.ProductName}' bằng '{bestMatch.Name}' ({clusterReason}, đảm bảo giá trị dinh dưỡng tương đương)";

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
            Title = "🤖 AI Đề xuất đổi món phù hợp",
            Message = $"Sản phẩm '{orderItem.ProductName}' trong đơn {order.OrderNumber} được gợi ý thay bằng '{bestMatch.Name}'.",
            Type = "Substitution",
            ReferenceId = order.Id
        });

        await dbContext.SaveChangesAsync(cancellationToken);

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
            if (orig != null)
            {
                var candidatesForOrig = inStockCandidates.Where(p => p.Id != orig.Id).ToList();
                if (candidatesForOrig.Count == 0) continue;

                var bestMatch = candidatesForOrig
                    .OrderByDescending(p => ScoreCulinaryMatch(orig, p))
                    .FirstOrDefault();

                if (bestMatch != null)
                {
                    bool isOut = orig.Stock <= 0;
                    bool isCheaperAndBetter = ScoreCulinaryMatch(orig, bestMatch) >= 150 && bestMatch.Price < orig.Price;

                    if (isOut || isCheaperAndBetter)
                    {
                        var priceDiff = orig.Price - bestMatch.Price;
                        var reason = isOut ? "(hết hàng)" : "(tối ưu chi phí & chất lượng)";
                        var clusterReason = GetCulinaryClusterReason(orig, bestMatch);
                        var note = priceDiff > 0
                            ? $"🤖 AI Culinary Match {reason}: Thay '{item.ProductName}' bằng '{bestMatch.Name}' ({clusterReason}, RẺ HƠN & TIẾT KIỆM {priceDiff:N0}đ!)"
                            : $"🤖 AI Culinary Match {reason}: Thay '{item.ProductName}' bằng '{bestMatch.Name}' ({clusterReason})";

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
        }

        if (proposedCount == 0)
        {
            return Ok(new { message = "✅ Các món trong đơn hàng hiện tại đã là lựa chọn tối ưu về chi phí và chất lượng nhất rồi!" });
        }

        await dbContext.SaveChangesAsync(cancellationToken);
        return Ok(new { message = $"🤖 AI đã tự động tạo {proposedCount} đề xuất thay thế tối ưu cho đơn hàng!" });
    }

    private static double ScoreCulinaryMatch(Product? orig, Product candidate)
    {
        if (orig is null) return 0;
        double score = 0;

        // 1. Khớp cụm thực phẩm nấu ăn chuyên sâu (Culinary Clusters)
        var origCluster = GetCulinaryCluster(orig.Name);
        var candCluster = GetCulinaryCluster(candidate.Name);

        if (origCluster != string.Empty && origCluster == candCluster)
        {
            score += 500; // Cùng nhóm thay thế hoàn hảo trong nấu ăn/tiêu dùng
        }
        else if (orig.CategoryId == candidate.CategoryId)
        {
            score += 150; // Cùng danh mục thực phẩm
        }

        // 2. Tối ưu giá tiền: Ưu tiên món có giá tương đương hoặc rẻ hơn cho khách
        if (candidate.Price <= orig.Price)
        {
            score += 60 + (double)((orig.Price - candidate.Price) / 1000m);
        }
        else
        {
            score -= (double)((candidate.Price - orig.Price) / 1000m);
        }

        if (candidate.IsOrganic) score += 30;
        if (candidate.IsDeal) score += 20;

        return score;
    }

    private static string GetCulinaryCluster(string name)
    {
        var n = name.ToLowerInvariant();
        if (n.Contains("milk") || n.Contains("sữa") || n.Contains("yogurt")) return "milk_dairy";
        if (n.Contains("egg") || n.Contains("trứng")) return "eggs";
        if (n.Contains("apple") || n.Contains("táo") || n.Contains("berry") || n.Contains("straw") || n.Contains("dâu")) return "sweet_fruits";
        if (n.Contains("spinach") || n.Contains("broccoli") || n.Contains("asparagus") || n.Contains("rau") || n.Contains("cải") || n.Contains("lơ")) return "leafy_greens";
        if (n.Contains("potato") || n.Contains("khoai") || n.Contains("corn") || n.Contains("carrots") || n.Contains("củ")) return "tubers_roots";
        if (n.Contains("chicken") || n.Contains("gà") || n.Contains("pork") || n.Contains("heo") || n.Contains("beef") || n.Contains("bò") || n.Contains("salmon") || n.Contains("cá")) return "protein_meat";
        if (n.Contains("onion") || n.Contains("garlic") || n.Contains("hành") || n.Contains("tỏi") || n.Contains("ginger") || n.Contains("gừng")) return "aromatics";
        return string.Empty;
    }

    private static string GetCulinaryClusterReason(Product? orig, Product cand)
    {
        var cluster = GetCulinaryCluster(orig?.Name ?? "");
        return cluster switch
        {
            "milk_dairy" => "Cùng nhóm sữa & đồ uống dinh dưỡng thơm mát",
            "eggs" => "Cùng nhóm trứng sạch giàu protein dễ chế biến",
            "sweet_fruits" => "Cùng loại trái cây giòn ngọt giàu vitamin C",
            "leafy_greens" => "Cùng nhóm rau xanh nấu canh/xào giàu chất xơ",
            "tubers_roots" => "Cùng loại củ quả bùi ngọt dinh dưỡng",
            "protein_meat" => "Cùng nhóm đạm cao cấp chuẩn bị bữa ăn đầy đủ",
            "aromatics" => "Cùng nhóm gia vị nấu nướng thơm lừng",
            _ => "Cùng danh mục thực phẩm chất lượng cao"
        };
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

        var eventData = new
        {
            id = substitution.Id,
            orderId = substitution.OrderId,
            status = substitution.Status,
            order = ApiMappings.ToResponse(order)
        };
        var payload = JsonSerializer.Serialize(eventData);

        dbContext.RealtimeEvents.Add(new RealtimeEvent
        {
            UserId = order.UserId,
            OrderId = order.Id,
            Type = "SubstitutionAccepted",
            Payload = payload
        });

        await dbContext.SaveChangesAsync(cancellationToken);

        await orderHub.Clients.Group(OrderHub.OrderGroup(order.Id.ToString())).SendAsync("SubstitutionAccepted", eventData, cancellationToken);
        await orderHub.Clients.Group(OrderHub.OrderGroup(order.OrderNumber)).SendAsync("SubstitutionAccepted", eventData, cancellationToken);

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

        var decEventData = new
        {
            id = substitution.Id,
            orderId = substitution.OrderId,
            status = substitution.Status
        };
        var payload = JsonSerializer.Serialize(decEventData);

        dbContext.RealtimeEvents.Add(new RealtimeEvent
        {
            UserId = order.UserId,
            OrderId = order.Id,
            Type = "SubstitutionDeclined",
            Payload = payload
        });

        await dbContext.SaveChangesAsync(cancellationToken);

        await orderHub.Clients.Group(OrderHub.OrderGroup(order.Id.ToString())).SendAsync("SubstitutionDeclined", decEventData, cancellationToken);
        await orderHub.Clients.Group(OrderHub.OrderGroup(order.OrderNumber)).SendAsync("SubstitutionDeclined", decEventData, cancellationToken);

        return Ok(ApiMappings.ToResponse(substitution));
    }

    private Guid? GetUserId()
    {
        var rawId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(rawId, out var userId) ? userId : null;
    }
}
