# GreenCart API Specification

Version: 0.1  
Last updated: 2026-06-12  
Backend: ASP.NET Core 8 Web API  
Database: SQLite with EF Core migrations  
Auth: JWT Bearer

## Status Legend

- `DONE`: Backend endpoint implemented.
- `MOBILE`: Flutter mobile has been connected to the endpoint.
- `UI_ONLY`: Flutter screen exists but still uses mock/local behavior.
- `BACKEND_ONLY`: Backend exists, no mobile/admin UI integration yet.
- `PLANNED`: Not implemented yet.

## Global Conventions

- Base URL local dev: `http://localhost:5126`
- Mobile emulator URL: `http://10.0.2.2:5126`
- Protected endpoints require header:

```http
Authorization: Bearer {jwt}
```

- Standard errors:
  - `400`: invalid input or validation error
  - `401`: unauthenticated or invalid token
  - `403`: role does not have permission
  - `404`: resource not found
  - `409`: business conflict or invalid state

- IDs are `Guid` unless noted.
- Money uses `decimal` on backend and JSON number on client.
- Catalog read APIs are public. Cart, checkout, orders, profile, review are customer-authenticated. Admin APIs require `Admin` role.

---

## 1. Authentication & Profile

### Business Requirements

- Customer can register, login, restore session, update profile, and logout.
- Email is normalized to lowercase.
- Password minimum length is 8 characters.
- JWT is stateless; logout on backend is a no-op for compatibility, mobile clears local token.

### `POST /api/auth/register`

Status: `DONE`, `MOBILE`

Registers a new customer account and returns JWT + user profile.

Request:

```json
{
  "name": "Test Customer",
  "email": "customer@example.com",
  "password": "password123"
}
```

Response `200`:

```json
{
  "token": "jwt-token",
  "user": {
    "id": "guid",
    "name": "Test Customer",
    "email": "customer@example.com",
    "role": "Customer",
    "phone": null,
    "address": null,
    "avatarUrl": null,
    "createdAt": "2026-06-12T00:00:00Z"
  }
}
```

Errors:

- `409`: email already registered

### `POST /api/auth/login`

Status: `DONE`, `MOBILE`

Authenticates an existing account.

Request:

```json
{
  "email": "customer@example.com",
  "password": "password123"
}
```

Response: same as register.

Errors:

- `401`: invalid email/password

### `GET /api/auth/me`

Status: `DONE`, `MOBILE`

Restores current user from JWT.

Response `200`: `UserResponse`

### `POST /api/auth/logout`

Status: `DONE`, `MOBILE local only`

Backend returns `204`. Mobile currently clears token locally.

### `PUT /api/auth/change-password`

Status: `DONE`, `BACKEND_ONLY`

Changes password for current user.

Request:

```json
{
  "currentPassword": "password123",
  "newPassword": "newPassword123"
}
```

Response:

- `204`: changed
- `401`: current password incorrect

### `PUT /api/profile`

Status: `DONE`, `MOBILE`

Updates customer profile and delivery details.

Request:

```json
{
  "name": "Test Customer",
  "phone": "0900000000",
  "address": "221B Green Market Street",
  "avatarUrl": null
}
```

Response `200`: `UserResponse`

---

## 2. Catalog: Categories & Products

### Business Requirements

- Customer can browse categories and products without login.
- Products can be searched and filtered by keyword, category, price, organic/deal status, and stock availability.
- Product detail shows stock; out-of-stock product cannot be added to cart.

### `GET /api/categories`

Status: `DONE`, `MOBILE`

Returns all categories ordered by name.

Response:

```json
[
  {
    "id": "guid",
    "name": "Vegetables",
    "imageUrl": "https://..."
  }
]
```

### `GET /api/products`

Status: `DONE`, `MOBILE`

Query parameters:

- `keyword`: optional string
- `categoryId`: optional guid
- `minPrice`: optional decimal
- `maxPrice`: optional decimal
- `isDeal`: optional bool
- `isOrganic`: optional bool
- `inStock`: optional bool

