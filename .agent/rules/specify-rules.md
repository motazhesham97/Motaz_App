# Motaz_App Development Guidelines

Auto-generated from all feature plans. Last updated: 2026-04-20

## Active Technologies
- Dart 3.x (Flutter SDK 3.32.0) + Drift (local SQLite ORM), Serverpod ORM (cloud PostgreSQL ORM), drift_dev (code generation) (002-core-data-model)
- SQLite (local, via Drift), PostgreSQL on Neon (cloud, via Serverpod ORM) (002-core-data-model)
- Dart 3.x (Flutter 3.32+) + Drift 2.x (local SQLite), Serverpod ORM (cloud PostgreSQL), flutter_riverpod (002-core-data-model)
- SQLite (local via Drift), PostgreSQL on Neon (cloud via Serverpod ORM) (002-core-data-model)
- Dart 3.x (Flutter 3.x + Serverpod latest) + Drift (local DB), Serverpod (backend endpoints + ORM), flutter_riverpod (state), connectivity_plus (network detection), cloudinary_dart or HTTP (uploads) (003-sync-foundation)
- SQLite (Drift) local, PostgreSQL (Neon) cloud, Cloudinary (attachments) (003-sync-foundation)
- Dart 3.x (Flutter 3.x + Serverpod latest stable) + Drift (local DB queries), flutter_riverpod (state), go_router (navigation), uuid (ID generation) (004-products-clients)
- SQLite (Drift) local — using existing schema from Phase 2 (004-products-clients)
- SQLite (Drift) local — Expenses table exists from Phase 2; MonthlyDistributions table must be added (006-expenses-profit)
- SQLite (Drift) local — SalesReturns and SalesReturnLines tables exist from Phase 2 (007-partial-returns-reversals)
- Dart 3.8+ / Flutter 3.32+ + flutter_riverpod, drift, go_router, pdf (^3.11.1), printing (^5.13.3), google_fonts (008-reports-dashboard-pdf)
- SQLite via Drift (local, compute-on-read queries; no new tables) (008-reports-dashboard-pdf)
- Dart 3.8+ / Flutter 3.32+ + flutter_riverpod, drift, go_router, pdf (^3.11.1), printing (^5.13.3), logging, connectivity_plus, path_provider (009-hardening-release)
- SQLite via Drift (existing schema v4, no new tables) (009-hardening-release)

- Dart 3.x (Flutter SDK latest stable, Serverpod latest stable) + Flutter, Serverpod, Drift, flutter_riverpod, connectivity_plus, go_router, flutter_localizations (001-workspace-foundation)

## Project Structure

```text
src/
tests/
```

## Commands

# Add commands for Dart 3.x (Flutter SDK latest stable, Serverpod latest stable)

## Code Style

Dart 3.x (Flutter SDK latest stable, Serverpod latest stable): Follow standard conventions

## Recent Changes
- 009-hardening-release: Added Dart 3.8+ / Flutter 3.32+ + flutter_riverpod, drift, go_router, pdf (^3.11.1), printing (^5.13.3), logging, connectivity_plus, path_provider
- 008-reports-dashboard-pdf: Added Dart 3.8+ / Flutter 3.32+ + flutter_riverpod, drift, go_router, pdf (^3.11.1), printing (^5.13.3), google_fonts
- 007-partial-returns-reversals: Added Dart 3.x (Flutter 3.x + Serverpod latest stable) + Drift (local DB queries), flutter_riverpod (state), go_router (navigation), uuid (ID generation)


<!-- MANUAL ADDITIONS START -->
<!-- MANUAL ADDITIONS END -->
