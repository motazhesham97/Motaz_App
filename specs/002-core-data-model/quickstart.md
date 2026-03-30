# Quickstart: Core Data Model

**Branch**: `002-core-data-model` | **Date**: 2026-03-22

## Prerequisites

- Phase 1 (Workspace Foundation) complete and all tasks passing
- Flutter SDK 3.32.0+ installed
- Dart SDK 3.x installed
- Serverpod CLI installed (`dart pub global activate serverpod_cli`)

## Development Setup

### 1. Switch to feature branch

```bash
git checkout 002-core-data-model
```

### 2. Install dependencies

```bash
# Flutter app
cd motaz_app/motaz_app_flutter
dart pub get

# Server
cd ../motaz_app_server
dart pub get
```

### 3. After making changes to Drift tables

Run code generation to produce the `.g.dart` files:

```bash
cd motaz_app/motaz_app_flutter
dart run build_runner build --delete-conflicting-outputs
```

### 4. After making changes to Serverpod models (.spy.yaml)

Run Serverpod code generation:

```bash
cd motaz_app/motaz_app_server
serverpod generate
```

### 5. Run tests

```bash
cd motaz_app/motaz_app_flutter
flutter test test/core/database/
```

## Key Conventions

- **One table per file**: Each Drift table class lives in its own file under `lib/core/database/tables/`
- **One model per file**: Each Serverpod model lives in its own `.spy.yaml` file under `lib/src/models/`
- **Money = integers**: All monetary columns use `integer()` in Drift, `int` in Serverpod. Never `real()` or `double`.
- **UUID storage**: UUIDs are stored as text in SQLite and as native `uuid` columns in PostgreSQL
- **Enums**: Drift uses `intEnum()` or `textEnum()`. Serverpod defines enums in separate `.spy.yaml` files
- **No hard delete**: Financial records use `status` + `void_reason` pattern

## File Map

| Purpose | Location |
|---------|----------|
| Drift table definitions | `motaz_app_flutter/lib/core/database/tables/` |
| Drift database class | `motaz_app_flutter/lib/core/database/app_database.dart` |
| Serverpod model definitions | `motaz_app_server/lib/src/models/` |
| Generated Drift code | `motaz_app_flutter/lib/core/database/app_database.g.dart` |
| Generated Serverpod code | `motaz_app_server/lib/src/generated/` |
| Database smoke tests | `motaz_app_flutter/test/core/database/` |
