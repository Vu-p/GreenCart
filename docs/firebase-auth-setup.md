# Firebase Auth Setup

GreenCart mobile uses Firebase Auth for account sessions and Google Sign-In. The backend still issues GreenCart JWT after verifying Firebase ID tokens.

## Firebase Console

1. Create or open a Firebase project.
2. Enable Authentication providers:
   - Email/Password
   - Google
3. Add Android app using the package name from `greencart_app/android/app/build.gradle`.
4. Add SHA-1 and SHA-256 fingerprints for local debug Google Sign-In.
5. Download `google-services.json` into:

```text
greencart_app/android/app/google-services.json
```

6. If building iOS, download `GoogleService-Info.plist` into the iOS Runner target.

For local Android debugging, rebuild the app after replacing
`google-services.json`. If Google Sign-In reports a client configuration error
or cannot return an ID token, pass the Web client ID from `google-services.json`
as a Dart define:

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

## Backend

Set Firebase project id:

```json
{
  "Firebase": {
    "ProjectId": "your-firebase-project-id"
  }
}
```

The backend endpoint is:

```http
POST /api/auth/firebase-login
Authorization: Bearer {firebase_id_token}
```

It verifies the Firebase token, syncs the local `Users` row, and returns the existing GreenCart API JWT response.

## Database

Run migrations after pulling this change:

```bash
dotnet ef database update --project backend/GreenCart.Api/GreenCart.Api.csproj
```

If the API is running, stop/restart it so the new migration and config are loaded.
