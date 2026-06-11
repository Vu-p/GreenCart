# GreenCart

Week 1 implements the end-to-end authentication foundation for GreenCart:

- .NET 8 Web API in `backend/GreenCart.Api`
- SQLite app database
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

If your local database was created before EF Core migrations were added, delete `backend/GreenCart.Api/greencart.db` once and restart the API so SQLite can rebuild from migrations.

Optional development admin seed is controlled by local `appsettings.json`:

```json
{
  "SeedAdmin": {
    "Email": "admin@example.local",
    "Password": "CHANGE_ME_ADMIN_PASSWORD"
  }
}
```

SQLite is the application database for GreenCart. Later order, admin, and realtime phases continue to use SQLite with EF Core migrations.

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

## Backend Roadmap

Backend features are implemented progressively by feature branch:

- Auth/Profile: register, login, restore session, profile update, logout, and password change.
- Catalog: categories, products, filters, deals, organic and stock views.
- Cart/Checkout/Orders: authenticated cart, checkout transaction, order history, order tracking, and cancellation.
- Reviews/Admin/Realtime: order reviews, product reviews, admin product/order management, and SignalR order updates.
- Database: SQLite remains the database for all phases.
