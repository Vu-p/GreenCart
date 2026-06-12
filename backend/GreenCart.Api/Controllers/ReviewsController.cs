using System.Security.Claims;
using GreenCart.Api.Contracts;
using GreenCart.Api.Data;
using GreenCart.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GreenCart.Api.Controllers;

[ApiController]
public sealed class ReviewsController(AppDbContext dbContext) : ControllerBase
{
    [Authorize]
    [HttpPost("api/orders/{id}/review")]
    public async Task<ActionResult<OrderReviewResponse>> SubmitOrderReview(
        string id,
        SubmitOrderReviewRequest request,
        CancellationToken cancellationToken)
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

        if (order.Status != OrderStatuses.Completed)
        {
            return Conflict(new { message = "Only completed orders can be reviewed." });
        }

        if (order.Review is not null)
        {
            return Conflict(new { message = "Order has already been reviewed." });
        }

        var orderProductIds = order.Items
            .Where(item => item.ProductId is not null)
            .Select(item => item.ProductId!.Value)
            .ToHashSet();

        var review = new OrderReview
        {
            OrderId = order.Id,
            UserId = userId.Value,
            Rating = request.Rating,
            Comment = string.IsNullOrWhiteSpace(request.Comment) ? null : request.Comment.Trim()
        };

        foreach (var productReview in request.ProductReviews ?? [])
        {
            if (!orderProductIds.Contains(productReview.ProductId))
            {
                return Conflict(new { message = "Product review must belong to this order." });
            }

            review.ProductReviews.Add(new ProductReview
            {
                ProductId = productReview.ProductId,
                Rating = productReview.Rating,
                Comment = string.IsNullOrWhiteSpace(productReview.Comment) ? null : productReview.Comment.Trim()
            });
        }

        dbContext.OrderReviews.Add(review);
        await dbContext.SaveChangesAsync(cancellationToken);

        var savedReview = await dbContext.OrderReviews
            .Include(review => review.ProductReviews)
            .SingleAsync(savedReview => savedReview.Id == review.Id, cancellationToken);

        return Created($"api/orders/{id}/review", ApiMappings.ToResponse(savedReview));
    }

    [AllowAnonymous]
    [HttpGet("api/products/{id:guid}/reviews")]
    public async Task<ActionResult<IReadOnlyList<ProductReviewResponse>>> GetProductReviews(Guid id, CancellationToken cancellationToken)
    {
        var reviews = (await dbContext.ProductReviews
            .AsNoTracking()
            .Where(review => review.ProductId == id)
            .ToListAsync(cancellationToken))
            .OrderByDescending(review => review.CreatedAt)
            .Select(review => new ProductReviewResponse(
                review.Id,
                review.ProductId,
                review.Rating,
                review.Comment,
                review.CreatedAt))
            .ToList();

        return Ok(reviews);
    }

    private async Task<Order?> FindOrderAsync(Guid userId, string id, CancellationToken cancellationToken)
    {
        var query = dbContext.Orders
            .Include(order => order.Items)
            .Include(order => order.Review)
            .Where(order => order.UserId == userId);

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
