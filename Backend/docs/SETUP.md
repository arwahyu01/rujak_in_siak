# RUJAK.IN.SIAK POS — Backend Setup

Laravel 13 modular-monolith back-office and `/api/v1` backend for the RUJAK.IN.SIAK
offline-first Flutter POS. The Inertia back-office remains available; the API is
additive.

Prerequisites: PHP 8.3+ (tested on 8.4.27), Composer, MySQL 8 / MariaDB (or SQLite
for a quick local run), Node.js 20+ and npm for back-office assets.

## 1. Install

```bash
composer install
cp .env.example .env
php artisan key:generate
```

On this Windows machine use the Laragon PHP 8.4 binary explicitly:

```bash
PHP="D:/Aplikasi/laragon/bin/php/php-8.4.27-Win32-vs17-x64/php.exe"
"$PHP" artisan key:generate
```

## 2. Environment

`.env.example` already targets MySQL and the business timezone:

```dotenv
APP_ENV=production
APP_DEBUG=false
APP_TIMEZONE=Asia/Jakarta
DB_CONNECTION=mysql
DB_DATABASE=rujak_in_siak
DB_USERNAME=root
DB_PASSWORD=
QUEUE_CONNECTION=database
CACHE_STORE=database
```

Set `APP_KEY` (used to sign offline leases) and change `APP_DEBUG` to `false` in
production. `DB_CONNECTION=sqlite` with `DB_DATABASE=/absolute/path/database.sqlite`
also works without MySQL.

The bootstrap owner account reads `ADMIN_NAME`, `ADMIN_EMAIL`, and
`ADMIN_PASSWORD` from `.env`.

## 3. Database

```bash
php artisan migrate --seed
```

Seeded data:

- Business `Rujak In Siak` and outlet `PUSAT` (`timezone = Asia/Jakarta`).
- Permissions and roles (`owner`, and the operational roles defined in
  `RoleSeeder`).
- Owner login `owner@rujakinsiak.test` / `password` by default. Change the
  password immediately; never keep the default in production.

Optional demo catalog data is not seeded by `DatabaseSeeder`; create products via
`POST /api/v1/products` or the back-office.

Database tables of interest: `businesses`, `outlets`, `users`, `roles`,
`permissions`, `devices`, `user_sessions`, `authorization_leases`, `categories`,
`products`, `orders`, `order_items`, `sales`, `sale_items`, `sale_payments`,
`payment_verification_logs`, `shifts`, `shift_cash_movements`,
`shift_closing_snapshots`, `sync_events`, `sync_cursors`, `sync_logs`,
`idempotency_keys`, `audit_logs`.

## 4. Run

```bash
php artisan serve
npm install
npm run dev        # or: npm run build for a production asset build
```

The API is served under `/api/v1`. Back-office pages live at `/login` and the
dashboard.

## 5. API authentication and devices

