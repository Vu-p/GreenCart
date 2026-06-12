using System.Text.Json;
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
[Authorize(Roles = UserRoles.Admin)]
[Route("api/admin")]
public sealed class AdminController(AppDbContext dbContext, IHubContext<OrderHub> orderHub) : ControllerBase
{
    [HttpGet("orders")]
    public async Task<ActionResult<IReadOnlyList<OrderResponse>>> GetOrders(CancellationToken cancellationToken)
    {
        var orders = (await BaseOrderQuery()
            .ToListAsync(cancellationToken))
            .OrderByDescending(order => order.CreatedAt)
            .ToList();

        return Ok(orders.Select(ApiMappings.ToResponse).ToList());
    }

    [HttpPut("orders/{id}/status")]
    public async Task<ActionResult<OrderResponse>> UpdateOrderStatus(
        string id,
        UpdateOrderStatusRequest request,
        CancellationToken cancellationToken)
    {
        if (!OrderStatuses.All.Contains(request.Status))
        {
            return BadRequest(new { message = "Unsupported order status." });
        }

        var order = await FindOrderAsync(id, cancellationToken);
        if (order is null)
        {
            return NotFound();
        }

        order.Status = request.Status;
        order.UpdatedAt = DateTimeOffset.UtcNow;

        var payload = JsonSerializer.Serialize(new
        {
            order.Id,
            order.OrderNumber,
            order.Status,
            order.UpdatedAt
        });

        dbContext.RealtimeEvents.Add(new RealtimeEvent
        {
            UserId = order.UserId,
            OrderId = order.Id,
            Type = "OrderStatusChanged",
            Payload = payload
        });

        await dbContext.SaveChangesAsync(cancellationToken);
        await orderHub.Clients.Group(OrderHub.OrderGroup(order.Id.ToString())).SendAsync("OrderStatusChanged", payload, cancellationToken);
        await orderHub.Clients.Group(OrderHub.OrderGroup(order.OrderNumber)).SendAsync("OrderStatusChanged", payload, cancellationToken);

        return Ok(ApiMappings.ToResponse(order));
    }

    [HttpGet("products")]
    public async Task<ActionResult<IReadOnlyList<ProductResponse>>> GetProducts(CancellationToken cancellationToken)
    {
        var products = await dbContext.Products
            .Include(product => product.Category)
            .AsNoTracking()
            .OrderBy(product => product.Name)
            .ToListAsync(cancellationToken);

        return Ok(products.Select(ApiMappings.ToResponse).ToList());
    }

    [HttpPost("products")]
    public async Task<ActionResult<ProductResponse>> CreateProduct(UpsertProductRequest request, CancellationToken cancellationToken)
    {
        if (!await dbContext.Categories.AnyAsync(category => category.Id == request.CategoryId, cancellationToken))
        {
            return NotFound(new { message = "Category was not found." });
        }

        var product = new Product
        {
            Name = request.Name.Trim(),
            Description = request.Description.Trim(),
            Price = request.Price,
            Stock = request.Stock,
            ImageUrl = request.ImageUrl.Trim(),
            CategoryId = request.CategoryId,
            IsOrganic = request.IsOrganic,
            IsDeal = request.IsDeal
        };

        dbContext.Products.Add(product);
        await dbContext.SaveChangesAsync(cancellationToken);

        var savedProduct = await LoadProductAsync(product.Id, cancellationToken);
        return Created($"api/products/{product.Id}", ApiMappings.ToResponse(savedProduct!));
    }