Response:

```json
[
  {
    "id": "guid",
    "name": "Organic Spinach",
    "description": "Tender organic spinach leaves...",
    "price": 3.49,
    "stock": 42,
    "imageUrl": "https://...",
    "categoryId": "guid",
    "categoryName": "Vegetables",
    "isOrganic": true,
    "isDeal": true
  }
]
```

### `GET /api/products/{id}`

Status: `DONE`, `MOBILE`

Returns product detail by id.

Errors:

- `404`: product not found

### `GET /api/products/{id}/reviews`

Status: `DONE`, `BACKEND_ONLY`

Returns product reviews.

Response:

```json
[
  {
    "id": "guid",
    "productId": "guid",
    "rating": 5,
    "comment": "Fresh and well packed.",
    "createdAt": "2026-06-12T00:00:00Z"
  }
]
```

---

## 3. Cart

### Business Requirements

- Cart belongs to the current authenticated customer.
- Customer can add, update, remove items, and clear cart.
- Quantity must be at least 1.
- Quantity cannot exceed current product stock.
- Out-of-stock products cannot be added.
- Cart response includes subtotal, delivery fee estimate, and total estimate.

### `GET /api/cart`

Status: `DONE`, `MOBILE`

Returns current customer's cart.

Response:

```json
{
  "items": [
    {
      "productId": "guid",
      "productName": "Organic Spinach",
      "imageUrl": "https://...",
      "unitPrice": 3.49,
      "quantity": 2,
      "lineTotal": 6.98,
      "stock": 42
    }
  ],
  "subtotal": 6.98,
  "deliveryFee": 2.9,
  "total": 9.88
}
```

### `POST /api/cart/items`

Status: `DONE`, `MOBILE`

Adds quantity to an item. If the product is already in cart, quantity is incremented.

Request:

```json
{
  "productId": "guid",
  "quantity": 1
}
```

Response `200`: `CartResponse`

Errors:

- `404`: product not found
- `409`: product out of stock or quantity exceeds stock

### `PUT /api/cart/items/{productId}`

Status: `DONE`, `BACKEND_ONLY`

Sets item quantity.

Request:

```json
{
  "quantity": 3
}
```

Response `200`: `CartResponse`

### `DELETE /api/cart/items/{productId}`

Status: `DONE`, `MOBILE`

Removes one item from cart.

Response `200`: `CartResponse`

### `DELETE /api/cart`

Status: `DONE`, `BACKEND_ONLY`

Clears cart.

Response `200`: empty `CartResponse`

---

## 4. Checkout, Payment & Delivery Slot

### Business Requirements

- Customer reviews delivery address, delivery slot, payment method, and substitution preference before placing order.
- Checkout creates an order from current cart.
- Product name, image, price, and quantity are snapshotted into order items.
- Checkout runs inside a SQLite transaction:
  - validate cart
  - validate stock
  - create order
  - decrement stock
  - clear cart
- Current payment is MVP mock payment. No real gateway yet.
- Delivery slot exists in UI but is not persisted as a backend entity yet.

### `POST /api/checkout/preview`

Status: `DONE`, `MOBILE`

Returns cart totals and default delivery information before payment.

Response:

```json
{
  "items": [],
  "subtotal": 20.0,
  "deliveryFee": 2.9,
  "total": 22.9,
  "deliveryAddress": "221B Green Market Street",
  "deliveryPhone": "0900000000",
  "substitutionPreference": "Contact me before replacing out-of-stock items."
}
```

### `POST /api/checkout`

Status: `DONE`, `MOBILE`

Creates an order from cart.

Request:

```json
{
  "deliveryAddress": "221B Green Market Street",
  "deliveryPhone": "0900000000",
  "substitutionPreference": "Contact me before replacing out-of-stock items."
}
```

Response `201`: `OrderResponse`

Errors:

- `409`: cart empty, product unavailable, or stock not enough

### `PUT /api/checkout/substitution`

Status: `DONE`, `UI_ONLY`

