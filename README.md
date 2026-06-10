# GreenCart

Week 1 implements the end-to-end authentication foundation for GreenCart:

- .NET 8 Web API in `backend/GreenCart.Api`
- SQLite development database
- Flutter mobile app in `greencart_app`
- Register, login, restore session, profile update, and logout
- Splash follows the Stitch design: `Get Started` opens Login, while an existing valid token opens the app.

Week 2 adds Product + Search:

- `GET /api/categories`
- `GET /api/products`
- `GET /api/products/{id}`
- Product listing supports `keyword`, `categoryId`, `minPrice`, and `maxPrice`
- Flutter Home Marketplace, Product Search/Category View, and Product Detail
- Product Detail has a UI-only `Add to Cart` placeholder for Week 3

## Run the API

```powershell
dotnet run --project backend\GreenCart.Api --launch-profile http
```

The API runs at `http://localhost:5126` and Swagger is available at:

```text
http://localhost:5126/swagger
```

The SQLite database file is created automatically as:

```text
backend/GreenCart.Api/greencart.db
```

Optional development admin seed is controlled by local `appsettings.json`:

```json
{
  "SeedAdmin": {
    "Email": "admin@example.local",
    "Password": "CHANGE_ME_ADMIN_PASSWORD"
  }
}
```

SQLite is the Week 1/MVP development database. Before the realtime Order/Admin phase, the project should migrate to PostgreSQL.

## Run the Flutter App

For Android emulator, the default API URL is already:

```text
http://10.0.2.2:5126
```

Run:

```powershell
cd greencart_app
flutter run
```

For Chrome, Windows, or a physical phone, pass a reachable API URL:

```powershell
flutter run --dart-define=API_BASE_URL=http://localhost:5126
```

For a physical phone, replace `localhost` with your computer LAN IP.

## Verify

```powershell
dotnet build backend\GreenCart.Api\GreenCart.Api.csproj
cd greencart_app
flutter analyze
flutter test
```

## Realtime Roadmap

Realtime features are documented for later weeks, not implemented in Week 2:

- Realtime Order Tracking: Admin changes order status through `Pending -> Confirmed -> Delivering -> Completed`; ASP.NET SignalR pushes updates to the customer Order Detail screen without refresh.
- Realtime Product Substitution: Admin proposes a replacement product when an item is out of stock; SignalR pushes an `Accept / Decline` popup to the customer app.
- Backend realtime technology: ASP.NET SignalR.
- Flutter realtime technology: `signalr_netcore`.
- Database for realtime/order phase: PostgreSQL.
