using GreenCart.Api.Contracts;

namespace GreenCart.Api.Services;

public interface IAuthService
{
    Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken);
    Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken cancellationToken);
    Task<UserResponse?> GetCurrentUserAsync(Guid userId, CancellationToken cancellationToken);
    Task<UserResponse?> UpdateProfileAsync(Guid userId, UpdateProfileRequest request, CancellationToken cancellationToken);
    Task<bool> ChangePasswordAsync(Guid userId, ChangePasswordRequest request, CancellationToken cancellationToken);
}