All protected endpoints use Sanctum bearer tokens plus the `X-Device-Id` header
(device UUID registered for the signed-in user's business/outlet).

### Login

```bash
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"identifier":"owner@rujakinsiak.test","password":"password"}'
```

`identifier` accepts an email or username. When `device_uuid` is supplied, the
response also contains an `offline_lease` for that device. Tokens last 30 days;
`POST /auth/refresh` rotates them.

Login failures are rate limited to 5 attempts per identifier/IP per minute.
After 5 consecutive wrong passwords the account is locked for 15 minutes
(`AUTH_LOCKED`).

### Register a device

```bash
curl -X POST http://localhost:8000/api/v1/devices/register \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "uuid":"6f1c2f0e-0a5b-4e1e-9d0e-3f8f0a1b2c3d",
    "name":"Kasir 1",
    "terminal_code":"KSR1",
    "platform":"android",
    "app_version":"1.0.0",
    "device_fingerprint":"sha256-of-android-id"
  }'
```

Terminal codes are unique per outlet. A revoked device cannot re-register
(`DEVICE_REVOKED`); a registration from another tenant returns
`DEVICE_SCOPE_MISMATCH`. `POST /devices/{uuid}/revoke` revokes the device, its
tokens, sessions, and offline leases.

Send the returned device UUID as `X-Device-Id` on every device-scoped request.

### PIN

`PUT /api/v1/me/pin` accepts `current_password`, `pin` (4–6 digits), and the
matching `pin_confirmation`. Setting a PIN increments `auth_version`, revokes
the current device's leases, and requires a fresh offline lease.

## 6. Offline authorization lease

`POST /api/v1/auth/offline-lease` (requires `X-Device-Id`):

```json
{ "hours": 72 }
```

If the user has a PIN, include `pin` or `password` as proof
(`AUTH_PROOF_REQUIRED` / `AUTH_PROOF_INVALID` otherwise). `hours` must be 1–72
(72 when omitted). The returned `token` is HMAC-SHA256 signed with `APP_KEY` and bound to the
user, device, business, outlet, roles, permissions, and `auth_version`.

Every offline sync push must include this token as `lease_token`. A lease may
have expired by the time the batch is pushed, but it must have been valid at each
event's `occurred_at`. Events after a revocation are rejected
(`LEASE_REVOKED_AT_EVENT`, `LEASE_EXPIRED_AT_EVENT`, `LEASE_NOT_YET_ISSUED`).

## 7. Catalog

- `GET /api/v1/categories` — active categories by default; `include_inactive=1`,
  `updated_since=<iso8601>`.
- `GET /api/v1/products` — active and available by default; `include_inactive=1`,
  `include_unavailable=1`, `category_uuid`, `q`, `updated_since`, `per_page`
  (max 200).
- `POST /api/v1/products`, `PUT /api/v1/products/{uuid}` — `products.manage`.

Catalog responses include `catalog_version` metadata. Devices must refresh the
catalog at least every 72 hours (`OFFLINE_CATALOG_MAX_AGE_HOURS`).

## 8. Orders, checkout, payments, shifts, reports

- Orders: create, update, hold, resume, cancel with `version` /
  `base_version` optimistic concurrency. One finalized sale per order.
- Checkout: idempotent `POST /api/v1/sales/checkout` with integer rupiah,
  discounts, service charge, tax, split payments, and `receipt_number` in the
  form `RJS-{OUTLET}-{TERMINAL}-{SEQUENCE}`.
- Non-cash payments can be `awaiting_verification`; verify/reject through
  `POST /api/v1/payments/{uuid}/verify|reject` by a different officer (online
  only). Void requires no confirmed/awaiting payment; refunds cannot exceed
  confirmed-but-unrefunded amounts.
- Shifts: open, cash in/out, close with an immutable closing snapshot, and
  reconcile pending sync. Held orders block close (`SHIFT_HAS_HELD_ORDERS`).
- Reports: `GET /api/v1/reports/{sales,payments,products,shifts}` with
  `date_from`, `date_to` (business timezone), and optional `outlet_uuid`.
  Maximum range is 5 years.

Report grouping uses SQL `DATE(transacted_at)`, so `APP_TIMEZONE` must match the
business timezone. Multi-timezone businesses are not supported in the MVP.

## 9. Sync protocol (Module 11)

Protocol/schema version: `1`. Push accepts at most 50 events and roughly 1 MB.

### Push

```bash
curl -X POST http://localhost:8000/api/v1/sync/push \
  -H "Authorization: Bearer $TOKEN" \
  -H "X-Device-Id: $DEVICE_UUID" \
  -H 'Content-Type: application/json' \
  -d '{
    "protocol_version": 1,
    "batch_id": "0b6f4e8a-2c1d-4a1f-9f2e-7b3c9d0e1f2a",
    "device_id": "'"$DEVICE_UUID"'",
    "outlet_id": "'"$OUTLET_UUID"'",
    "origin": "offline",
    "lease_token": "'"$LEASE_TOKEN"'",
    "events": [{
      "event_id": "5f0e1d2c-3b4a-4a5b-8c9d-0e1f2a3b4c5d",
      "event_type": "order.created",
      "aggregate_type": "order",
      "aggregate_id": "ORDER_UUID",
      "sequence": 1,
      "schema_version": 1,
      "occurred_at": "2026-11-05T10:15:00+07:00",
      "payload": { "order_uuid": "ORDER_UUID", "items": [], "subtotal": 0, "total": 0 }
    }]
  }'
```

Each event is applied in its own transaction. Per-event results are `accepted`,
`duplicate`, `rejected`, `conflict`, `blocked_dependency`, or
`upgrade_required`. Retrying the same `event_id` with the same payload is safe;
a different payload for the same `event_id` is rejected as an idempotency
conflict. Order updates use `base_version`, never last-write-wins.

### Pull / bootstrap / status

- `GET /api/v1/sync/pull?cursor=...&limit=...` — opaque scoped cursor, max 500
  changes per page; deliver `next_cursor` back on the next call. An invalid
  cursor returns `CURSOR_INVALID`.
- `GET /api/v1/sync/bootstrap` — device, outlet, user, catalog, and cursor seed
  for a fresh install.
- `GET /api/v1/sync/status` — device sequence, cursor, pending/conflict/rejected
  counters, catalog version.

Rate limits: API 120 requests/minute; sync push 30/minute.

## 10. Testing and formatting

```bash
php artisan test
vendor/bin/pint --test
php artisan route:list --path=api/v1
```

Tests run on in-memory SQLite (`phpunit.xml`) and never touch the production
database. The OpenAPI contract is in [`docs/openapi.yaml`](openapi.yaml).

## 11. Production notes

- Serve behind HTTPS; rotate `APP_KEY` only with a planned lease/token reissue.
- Run `php artisan migrate --force` and `php artisan config:cache` during deploy.
- Keep `APP_DEBUG=false`; API errors use the `{error:{code,message,details?}}`
  envelope and never expose stack traces.
- Back up the database before migrations. Removing a device token/lease or
  revoking a device is an operational action with audit records.
