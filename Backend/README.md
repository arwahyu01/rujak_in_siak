# RUJAK.IN.SIAK POS — Backend

Laravel 13 modular-monolith backend for the RUJAK.IN.SIAK offline-first POS. It
provides the Inertia back-office plus a Sanctum-secured `/api/v1` API for the
Flutter Android terminal.

The API covers authentication, PIN, device registration/revocation, signed
offline authorization leases, catalog, orders with optimistic concurrency,
deterministic integer-rupiah checkout, split payments and verification, refunds
and voids, shifts with immutable closing snapshots, sync push/pull/bootstrap,
and timezone-aware reports.

## Quick start

```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
php artisan serve
```

The default owner account is `owner@rujakinsiak.test` / `password` (override
with `ADMIN_NAME`, `ADMIN_EMAIL`, `ADMIN_PASSWORD` before seeding). Change the
password immediately.

See [docs/SETUP.md](docs/SETUP.md) for prerequisites, environment, API auth and
device registration, the offline lease and sync protocol, and production notes.
The API contract is in [docs/openapi.yaml](docs/openapi.yaml).

On this development machine, PHP 8.4 is at
`D:/Aplikasi/laragon/bin/php/php-8.4.27-Win32-vs17-x64/php.exe`.

## Testing

```bash
php artisan test
vendor/bin/pint --test
```

Tests use in-memory SQLite and do not touch the configured MySQL database.

## Scope

MVP scope only: single active outlet per business, no inventory/recipe/HPP,
purchasing, finance, loyalty, KDS, QR self-ordering, or AI features.

## License

Proprietary — RUJAK.IN.SIAK.