    [HttpPut("products/{id:guid}")]
    public async Task<ActionResult<ProductResponse>> UpdateProduct(Guid id, UpsertProductRequest request, CancellationToken cancellationToken)
    {
        var product = await dbContext.Products.SingleOrDefaultAsync(product => product.Id == id, cancellationToken);
        if (product is null)
        {
            return NotFound();
        }

        if (!await dbContext.Categories.AnyAsync(category => category.Id == request.CategoryId, cancellationToken))
        {
            return NotFound(new { message = "Category was not found." });
        }

        product.Name = request.Name.Trim();
        product.Description = request.Description.Trim();
        product.Price = request.Price;
        product.Stock = request.Stock;
        product.ImageUrl = request.ImageUrl.Trim();
        product.CategoryId = request.CategoryId;
        product.IsOrganic = request.IsOrganic;
        product.IsDeal = request.IsDeal;
        await dbContext.SaveChangesAsync(cancellationToken);

        var savedProduct = await LoadProductAsync(product.Id, cancellationToken);
        return Ok(ApiMappings.ToResponse(savedProduct!));
    }

    [HttpDelete("products/{id:guid}")]
    public async Task<IActionResult> DeleteProduct(Guid id, CancellationToken cancellationToken)
    {
        var product = await dbContext.Products.SingleOrDefaultAsync(product => product.Id == id, cancellationToken);
        if (product is null)
        {
            return NotFound();
        }

        dbContext.Products.Remove(product);
        await dbContext.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    [HttpPost("categories")]
    public async Task<ActionResult<CategoryResponse>> CreateCategory(UpsertCategoryRequest request, CancellationToken cancellationToken)
    {
        var normalizedName = request.Name.Trim();
        if (await dbContext.Categories.AnyAsync(category => category.Name == normalizedName, cancellationToken))
        {
            return Conflict(new { message = "Category already exists." });
        }

        var category = new Category
        {
            Name = normalizedName,
            ImageUrl = string.IsNullOrWhiteSpace(request.ImageUrl) ? null : request.ImageUrl.Trim()
        };

        dbContext.Categories.Add(category);
        await dbContext.SaveChangesAsync(cancellationToken);

        return Created("api/categories", new CategoryResponse(category.Id, category.Name, category.ImageUrl));
    }

    [HttpPut("categories/{id:guid}")]
    public async Task<ActionResult<CategoryResponse>> UpdateCategory(Guid id, UpsertCategoryRequest request, CancellationToken cancellationToken)
    {
        var category = await dbContext.Categories.SingleOrDefaultAsync(category => category.Id == id, cancellationToken);
        if (category is null)
        {
            return NotFound();
        }

        category.Name = request.Name.Trim();
        category.ImageUrl = string.IsNullOrWhiteSpace(request.ImageUrl) ? null : request.ImageUrl.Trim();
        await dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new CategoryResponse(category.Id, category.Name, category.ImageUrl));
    }

    [HttpDelete("categories/{id:guid}")]
    public async Task<IActionResult> DeleteCategory(Guid id, CancellationToken cancellationToken)
    {
        var category = await dbContext.Categories
            .Include(category => category.Products)
            .SingleOrDefaultAsync(category => category.Id == id, cancellationToken);

        if (category is null)
        {
            return NotFound();
        }

        if (category.Products.Count > 0)
        {
            return Conflict(new { message = "Category still has products." });
        }

        dbContext.Categories.Remove(category);
        await dbContext.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    private IQueryable<Order> BaseOrderQuery() =>
        dbContext.Orders
            .Include(order => order.Items)
            .Include(order => order.Review);

    private async Task<Order?> FindOrderAsync(string id, CancellationToken cancellationToken)
    {
        var query = BaseOrderQuery();
        return Guid.TryParse(id, out var orderId)
            ? await query.SingleOrDefaultAsync(order => order.Id == orderId, cancellationToken)
            : await query.SingleOrDefaultAsync(order => order.OrderNumber == id, cancellationToken);
    }

    private async Task<Product?> LoadProductAsync(Guid id, CancellationToken cancellationToken) =>
        await dbContext.Products
            .Include(product => product.Category)
            .AsNoTracking()
            .SingleOrDefaultAsync(product => product.Id == id, cancellationToken);
}