MVP endpoint returns selected substitution preference. It does not persist to an active checkout session yet.

Request:

```json
{
  "substitutionPreference": "Replace with best similar product under same category."
}
```

Response:

```json
{
  "substitutionPreference": "Replace with best similar product under same category."
}
```

### `POST /api/payments/intent`

Status: `PLANNED`

Creates a payment intent/session for a real payment provider.

Business requirement:

- Only needed when moving beyond mock Visa payment.
- Must be tied to current checkout/order.

### `POST /api/payments/webhook`

Status: `PLANNED`

Receives payment provider webhook and updates order payment status.

---

## 5. Orders & Tracking

### Business Requirements

- Customer can view order history and order detail.
- Customer can cancel order only before delivery/completion.
- Admin can update order status.
- Order statuses:
  - `Pending`
  - `Confirmed`
  - `Packing`
  - `Delivering`
  - `Completed`
  - `Cancelled`
- Realtime order tracking requirement: when admin updates order status, customer Order Detail should update without refresh.

### `GET /api/orders`

Status: `DONE`, `MOBILE`

Returns current customer's orders, newest first.

Response:

```json
[
  {
    "id": "guid",
    "orderNumber": "GC-2048",
    "status": "Confirmed",
    "paymentStatus": "Paid",
    "deliveryAddress": "221B Green Market Street",
    "deliveryPhone": "0900000000",
    "substitutionPreference": null,
    "subtotal": 20.0,
    "deliveryFee": 2.9,
    "total": 22.9,
    "items": [],
    "createdAt": "2026-06-12T00:00:00Z",
    "updatedAt": "2026-06-12T00:00:00Z",
    "hasReview": false
  }
]
```

### `GET /api/orders/{id}`

Status: `DONE`, `MOBILE`

`id` can be order `Guid` or `orderNumber`.

Response `200`: `OrderResponse`

### `POST /api/orders/{id}/cancel`

Status: `DONE`, `BACKEND_ONLY`

Cancels order owned by current user.

Errors:

- `409`: order is already delivering, completed, or cancelled

---

## 6. Product Substitution

### Business Requirements

- If a product selected by customer is out of stock, the system should suggest replacement products.
- Replacement products must be:
  - same or similar category as the original product
  - in stock
  - sorted by price from low to high
- Admin can propose a replacement product.
- Customer receives realtime popup with `Accept` and `Decline`.
- Accepted substitution updates the cart/order item.
- Declined substitution keeps original item unavailable or lets customer remove it.

### `GET /api/products/{productId}/substitutions`

Status: `PLANNED`

Returns replacement candidates for an out-of-stock product.

Query parameters:

- `limit`: optional integer, default `5`

Response:

```json
[
  {
    "id": "guid",
    "name": "Similar Fresh Milk",
    "price": 2.19,
    "stock": 12,
    "imageUrl": "https://...",
    "categoryId": "guid",
    "categoryName": "Dairy",
    "isOrganic": false,
    "isDeal": true
  }
]
```

Sorting:

1. Same category first.
2. In-stock only.
3. Lowest price first.

### `POST /api/admin/orders/{orderId}/substitutions`

Status: `PLANNED`

Admin proposes a replacement for an order item.

Request:

```json
{
  "orderItemId": "guid",
  "originalProductId": "guid",
  "replacementProductId": "guid",
  "note": "Original milk is out of stock. This is the closest lower-price option."
}
```

Response:

```json
{
  "id": "guid",
  "orderId": "guid",
  "orderItemId": "guid",
  "originalProductId": "guid",
  "replacementProductId": "guid",
  "status": "PendingCustomerDecision",
  "note": "Original milk is out of stock..."
}
```

### `POST /api/orders/{orderId}/substitutions/{substitutionId}/accept`

Status: `PLANNED`

Customer accepts replacement.

Business behavior:

- Replace original order item product snapshot with replacement snapshot.
- Recalculate totals if needed.
- Persist customer decision.
- Broadcast realtime update.

