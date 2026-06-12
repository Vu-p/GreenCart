using Google.Apis.Auth;
using GreenCart.Api.Options;
using Microsoft.Extensions.Options;

namespace GreenCart.Api.Services;

public sealed class FirebaseTokenVerifier(IOptions<FirebaseOptions> firebaseOptions) : IFirebaseTokenVerifier
{
    private readonly FirebaseOptions _firebaseOptions = firebaseOptions.Value;

    public async Task<FirebaseUserInfo> VerifyAsync(string idToken, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_firebaseOptions.ProjectId))
        {
            throw new InvalidOperationException("Firebase project id is not configured.");
        }

        var settings = new GoogleJsonWebSignature.ValidationSettings
        {
            Audience = [_firebaseOptions.ProjectId]
        };

        var payload = await GoogleJsonWebSignature.ValidateAsync(idToken, settings);
        var expectedIssuer = $"https://securetoken.google.com/{_firebaseOptions.ProjectId}";
        if (!string.Equals(payload.Issuer, expectedIssuer, StringComparison.Ordinal))
        {
            throw new InvalidJwtException("Firebase token issuer is invalid.");
        }

        if (string.IsNullOrWhiteSpace(payload.Subject))
        {
            throw new InvalidJwtException("Firebase token subject is missing.");
        }

        if (string.IsNullOrWhiteSpace(payload.Email))
        {
            throw new InvalidJwtException("Firebase token email is missing.");
        }

        var name = string.IsNullOrWhiteSpace(payload.Name)
            ? payload.Email.Split('@', 2)[0]
            : payload.Name.Trim();

        return new FirebaseUserInfo(
            payload.Subject,
            payload.Email.Trim().ToLowerInvariant(),
            name,
            string.IsNullOrWhiteSpace(payload.Picture) ? null : payload.Picture.Trim(),
            payload.EmailVerified);
    }
}
