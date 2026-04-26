# Quickstart: Hardening & Release Readiness

**Branch**: `009-hardening-release` | **Date**: 2026-04-20

## Prerequisites

- Phases 1–8 implemented and `dart analyze` clean
- Android device and Windows laptop available for testing
- Neon database accessible for sync testing
- App running on both platforms via `flutter run`

## Setup

```bash
git checkout 009-hardening-release
cd motaz_app/motaz_app_flutter
flutter pub get
dart analyze   # must be 0 errors, 0 warnings
```

## Key Files to Modify

### Logging Infrastructure
- `lib/core/logging/app_logger.dart` — Fix log file path, add rotation, add structured format

### Settings Screen (new)
- `lib/features/settings/presentation/settings_screen.dart` — Replace placeholder
- `lib/features/settings/presentation/log_viewer_screen.dart` — Log viewer widget

### Sync Hardening
- `lib/features/sync/application/sync_coordinator.dart` — Add transient error handling
- `lib/features/sync/application/outbox_processor.dart` — Verify retry logic edge cases
- `lib/features/sync/presentation/sync_status_badge.dart` — Add info bottom sheet on tap
- `lib/features/sync/presentation/conflict_resolution_screen.dart` — Arabize, add device labels

### Migration Safety
- `lib/core/database/app_database.dart` — Add pre-migration backup logic

### Performance
- `lib/core/database/tables/*.dart` — Verify/add indexes on date columns

### Audit Trail
- `lib/shared/widgets/audit_trail_sheet.dart` — Reusable audit history bottom sheet

### Cross-Platform Polish
- All screens — Verify RTL layout on Windows
- All PDF templates — Test with edge-case content (empty, large, long names)

### Router Updates
- `lib/core/router/app_router.dart` — Settings route update, conflict route

### Documentation
- `specs/009-hardening-release/known-limitations.md` — Release deliverable

## Verification

```bash
# Static analysis
dart analyze

# Run on Windows
flutter run -d windows

# Run on Android
flutter run -d <android-device-id>

# Manual QA follows test matrix in tasks.md
```

## Architecture Note

This phase makes **no architectural changes**. It improves resilience, fixes edge cases, and validates existing implementations. All modifications are within existing feature boundaries.
