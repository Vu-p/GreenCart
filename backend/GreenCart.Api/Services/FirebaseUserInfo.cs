namespace GreenCart.Api.Services;

public sealed record FirebaseUserInfo(
    string Uid,
    string Email,
    string Name,
    string? AvatarUrl,
    bool EmailVerified);
