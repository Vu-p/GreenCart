using System;

namespace GreenCart.Api.Contracts;

public sealed record ProposeSubstitutionRequest(
    Guid OrderItemId,
    Guid OriginalProductId,
    Guid ReplacementProductId,
    string? Note);

public sealed record OrderSubstitutionResponse(
    Guid Id,
    Guid OrderId,
    Guid OrderItemId,
    Guid OriginalProductId,
    Guid ReplacementProductId,
    string Status,
    string? Note);
