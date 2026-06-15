using System.ComponentModel.DataAnnotations;

namespace GreenCart.Api.Contracts;

public sealed record RegisterRequest(
    [Required, MinLength(2), MaxLength(120)] string Name,
    [Required, EmailAddress, MaxLength(255)] string Email,
    [Required, MinLength(8), MaxLength(128)] string Password);

public sealed record LoginRequest(
    [Required, EmailAddress, MaxLength(255)] string Email,
    [Required, MinLength(8), MaxLength(128)] string Password);

public sealed record FirebaseLoginRequest([MaxLength(4096)] string? IdToken);

public sealed record ChangePasswordRequest(
    [Required, MinLength(8), MaxLength(128)] string CurrentPassword,
    [Required, MinLength(8), MaxLength(128)] string NewPassword);

public sealed record UpdateProfileRequest(
    [Required, MinLength(2), MaxLength(120)] string Name,
    [MaxLength(32)] string? Phone,
    [MaxLength(500)] string? Address,
    [MaxLength(1000)] string? AvatarUrl);

public sealed record AuthResponse(string Token, UserResponse User);

public sealed record UserResponse(
    Guid Id,
    string Name,
    string Email,
    string Role,
    string? Phone,
    string? Address,
    string? AvatarUrl,
    DateTimeOffset CreatedAt);
