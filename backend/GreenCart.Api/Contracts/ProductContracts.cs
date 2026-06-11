using System.ComponentModel.DataAnnotations;

namespace GreenCart.Api.Contracts;

public sealed record CategoryResponse(Guid Id, string Name, string? ImageUrl);

public sealed record UpsertCategoryRequest(
    [Required, MinLength(2), MaxLength(120)] string Name,
    [MaxLength(1000)] string? ImageUrl);

public sealed record ProductResponse(
    Guid Id,
    string Name,
    string Description,
    decimal Price,
    int Stock,
    string ImageUrl,
    Guid CategoryId,
    string CategoryName,
    bool IsOrganic,
    bool IsDeal);

public sealed record UpsertProductRequest(
    [Required, MinLength(2), MaxLength(160)] string Name,
    [Required, MinLength(5), MaxLength(1000)] string Description,
    [Range(0.01, 99999)] decimal Price,
    [Range(0, 999999)] int Stock,
    [Required, MaxLength(1000)] string ImageUrl,
    [Required] Guid CategoryId,
    bool IsOrganic,
    bool IsDeal);
