using System.IdentityModel.Tokens.Jwt;
using System.Net.Http.Json;
using System.Security.Claims;
using System.Security.Cryptography.X509Certificates;
using GreenCart.Api.Options;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;

namespace GreenCart.Api.Services;

public sealed class FirebaseTokenVerifier(
    IOptions<FirebaseOptions> firebaseOptions,
    HttpClient httpClient) : IFirebaseTokenVerifier
{
    private const string FirebaseCertificatesUrl =
        "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com";

    private readonly FirebaseOptions _firebaseOptions = firebaseOptions.Value;

    public async Task<FirebaseUserInfo> VerifyAsync(string idToken, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_firebaseOptions.ProjectId))
        {
            throw new InvalidOperationException("Firebase project id is not configured.");
        }

        var expectedIssuer = $"https://securetoken.google.com/{_firebaseOptions.ProjectId}";
        var tokenHandler = new JwtSecurityTokenHandler { MapInboundClaims = false };
        var token = tokenHandler.ReadJwtToken(idToken);
        if (!string.Equals(token.Header.Alg, SecurityAlgorithms.RsaSha256, StringComparison.Ordinal))
        {
            throw new SecurityTokenInvalidAlgorithmException("Firebase token algorithm must be RS256.");
        }

        var keyId = token.Header.Kid;
        if (string.IsNullOrWhiteSpace(keyId))
        {
            throw new SecurityTokenException("Firebase token key id is missing.");
        }

        var certificates = await GetFirebaseCertificatesAsync(cancellationToken);
        if (!certificates.TryGetValue(keyId, out var certificatePem))
        {
            throw new SecurityTokenInvalidSigningKeyException("Firebase token key id is not trusted.");
        }

        using var certificate = X509Certificate2.CreateFromPem(certificatePem);
        var validationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = expectedIssuer,
            ValidateAudience = true,
            ValidAudience = _firebaseOptions.ProjectId,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new X509SecurityKey(certificate) { KeyId = keyId },
            ClockSkew = TimeSpan.FromMinutes(2),
            ValidAlgorithms = [SecurityAlgorithms.RsaSha256]
        };

        var principal = tokenHandler.ValidateToken(
            idToken,
            validationParameters,
            out _);

        var subject = principal.FindFirstValue(JwtRegisteredClaimNames.Sub);
        if (string.IsNullOrWhiteSpace(subject))
        {
            throw new SecurityTokenException("Firebase token subject is missing.");
        }

        var email = principal.FindFirstValue(JwtRegisteredClaimNames.Email);
        if (string.IsNullOrWhiteSpace(email))
        {
            throw new SecurityTokenException("Firebase token email is missing.");
        }

        var rawName = principal.FindFirstValue("name");
        var name = string.IsNullOrWhiteSpace(rawName)
            ? email.Split('@', 2)[0]
            : rawName.Trim();
        var emailVerified = bool.TryParse(
            principal.FindFirstValue("email_verified"),
            out var parsedEmailVerified) && parsedEmailVerified;

        return new FirebaseUserInfo(
            subject,
            email.Trim().ToLowerInvariant(),
            name,
            principal.FindFirstValue("picture")?.Trim(),
            emailVerified);
    }

    private async Task<Dictionary<string, string>> GetFirebaseCertificatesAsync(CancellationToken cancellationToken)
    {
        var certificates = await httpClient.GetFromJsonAsync<Dictionary<string, string>>(
            FirebaseCertificatesUrl,
            cancellationToken);

        return certificates is { Count: > 0 }
            ? certificates
            : throw new InvalidOperationException("Firebase public certificates could not be loaded.");
    }
}
