using System.Security.Claims;
using GreenCart.Api.Contracts;
using GreenCart.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GreenCart.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/profile")]
public sealed class ProfileController(IAuthService authService) : ControllerBase
{
    [HttpPut]
    public async Task<ActionResult<UserResponse>> Update(UpdateProfileRequest request, CancellationToken cancellationToken)
    {
        var rawId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(rawId, out var userId))
        {
            return Unauthorized();
        }

        var user = await authService.UpdateProfileAsync(userId, request, cancellationToken);
        return user is null ? NotFound() : Ok(user);
    }
}
