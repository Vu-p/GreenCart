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
        [FromQuery] bool? isDeal,
        [FromQuery] bool? isOrganic,
        [FromQuery] bool? inStock,
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

        if (isDeal is not null)
        {
            query = query.Where(product => product.IsDeal == isDeal);
        }

        if (isOrganic is not null)
        {
            query = query.Where(product => product.IsOrganic == isOrganic);
        }

        if (inStock is not null)
        {
            query = inStock.Value
                ? query.Where(product => product.Stock > 0)
                : query.Where(product => product.Stock <= 0);
        }

        var products = await query
            .OrderByDescending(product => product.IsDeal)
            .ThenBy(product => product.Name)
            .ToListAsync(cancellationToken);

        return Ok(products.Select(ApiMappings.ToResponse).ToList());
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ProductResponse>> GetProduct(Guid id, CancellationToken cancellationToken)
    {
        var product = await dbContext.Products
            .Include(product => product.Category)
            .AsNoTracking()
            .SingleOrDefaultAsync(product => product.Id == id, cancellationToken);

        return product is null ? NotFound() : Ok(ApiMappings.ToResponse(product));
    }

    [HttpGet("{productId:guid}/substitutions")]
    public async Task<ActionResult<IReadOnlyList<ProductResponse>>> GetSubstitutions(
        Guid productId,
        [FromQuery] int limit = 5,
        CancellationToken cancellationToken = default)
    {
        var product = await dbContext.Products.AsNoTracking().SingleOrDefaultAsync(p => p.Id == productId, cancellationToken);
        if (product is null)
        {
            return NotFound();
        }

        var query = dbContext.Products
            .Include(p => p.Category)
            .AsNoTracking()
            .Where(p => p.Id != productId && p.Stock > 0);

        var candidates = await query
            .OrderByDescending(p => p.CategoryId == product.CategoryId)
            .ThenBy(p => p.Price)
            .Take(limit)
            .ToListAsync(cancellationToken);

        return Ok(candidates.Select(ApiMappings.ToResponse).ToList());
    }
}
