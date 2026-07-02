using System.Security.Claims;
using GreenCart.Api.Data;
using GreenCart.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GreenCart.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/notifications")]
public sealed class NotificationsController(AppDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<object>>> GetNotifications(CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var list = (await dbContext.Notifications
            .AsNoTracking()
            .Where(n => n.UserId == userId.Value)
            .ToListAsync(cancellationToken))
            .OrderByDescending(n => n.CreatedAt)
            .Take(50)
            .ToList();

        return Ok(list.Select(n => new
        {
            id = n.Id.ToString(),
            title = n.Title,
            message = n.Message,
            type = n.Type,
            referenceId = n.ReferenceId?.ToString(),
            isRead = n.IsRead,
            createdAt = n.CreatedAt
        }));
    }

    [HttpPut("{id:guid}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var notification = await dbContext.Notifications
            .SingleOrDefaultAsync(n => n.Id == id && n.UserId == userId.Value, cancellationToken);

        if (notification != null && !notification.IsRead)
        {
            notification.IsRead = true;
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        return NoContent();
    }

    [HttpPut("read-all")]
    public async Task<IActionResult> MarkAllAsRead(CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId is null)
        {
            return Unauthorized();
        }

        var unread = await dbContext.Notifications
            .Where(n => n.UserId == userId.Value && !n.IsRead)
            .ToListAsync(cancellationToken);

        foreach (var n in unread)
        {
            n.IsRead = true;
        }

        if (unread.Count > 0)
        {
            await dbContext.SaveChangesAsync(cancellationToken);
        }

        return NoContent();
    }

    private Guid? GetUserId()
    {
        var rawId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(rawId, out var userId) ? userId : null;
    }
}
