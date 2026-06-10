namespace GreenCart.Api.Contracts;

public sealed record CategoryResponse(Guid Id, string Name, string? ImageUrl);

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
