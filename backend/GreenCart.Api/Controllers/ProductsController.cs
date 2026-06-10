using GreenCart.Api.Contracts;
using GreenCart.Api.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace GreenCart.Api.Controllers;

[ApiController]
[Route("api/products")]
public sealed class ProductsController(AppDbContext dbContext) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<ProductResponse>>> GetProducts(
        [FromQuery] string? keyword,
        [FromQuery] Guid? categoryId,
        [FromQuery] decimal? minPrice,
        [FromQuery] decimal? maxPrice,
        CancellationToken cancellationToken)
    {
        var query = dbContext.Products.Include(product => product.Category).AsNoTracking();

        if (!string.IsNullOrWhiteSpace(keyword))
        {
            var normalizedKeyword = keyword.Trim().ToLower();
            query = query.Where(product =>
                product.Name.ToLower().Contains(normalizedKeyword) ||
                product.Description.ToLower().Contains(normalizedKeyword));
        }

        if (categoryId is not null)
        {
            query = query.Where(product => product.CategoryId == categoryId);
        }

        if (minPrice is not null)
        {
            query = query.Where(product => product.Price >= minPrice);
        }

        if (maxPrice is not null)
        {
            query = query.Where(product => product.Price <= maxPrice);
        }

        var products = await query
            .OrderByDescending(product => product.IsDeal)
            .ThenBy(product => product.Name)
            .Select(product => new ProductResponse(
                product.Id,
                product.Name,
                product.Description,
                product.Price,
                product.Stock,
                product.ImageUrl,
                product.CategoryId,
                product.Category == null ? string.Empty : product.Category.Name,
                product.IsOrganic,
                product.IsDeal))
            .ToListAsync(cancellationToken);

        return Ok(products);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ProductResponse>> GetProduct(Guid id, CancellationToken cancellationToken)
    {
        var product = await dbContext.Products
            .Include(product => product.Category)
            .AsNoTracking()
            .SingleOrDefaultAsync(product => product.Id == id, cancellationToken);

        return product is null ? NotFound() : Ok(ToResponse(product));
    }

    private static ProductResponse ToResponse(Models.Product product) =>
        new(
            product.Id,
            product.Name,
            product.Description,
            product.Price,
            product.Stock,
            product.ImageUrl,
            product.CategoryId,
            product.Category?.Name ?? string.Empty,
            product.IsOrganic,
            product.IsDeal);
}