### `POST /api/orders/{orderId}/substitutions/{substitutionId}/decline`

Status: `PLANNED`

Customer declines replacement.

Business behavior:

- Mark substitution declined.
- Do not replace item.
- Admin/customer must decide whether to remove item/refund later.

### SignalR Event: `SubstitutionProposed`

Status: `PLANNED`

Hub: `/hubs/orders`

Payload:

```json
{
  "orderId": "guid",
  "substitutionId": "guid",
  "originalProduct": {},
  "replacementProduct": {},
  "note": "..."
}
```

---

## 7. Rating & Review

### Business Requirements

- Customer can review only their own completed order.
- One order can only be reviewed once.
- Rating is 1 to 5.
- Comment is optional.
- Product-level reviews must refer to products from that order.

### `POST /api/orders/{id}/review`

Status: `DONE`, `UI_ONLY`

Backend implemented. Mobile Rating screen exists but does not submit this API yet.

Request:

```json
{
  "rating": 5,
  "comment": "Fresh produce and smooth delivery.",
  "productReviews": [
    {
      "productId": "guid",
      "rating": 5,
      "comment": "Very fresh."
    }
  ]
}
```

Response `201`: `OrderReviewResponse`

Errors:

- `409`: order not completed, already reviewed, or product not in order

---

## 8. Meal Planner

### Business Requirements

- Customer can browse suggested meals/recipes.
- Customer selects a meal and sees recipe detail.
- Recipe detail has ingredients list.
- Customer can:
  - add a single ingredient to cart
  - add all recipe ingredients to cart
- If an ingredient maps to multiple products, choose the most relevant in-stock product.
- If ingredient product is out of stock, use Product Substitution logic:
  - same/similar category
  - in stock
  - lowest price first

### `GET /api/meal-plans`

Status: `PLANNED`

Returns meal planner recipes.

Response:

```json
[
  {
    "id": "green-bowl",
    "title": "Green Power Bowl",
    "subtitle": "Spinach, avocado, brown rice, and yogurt dressing.",
    "minutes": 22,
    "calories": 520,
    "imageUrl": "https://..."
  }
]
```

### `GET /api/meal-plans/{id}`

Status: `PLANNED`

Returns recipe detail with ingredients.

Response:

```json
{
  "id": "green-bowl",
  "title": "Green Power Bowl",
  "subtitle": "Spinach, avocado, brown rice, and yogurt dressing.",
  "minutes": 22,
  "calories": 520,
  "ingredients": [
    {
      "id": "guid",
      "name": "Organic Spinach",
      "quantityLabel": "1 pack",
      "productId": "guid",
      "required": true
    }
  ],
  "steps": [
    "Warm cooked brown rice with a pinch of salt."
  ]
}
```

### `POST /api/meal-plans/{id}/cart-items`

Status: `PLANNED`

Adds selected recipe ingredients to cart.

Request:

```json
{
  "ingredientIds": ["guid"],
  "addAll": false
}
```

Business behavior:

- If `addAll = true`, ignore `ingredientIds` and add every ingredient.
- If `addAll = false`, add only selected ingredients.
- For each ingredient:
  - find mapped product
  - validate stock
  - if out of stock, return substitution candidates
  - add in-stock product to cart

Response:

```json
{
  "cart": {},
  "unavailableIngredients": [
    {
      "ingredientId": "guid",
      "name": "Fresh Milk",
      "substitutions": []
    }
  ]
}
```

Current implementation:

- Mobile Meal Planner UI exists with mock recipe data.
- Recipe detail has ingredient list and an Add Ingredients button.
- Backend APIs are not implemented yet.

---

## 9. Deals

### Business Requirements

- Customer can open Deals screen from Home promo banner.
- Deals show seasonal bundles/coupons.
- Deal products should eventually be derived from products where `isDeal = true`.

### `GET /api/deals`

Status: `PLANNED`

Recommended backend endpoint for Deals screen.

Current implementation:

- Public product API supports `GET /api/products?isDeal=true`.
- Mobile Deals screen currently uses mock deal bundles.

