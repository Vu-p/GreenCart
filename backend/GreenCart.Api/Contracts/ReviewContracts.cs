using System.ComponentModel.DataAnnotations;

namespace GreenCart.Api.Contracts;

public sealed record SubmitOrderReviewRequest(
    [Range(1, 5)] int Rating,
    [MaxLength(1000)] string? Comment,
    IReadOnlyList<SubmitProductReviewRequest>? ProductReviews);

public sealed record SubmitProductReviewRequest(
    [Required] Guid ProductId,
    [Range(1, 5)] int Rating,
    [MaxLength(500)] string? Comment);

public sealed record OrderReviewResponse(
    Guid Id,
    Guid OrderId,
    int Rating,
    string? Comment,
    IReadOnlyList<ProductReviewResponse> ProductReviews,
    DateTimeOffset CreatedAt);

public sealed record ProductReviewResponse(
    Guid Id,
    Guid ProductId,
    int Rating,
    string? Comment,
    DateTimeOffset CreatedAt);
