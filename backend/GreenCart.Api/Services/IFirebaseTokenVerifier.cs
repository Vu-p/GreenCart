namespace GreenCart.Api.Services;

public interface IFirebaseTokenVerifier
{
    Task<FirebaseUserInfo> VerifyAsync(string idToken, CancellationToken cancellationToken);
}