---

## 10. Admin APIs

### Business Requirements

- Admin can manage products, categories, and orders.
- Admin can update order status.
- Admin actions should be protected by `Admin` role.

### `GET /api/admin/orders`

Status: `DONE`, `BACKEND_ONLY`

Returns all orders for admin.

### `PUT /api/admin/orders/{id}/status`

Status: `DONE`, `BACKEND_ONLY`

Updates order status and broadcasts SignalR event.

Request:

```json
{
  "status": "Delivering"
}
```

Business behavior:

- Persist new status.
- Persist realtime event.
- Broadcast `OrderStatusChanged` to order groups.

### `GET /api/admin/products`

Status: `DONE`, `BACKEND_ONLY`

Returns all products.

### `POST /api/admin/products`

Status: `DONE`, `BACKEND_ONLY`

Creates product.

### `PUT /api/admin/products/{id}`

Status: `DONE`, `BACKEND_ONLY`

Updates product.

### `DELETE /api/admin/products/{id}`

Status: `DONE`, `BACKEND_ONLY`

Deletes product.

### `POST /api/admin/categories`

Status: `DONE`, `BACKEND_ONLY`

Creates category.

### `PUT /api/admin/categories/{id}`

Status: `DONE`, `BACKEND_ONLY`

Updates category.

### `DELETE /api/admin/categories/{id}`

Status: `DONE`, `BACKEND_ONLY`

Deletes category if it has no products.

### Admin UI

Status: `PLANNED`

Needed screens:

- Admin login or role-aware entry
- Product management
- Category management
- Order management
- Substitution proposal panel

---

## 11. Realtime

### Business Requirements

- Customer Order Detail updates without manual refresh when admin changes order status.
- Product substitution proposal appears as realtime popup.
- Backend persists important realtime events before sending them.

### Hub `/hubs/orders`

Status: `DONE`, `BACKEND_ONLY`

Methods:

- `JoinOrder(orderId)`
- `LeaveOrder(orderId)`

### Event `OrderStatusChanged`

Status: `DONE`, `BACKEND_ONLY`

Backend sends event when admin updates order status.

Flutter status:

- `PLANNED`: Flutter does not currently include SignalR client or realtime subscription.

### Event `SubstitutionProposed`

Status: `PLANNED`

See Product Substitution section.

---

## 12. Optional/Future Features From SRS

These are listed as extensions if time remains.

### Wishlist

Status: `PLANNED`

Suggested APIs:

- `GET /api/wishlist`
- `POST /api/wishlist/items`
- `DELETE /api/wishlist/items/{productId}`

### Voucher

Status: `PLANNED`

Suggested APIs:

- `GET /api/vouchers`
- `POST /api/cart/apply-voucher`

### Smart Reorder

Status: `PLANNED`

Suggested APIs:

- `GET /api/reorders/suggestions`
- `POST /api/reorders/{orderId}/cart`

### Notification

Status: `PLANNED`

Suggested APIs:

- `GET /api/notifications`
- `PUT /api/notifications/{id}/read`

### Recommendation System

Status: `PLANNED`

Suggested APIs:

- `GET /api/recommendations/products`
- `GET /api/recommendations/meals`

---

## Current Completion Summary

### Completed Backend

- Auth/Profile
- Catalog
- Cart
- Checkout
- Orders
- Reviews
- Admin product/category/order APIs
- SQLite migrations
- SignalR hub foundation

### Completed Mobile Integration

- Auth/Profile
- Catalog/Product Detail
- Cart
- Checkout
- Order history/detail
- Payment success route

### Mobile UI Exists But Needs Backend Integration

- Rating & Review submit
- Deals real data
- Meal Planner real data and add selected ingredients
- Product Substitution realtime popup

### Not Implemented Yet

- Real payment gateway
- Delivery slot persistence
- Product substitution APIs and data model
- Meal planner APIs and data model
- Admin UI
- Flutter SignalR client
- Optional wishlist/voucher/smart reorder/notifications/recommendations
