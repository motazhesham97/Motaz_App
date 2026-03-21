# Research: Workspace Foundation

**Branch**: `001-workspace-foundation`
**Date**: 2026-03-19

## Summary

All technology decisions for this phase are frozen in the constitution v1.3.0 and the master implementation plan v2. No NEEDS CLARIFICATION items remain in the technical context. This document consolidates the research findings for reference.

---

## Decision 1: Backend Framework

**Decision**: Serverpod (Dart)
**Rationale**: Single language across client and server (Dart). Built-in ORM, code generation for protocol classes, and auth module. Reduces glue code.
**Alternatives considered**:
- Custom Dart server (shelf) — too much manual work for sync, auth, ORM
- Node.js / Express — different language, no code sharing with Flutter
- Python / Django — explicitly excluded in constitution

---

## Decision 2: Local Database Library

**Decision**: Drift (formerly Moor)
**Rationale**: Type-safe, code-generated SQLite access with migration support. Ideal for offline-first relational data with complex queries (accounting domain).
**Alternatives considered**:
- sqflite — manual SQL strings, no type safety, no generated migrations
- Isar — NoSQL, poor fit for relational accounting data
- ObjectBox — NoSQL, same concern

---

## Decision 3: State Management

**Decision**: flutter_riverpod with riverpod_generator
**Rationale**: Clean separation of concerns, works well with async data flows and repository patterns, fits feature-first architecture. Code generation reduces boilerplate.
**Alternatives considered**:
- Bloc/Cubit — more boilerplate, event/state ceremony overhead for simple cases
- Provider — less powerful, no code generation, harder dependency management

---

## Decision 4: Authentication

**Decision**: Serverpod email+password authentication module
**Rationale**: Built into Serverpod, covers single-owner MVP needs. Registration and sign-in screens in the app. Sessions never expire (clarification Q3).
**Alternatives considered**:
- Custom auth — unnecessary complexity when Serverpod provides it
- Firebase Auth — additional dependency, not needed for single-owner
- API key only — doesn't support email+password sign-in UX

---

## Decision 5: Routing

**Decision**: go_router
**Rationale**: Declarative routing, supports deep linking, platform-adaptive, well-maintained. Works with Riverpod for auth-based redirects.
**Alternatives considered**:
- auto_route — more complex setup, code generation overhead for this scale
- Navigator 2.0 raw — too verbose

---

## Decision 6: Connectivity Monitoring

**Decision**: connectivity_plus package
**Rationale**: Cross-platform (Android + Windows), detects network state changes, well-maintained. Will be debounced to handle intermittent connectivity edge case.
**Alternatives considered**:
- Manual platform channels — unnecessary complexity
- internet_connection_checker — adds HTTP ping overhead, connectivity_plus sufficient for detection

---

## Decision 7: Device Identity

**Decision**: UUID v4 generated on first launch, stored in local Drift database
**Rationale**: Simple, globally unique, no external dependency. Persists in local DB. New identity on reinstall (per spec assumption).
**Alternatives considered**:
- Platform device ID (android_id, etc.) — privacy concerns, inconsistent across platforms
- UUID stored in shared_preferences — less durable than DB, but DB is the source of truth

---

## Decision 8: Localization

**Decision**: Flutter's built-in intl/flutter_localizations with ARB files, Arabic-first
**Rationale**: Standard Flutter approach. Arabic is the only locale in MVP. ARB files support future expansion.
**Alternatives considered**:
- easy_localization — adds dependency for no benefit when only one locale
- slang — type-safe but overkill for MVP

---

## Decision 9: Navigation Pattern

**Decision**: Sidebar (drawer) navigation, collapses to hamburger on mobile (clarification Q2)
**Rationale**: Supports 9+ sections naturally, works well with Arabic RTL, clean on both phone and desktop.
**Alternatives considered**:
- Bottom navigation — limited to 5 tabs, doesn't scale to 9 sections
- Nested navigation — more complex UX for the owner
