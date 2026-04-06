# Tasks: Products & Clients

**Input**: Design documents from `/specs/004-products-clients/`  
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/endpoints.md  
**Branch**: `004-products-clients`  
**Date**: 2026-04-05

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Schema Migration & Code Generation

**Purpose**: Add missing columns to local Drift tables and Serverpod models, run code generation, and verify the build compiles.

> ⚠️ **Before implementing any task in this phase**: Read `specs/004-products-clients/data-model.md` and `specs/004-products-clients/research.md` (R-001, R-002) as the source of truth for field names, types, and nullability. Do not guess column types or names from memory.

- [x] T001 Add `costPrice`, `unit`, `sku` columns to Drift Products table in `motaz_app_flutter/lib/core/database/tables/products.dart`
  - **Objective**: Extend the existing Product schema with 3 new nullable columns.
  - **Scope**: Add `IntColumn get costPrice => integer().nullable()();` — minor-unit integer, nullable. Add `TextColumn get unit => text().nullable()();`. Add `TextColumn get sku => text().nullable()();`. Do NOT change existing columns. Do NOT add unique constraints on `sku`.
  - **Dependencies**: None.
  - **Verification**: File compiles with `dart analyze`. No existing columns modified. Three new columns present.

- [x] T002 [P] Add `email`, `address` columns to Drift Clients table in `motaz_app_flutter/lib/core/database/tables/clients.dart`
  - **Objective**: Extend the existing Client schema with 2 new nullable columns.
  - **Scope**: Add `TextColumn get email => text().nullable()();`. Add `TextColumn get address => text().nullable()();`. Position them after `phone` column. Do NOT change existing columns.
  - **Dependencies**: None.
  - **Verification**: File compiles with `dart analyze`. No existing columns modified. Two new columns present.

- [x] T003 [P] Add `costPrice`, `unit`, `sku` to Serverpod Product model in `motaz_app_server/lib/src/models/product.spy.yaml`
  - **Objective**: Add matching fields to the server-side model.
  - **Scope**: Add `costPrice: int?`, `unit: String?`, `sku: String?` under fields. Do NOT change existing fields.
  - **Dependencies**: None.
  - **Verification**: YAML is valid. Three new fields present.

- [x] T004 [P] Add `email`, `address` to Serverpod ClientRecord model in `motaz_app_server/lib/src/models/client_record.spy.yaml`
  - **Objective**: Add matching fields to the server-side model.
  - **Scope**: Add `email: String?`, `address: String?` under fields. Do NOT change existing fields.
  - **Dependencies**: None.
  - **Verification**: YAML is valid. Two new fields present.

- [x] T005 Run Drift code generation in `motaz_app_flutter/`
  - **Objective**: Regenerate the Drift `app_database.g.dart` to include the new columns.
  - **Scope**: Run `dart run build_runner build --delete-conflicting-outputs` from `motaz_app_flutter/`. Verify the generated file includes `costPrice`, `unit`, `sku` for Products and `email`, `address` for Clients.
  - **Dependencies**: T001, T002.
  - **Verification**: Build completes without errors. `app_database.g.dart` contains new fields in the generated data classes.

- [x] T006 Run Serverpod code generation and create migration in `motaz_app_server/`
  - **Objective**: Regenerate Serverpod protocol classes and create the database migration.
  - **Scope**: Run `serverpod generate` then `serverpod create-migration` from `motaz_app_server/`. Verify the migration adds the 5 new columns to PostgreSQL.
  - **Dependencies**: T003, T004.
  - **Verification**: Generation completes. Migration SQL file exists and contains ALTER TABLE statements for the new columns.

**Checkpoint**: Schema updated on both Drift and Serverpod. Build compiles. Code generation successful.

---

## Phase 2: FieldClassifier Update & Sync Allowlist Verification

**Purpose**: Update the FieldClassifier to include the new fields in the correct sync categories. Verify the server-side column allowlist already includes them.

> ⚠️ **Before implementing any task in this phase**: Read `specs/004-products-clients/data-model.md` (Sync Field Classification tables) and `specs/004-products-clients/research.md` (R-008) for the exact field classifications. Read `.specify/memory/constitution.md` Section II for the rule: "Financial conflicts must never be silently auto-merged."

- [x] T007 Add new product fields to FieldClassifier in `motaz_app_flutter/lib/features/sync/domain/field_classifier.dart`
  - **Objective**: Register `costPrice` as conflict-required and `unit`, `sku` as auto-merge for PRODUCT entity type.
  - **Scope**: In `autoMergeFields['PRODUCT']`, add `'unit'` and `'sku'`. In `conflictRequiredFields['PRODUCT']`, add `'costPrice'`. Do NOT remove any existing entries.
  - **Dependencies**: T005 (ensure code compiles first).
  - **Verification**: `FieldClassifier.getConflictRequiredFields('PRODUCT')` returns `{'name', 'defaultSalePrice', 'costPrice'}`. `autoMergeFields['PRODUCT']` contains `{'description', 'isActive', 'unit', 'sku'}`.

- [x] T008 [P] Add new client fields to FieldClassifier in `motaz_app_flutter/lib/features/sync/domain/field_classifier.dart`
  - **Objective**: Register `email` and `address` as auto-merge for CLIENT entity type.
  - **Scope**: In `autoMergeFields['CLIENT']`, add `'email'` and `'address'`. Do NOT modify `conflictRequiredFields` for CLIENT (it has none).
  - **Dependencies**: T005 (ensure code compiles first).
  - **Verification**: `autoMergeFields['CLIENT']` contains `{'displayName', 'phone', 'note', 'clientCode', 'email', 'address'}`.

> **NOTE**: T007 and T008 modify the same file (`field_classifier.dart`). If executing sequentially, combine into a single edit. If marked [P], the second task must be aware of T007's changes.

- [x] T009 Verify server-side column allowlist already includes new fields in `motaz_app_server/lib/src/services/sync_service.dart`
  - **Objective**: Confirm the `_columnAllowlist` map already includes `costPrice`, `unit`, `sku` for PRODUCT and `email`, `address` for CLIENT.
  - **Scope**: Read-only verification. Open `sync_service.dart`, find `_columnAllowlist`, and confirm the fields are present. If any are missing, add them. Based on current code (lines 366-374), they are already present — this task is a verification check.
  - **Dependencies**: T006.
  - **Verification**: `_columnAllowlist['PRODUCT']` contains `costPrice`, `unit`, `sku`. `_columnAllowlist['CLIENT']` contains `email`, `address`.

**Checkpoint**: Sync infrastructure updated for new fields. FieldClassifier knows which fields are auto-merge vs. conflict-required.

---

## Phase 3: US1 — Add a Product (Priority: P1) 🎯 MVP

**Goal**: Owner can create a new product with all fields, save it locally offline, and have it queued for sync.

**Independent Test**: Open the app in airplane mode, tap Products → Add Product, fill in name "عصير مانجو" and price 500.00 YER, save, verify it appears in the product list.

> ⚠️ **Before implementing any task in this phase**: Read `specs/004-products-clients/spec.md` (User Story 1, FR-001, FR-002, FR-009, FR-010, FR-011), `specs/004-products-clients/data-model.md` (Product entity), and `specs/004-products-clients/research.md` (R-003, R-004, R-006). Follow the approved constitution, Master Implementation Plan, and current spec boundaries. Do not guess architecture or business behavior from memory.

- [x] T010 [US1] Create `ProductRepository` in `motaz_app_flutter/lib/features/products/data/product_repository.dart`
  - **Objective**: Drift DAO wrapping all product CRUD operations.
  - **Files**: Create `motaz_app_flutter/lib/features/products/data/product_repository.dart`.
  - **Scope**:
    - Constructor takes `AppDatabase`.
    - `Future<void> create(ProductsCompanion product)` — inserts product AND creates a SyncOutbox entry in a single `_db.transaction()`. The outbox entry must use `ParentEntityType.PRODUCT`, `AuditOperation.CREATE`, JSON-encoded payload of all product fields, `rowVersion: 1`, and the device's ID. Generate product UUID with `Uuid().v4()`.
    - `Future<Product> getById(String id)` — returns single product.
    - `Future<bool> isNameTaken(String name, {String? excludeId})` — queries `SELECT COUNT(*) FROM products WHERE LOWER(name) = LOWER(:name)` optionally excluding a product ID. Returns true if count > 0.
    - All monetary values (`defaultSalePrice`, `costPrice`) are `int` (minor-unit integers). Do NOT use `double` anywhere.
  - **Dependencies**: T005 (code generation complete).
  - **Verification**: File compiles. `create` wraps both insert and outbox entry in a single transaction. `isNameTaken` uses case-insensitive comparison.

- [x] T011 [US1] Create `ProductProviders` in `motaz_app_flutter/lib/features/products/application/product_providers.dart`
  - **Objective**: Riverpod providers exposing product state to UI.
  - **Files**: Create `motaz_app_flutter/lib/features/products/application/product_providers.dart`.
  - **Scope**:
    - `productRepositoryProvider` — `Provider<ProductRepository>` that creates a repo from `appDatabaseProvider`.
    - `productListProvider` — `StreamProvider<List<Product>>` watching all products ordered by `createdAt DESC` using Drift `.watch()`.
    - `productSearchProvider(String query)` — `StreamProvider.family<List<Product>, String>` that filters products by name LIKE `%query%` using Drift `.watch()`.
    - Import from `core/database/app_database.dart`, `core/database/database_provider.dart`, and `product_repository.dart`.
    - Use `flutter_riverpod` — NOT `riverpod` directly.
  - **Dependencies**: T010.
  - **Verification**: File compiles. Providers are typed correctly. Search provider uses `.family`. Product list watches Drift stream.

- [x] T012 [US1] Create `ProductFormScreen` in `motaz_app_flutter/lib/features/products/presentation/product_form_screen.dart`
  - **Objective**: Add Product form with validation, offline save, and proper Arabic RTL support.
  - **Files**: Create `motaz_app_flutter/lib/features/products/presentation/product_form_screen.dart`.
  - **Scope**:
    - `ConsumerStatefulWidget` with a `Form` containing `TextFormField` widgets for: name (required, max 200 chars), description (optional), defaultSalePrice (required, non-negative integer input — user types YER value, app converts to minor-unit by multiplying by 100), costPrice (optional, non-negative), unit (optional), sku (optional).
    - On save: validate name is not empty, validate name length ≤ 200, validate defaultSalePrice ≥ 0, check `productRepository.isNameTaken(name)` — if taken, show Arabic error "اسم المنتج مستخدم بالفعل". If valid, call `productRepository.create(...)` with device ID from `DeviceService.ensureCurrentDevice()`, then pop the screen.
    - Price input: user enters decimal value (e.g., "500.00"), convert to int by `(double.parse(input) * 100).round()`. Display validation error for non-numeric input.
    - All labels and error messages in Arabic.
    - Scaffold with `AppBar` title "إضافة منتج".
  - **Dependencies**: T010, T011.
  - **Verification**: Form renders 6 fields. Save button validates all fields. Name uniqueness check runs before save. Price converts to minor-unit integer. All text is Arabic.

- [x] T013 [US1] Create initial `ProductListScreen` (add-only) in `motaz_app_flutter/lib/features/products/presentation/product_list_screen.dart`
  - **Objective**: Display product list with a FAB to add new products.
  - **Files**: Create `motaz_app_flutter/lib/features/products/presentation/product_list_screen.dart` (replacing the placeholder).
  - **Scope**:
    - `ConsumerWidget` wrapped in `AppDrawerScaffold` (import from `shared/widgets/app_drawer.dart`) with `currentRoute: '/products'`.
    - Watch `productListProvider` to get reactive product list.
    - Display each product as a `ListTile` showing: name, formatted price (`(defaultSalePrice / 100).toStringAsFixed(2) + ' ر.ي.'`), and unit if present.
    - `FloatingActionButton` navigates to `ProductFormScreen` (use `Navigator.push`, not `go_router`, for the form — it's a modal flow).
    - Empty state: show centered Arabic text "لا توجد منتجات" when list is empty.
    - Import `AppDrawerScaffold` from `shared/widgets/app_drawer.dart`.
  - **Dependencies**: T011, T012.
  - **Verification**: Screen shows product list from Drift stream. FAB opens form. After adding a product, it appears in the list without manual refresh. Empty state shows when no products exist.

- [x] T014 [US1] Update router to use `ProductListScreen` instead of placeholder in `motaz_app_flutter/lib/core/router/app_router.dart`
  - **Objective**: Replace the placeholder import and reference for the `/products` route.
  - **Files**: Modify `motaz_app_flutter/lib/core/router/app_router.dart`.
  - **Scope**: Replace `ProductsPlaceholderScreen` import and usage with `ProductListScreen` from `features/products/presentation/product_list_screen.dart`. Only change the `/products` route — do NOT touch any other routes.
  - **Dependencies**: T013.
  - **Verification**: Navigating to `/products` shows the real `ProductListScreen`, not the placeholder.

**Checkpoint**: Owner can add products offline. Products appear in the list. Name uniqueness is enforced. Price stored as minor-unit integer. Sync outbox entries created.

---

## Phase 4: US2 — Edit a Product (Priority: P1)

**Goal**: Owner can edit any product field, with name uniqueness re-validated on edit.

**Independent Test**: Create a product, tap it to edit, change the price, save, verify the updated price shows in the list.

> ⚠️ **Before implementing**: Read spec.md (User Story 2, FR-003) and research.md (R-004). Editing must re-validate name uniqueness excluding the current product.

- [x] T015 [US2] Add `update` method to `ProductRepository` in `motaz_app_flutter/lib/features/products/data/product_repository.dart`
  - **Objective**: Support editing a product with outbox entry creation.
  - **Scope**: Add `Future<void> update(String id, ProductsCompanion updates)` that: (1) increments `rowVersion` by 1, (2) sets `updatedAt` to now, (3) sets `syncStatus` to `SyncStatus.PENDING`, (4) writes the update, and (5) creates a SyncOutbox entry with `AuditOperation.UPDATE` and JSON payload of updated fields. All in a single `_db.transaction()`.
  - **Dependencies**: T010.
  - **Verification**: Method updates the product row and creates an outbox entry. `rowVersion` incremented. `syncStatus` set to PENDING.

- [x] T016 [US2] Add edit mode to `ProductFormScreen` in `motaz_app_flutter/lib/features/products/presentation/product_form_screen.dart`
  - **Objective**: Reuse the same form for editing. Pre-populate fields with existing values.
  - **Scope**: Add optional `Product? existingProduct` constructor parameter. If not null, pre-fill all form fields with existing values (convert minor-unit price back to decimal for display: `(existingProduct.defaultSalePrice / 100).toStringAsFixed(2)`). Change AppBar title to "تعديل منتج" when editing. On save: call `isNameTaken(name, excludeId: existingProduct.id)` for uniqueness check, then call `productRepository.update(...)` instead of `create(...)`. Do NOT change the create flow.
  - **Dependencies**: T015, T012.
  - **Verification**: Form pre-populates when editing. Name uniqueness check excludes current product. Save calls `update` not `create`. Price displays correctly from minor-unit.

- [x] T017 [US2] Add tap-to-edit to `ProductListScreen` in `motaz_app_flutter/lib/features/products/presentation/product_list_screen.dart`
  - **Objective**: Tapping a product in the list opens the edit form.
  - **Scope**: Add `onTap` to each product `ListTile` that navigates to `ProductFormScreen(existingProduct: product)`.
  - **Dependencies**: T016, T013.
  - **Verification**: Tapping a product opens the form pre-filled. Editing and saving updates the product in the list.

**Checkpoint**: Owner can edit products. Name uniqueness re-validated. Row version incremented. Outbox entry created for sync.

---

## Phase 5: US3 — Disable a Product (Priority: P2)

**Goal**: Owner can disable/re-enable a product. Disabled products show a visual indicator and don't appear in invoice autocomplete.

**Independent Test**: Create a product, disable it, verify it shows "disabled" indicator in the list.

> ⚠️ **Before implementing**: Read spec.md (User Story 3, FR-004, FR-005, FR-006, FR-007). Products are NEVER deleted per constitution (Section II).

- [x] T018 [US3] Add `toggleActive` method to `ProductRepository` in `motaz_app_flutter/lib/features/products/data/product_repository.dart`
  - **Objective**: Toggle `isActive` flag with sync outbox entry.
  - **Scope**: Add `Future<void> toggleActive(String id, bool isActive)` that updates the product's `isActive` field to the given value, increments `rowVersion`, sets `syncStatus` to PENDING, and creates an outbox entry. All in a single transaction.
  - **Dependencies**: T010.
  - **Verification**: Calling `toggleActive(id, false)` sets `isActive=false`. Outbox entry created.

- [x] T019 [US3] Add `activeProductSearchProvider` to `ProductProviders` in `motaz_app_flutter/lib/features/products/application/product_providers.dart`
  - **Objective**: Provide a search stream that returns ONLY active products — for use in invoice autocomplete (Phase 5 feature).
  - **Scope**: Add `activeProductSearchProvider(String query)` — `StreamProvider.family<List<Product>, String>` that filters products by name LIKE `%query%` AND `isActive = true`. This provider will be consumed by the invoice form in Phase 5. Do NOT modify the existing `productListProvider` (it shows ALL products including disabled).
  - **Dependencies**: T011.
  - **Verification**: Provider returns only active products. Disabled products are excluded.

- [x] T020 [US3] Add disable/enable UI to `ProductListScreen` in `motaz_app_flutter/lib/features/products/presentation/product_list_screen.dart`
  - **Objective**: Show disabled indicator and provide toggle action.
  - **Scope**: For each product `ListTile`: if `product.isActive == false`, add a `Text('معطّل', style: TextStyle(color: Colors.red))` subtitle or trailing badge, and reduce the tile opacity to 0.6. Add a trailing `PopupMenuButton` with option "تعطيل" (if active) or "تفعيل" (if disabled) that calls `productRepository.toggleActive(product.id, !product.isActive)`.
  - **Dependencies**: T018, T013.
  - **Verification**: Disabled products show red "معطّل" indicator. Tapping the menu toggles the active state. List updates reactively.

**Checkpoint**: Products can be disabled/re-enabled. Disabled products visually indicated. Active-only search provider ready for future invoice autocomplete.

---

## Phase 6: US4 — Search Products (Priority: P1)

**Goal**: Owner can search products by name with live filtering.

**Independent Test**: Create 3 products, type partial name in search box, verify list filters to show only matching products.

> ⚠️ **Before implementing**: Read spec.md (User Story 4, FR-008) and research.md (R-007). Search uses Drift LIKE query with debounce.

- [x] T021 [US4] Add search bar to `ProductListScreen` in `motaz_app_flutter/lib/features/products/presentation/product_list_screen.dart`
  - **Objective**: Add a `TextField` search bar that live-filters the product list.
  - **Scope**: Add a `TextField` with Arabic hint text "بحث عن منتج..." at the top of the screen (inside a `Padding` above the `ListView`). Use a local `_searchQuery` state variable. When `_searchQuery` is empty, watch `productListProvider` (all products). When `_searchQuery` is not empty, watch `productSearchProvider(_searchQuery)`. Add a 300ms debounce using a `Timer` before updating `_searchQuery`. Convert `ProductListScreen` from `ConsumerWidget` to `ConsumerStatefulWidget` to manage state.
  - **Dependencies**: T013, T011.
  - **Verification**: Typing in the search box filters the product list. Clearing the search box shows all products. Results update within 500ms for 2000 records.

**Checkpoint**: Product search works offline with live filtering. Arabic placeholder text.

---

## Phase 7: US5 — Add a Client (Priority: P1)

**Goal**: Owner can create a new client with display name and at least one identifying field, save locally offline.

**Independent Test**: Open the app offline, add a client with name "أحمد محمد" and phone "777123456", verify it appears in the client list.

> ⚠️ **Before implementing**: Read spec.md (User Story 5, FR-013, FR-014, FR-015, FR-019, FR-022), data-model.md (Client entity), and research.md (R-002, R-003, R-006). Clients do NOT require unique names but DO require at least one identifying field (phone, email, address, note, or client code). Follow the approved constitution Section IV.

- [x] T022 [US5] Create `ClientRepository` in `motaz_app_flutter/lib/features/clients/data/client_repository.dart`
  - **Objective**: Drift DAO wrapping all client CRUD operations.
  - **Files**: Create `motaz_app_flutter/lib/features/clients/data/client_repository.dart`.
  - **Scope**:
    - Constructor takes `AppDatabase`.
    - `Future<void> create(ClientsCompanion client)` — inserts client AND creates SyncOutbox entry in a single `_db.transaction()`. Use `ParentEntityType.CLIENT`, `AuditOperation.CREATE`, JSON-encoded payload.
    - `Future<Client> getById(String id)` — returns single client.
    - `Stream<List<Client>> watchAll()` — returns all clients ordered by `displayName ASC` via Drift `.watch()`.
    - Client names are NOT unique — no uniqueness check needed.
    - Generate client UUID with `Uuid().v4()`.
  - **Dependencies**: T005 (code generation complete).
  - **Verification**: File compiles. `create` wraps insert and outbox in a transaction. No uniqueness check on name. Stream returns reactive list.

- [x] T023 [US5] Create `ClientProviders` in `motaz_app_flutter/lib/features/clients/application/client_providers.dart`
  - **Objective**: Riverpod providers exposing client state to UI.
  - **Files**: Create `motaz_app_flutter/lib/features/clients/application/client_providers.dart`.
  - **Scope**:
    - `clientRepositoryProvider` — `Provider<ClientRepository>`.
    - `clientListProvider` — `StreamProvider<List<Client>>` watching all clients ordered by `displayName ASC`.
    - `clientSearchProvider(String query)` — `StreamProvider.family<List<Client>, String>` that filters by `displayName LIKE '%query%' OR phone LIKE '%query%' OR clientCode LIKE '%query%'` (multi-field OR search).
  - **Dependencies**: T022.
  - **Verification**: List provider watches Drift stream. Search provider filters across 3 fields.

- [x] T024 [US5] Create `ClientFormScreen` in `motaz_app_flutter/lib/features/clients/presentation/client_form_screen.dart`
  - **Objective**: Add Client form with identifying-field validation.
  - **Files**: Create `motaz_app_flutter/lib/features/clients/presentation/client_form_screen.dart`.
  - **Scope**:
    - `ConsumerStatefulWidget` with fields for: displayName (required, max 200 chars), phone (optional), email (optional), address (optional), note (optional), clientCode (optional).
    - On save: validate displayName is not empty. Validate at least ONE of (phone, email, address, note, clientCode) is non-empty — if all are empty, show Arabic error "يجب إدخال حقل تعريف واحد على الأقل (هاتف، بريد، عنوان، ملاحظة، أو رمز)". If valid, call `clientRepository.create(...)` with device ID, then pop.
    - AppBar title "إضافة عميل".
    - All labels and errors in Arabic.
  - **Dependencies**: T022, T023.
  - **Verification**: Form has 6 fields. Identifying-field validation works. Save creates client with outbox entry. All text is Arabic.

- [x] T025 [US5] Create initial `ClientListScreen` in `motaz_app_flutter/lib/features/clients/presentation/client_list_screen.dart`
  - **Objective**: Display client list with distinguishing fields for duplicate names.
  - **Files**: Create `motaz_app_flutter/lib/features/clients/presentation/client_list_screen.dart` (replacing the placeholder).
  - **Scope**:
    - `ConsumerWidget` wrapped in `AppDrawerScaffold` with `currentRoute: '/clients'`.
    - Watch `clientListProvider` for reactive list.
    - Display each client as a `ListTile`: title = `displayName`, subtitle = first non-empty value from [phone, clientCode, email] (to help distinguish duplicate names per FR-018).
    - `FloatingActionButton` navigates to `ClientFormScreen`.
    - Empty state: "لا يوجد عملاء".
  - **Dependencies**: T023, T024.
  - **Verification**: Client list shows distinguishing info. FAB opens form. New clients appear without manual refresh. Empty state works.

- [x] T026 [US5] Update router to use `ClientListScreen` instead of placeholder in `motaz_app_flutter/lib/core/router/app_router.dart`
  - **Objective**: Replace the placeholder import and reference for the `/clients` route.
  - **Files**: Modify `motaz_app_flutter/lib/core/router/app_router.dart`.
  - **Scope**: Replace `ClientsPlaceholderScreen` import and usage with `ClientListScreen` from `features/clients/presentation/client_list_screen.dart`. Only change the `/clients` route.
  - **Dependencies**: T025.
  - **Verification**: Navigating to `/clients` shows the real `ClientListScreen`.

**Checkpoint**: Owner can add clients offline. Identifying-field validation enforced. Duplicate names show distinguishing fields. Sync outbox entries created.

---

## Phase 8: US6 — Edit a Client (Priority: P1)

**Goal**: Owner can edit any client field with identifying-field re-validation.

**Independent Test**: Create a client, edit the phone number, save, verify the updated phone appears.

> ⚠️ **Before implementing**: Read spec.md (User Story 6, FR-016).

- [x] T027 [US6] Add `update` method to `ClientRepository` in `motaz_app_flutter/lib/features/clients/data/client_repository.dart`
  - **Objective**: Support editing a client with outbox entry creation.
  - **Scope**: Add `Future<void> update(String id, ClientsCompanion updates)` — same pattern as `ProductRepository.update`: increment `rowVersion`, set `updatedAt`, set `syncStatus` to PENDING, create outbox entry with `AuditOperation.UPDATE`. All in a single transaction.
  - **Dependencies**: T022.
  - **Verification**: Update modifies client row. Outbox entry created. Row version incremented.

- [x] T028 [US6] Add edit mode to `ClientFormScreen` in `motaz_app_flutter/lib/features/clients/presentation/client_form_screen.dart`
  - **Objective**: Reuse the form for editing. Pre-populate fields.
  - **Scope**: Add optional `Client? existingClient` parameter. If not null, pre-fill all fields. Change AppBar title to "تعديل عميل". On save: re-validate identifying-field rule, call `clientRepository.update(...)`. Do NOT change the create flow.
  - **Dependencies**: T027, T024.
  - **Verification**: Form pre-populates on edit. Identifying-field rule re-validated. Save calls update.

- [x] T029 [US6] Add tap-to-edit to `ClientListScreen` in `motaz_app_flutter/lib/features/clients/presentation/client_list_screen.dart`
  - **Objective**: Tapping a client in the list opens the edit form.
  - **Scope**: Add `onTap` to each client `ListTile` that navigates to `ClientFormScreen(existingClient: client)`.
  - **Dependencies**: T028, T025.
  - **Verification**: Tapping a client opens the form pre-filled. Editing and saving updates the client.

**Checkpoint**: Clients can be edited. Identifying-field rule re-validated. Outbox entries created.

---

## Phase 9: US7 — Search Clients (Priority: P1)

**Goal**: Owner can search clients by name, phone, or client code with live filtering and distinguishing fields visible.

**Independent Test**: Create 3 clients named "أحمد" with different phones, search "أحمد", verify all 3 appear with phone numbers visible.

> ⚠️ **Before implementing**: Read spec.md (User Story 7, FR-017, FR-018) and research.md (R-007).

- [x] T030 [US7] Add search bar to `ClientListScreen` in `motaz_app_flutter/lib/features/clients/presentation/client_list_screen.dart`
  - **Objective**: Add live search filtering across name, phone, and client code.
  - **Scope**: Same pattern as T021 (product search): Add a `TextField` with hint "بحث عن عميل...", local `_searchQuery` state, 300ms debounce timer. When query is empty, watch `clientListProvider`. When query is not empty, watch `clientSearchProvider(_searchQuery)`. Convert from `ConsumerWidget` to `ConsumerStatefulWidget` to manage state.
  - **Dependencies**: T025, T023.
  - **Verification**: Search filters by name, phone, or client code. Distinguishing fields visible for same-name clients. Results update reactively.

**Checkpoint**: Client search works offline across multiple fields. Duplicate-name clients distinguishable.

---

## Phase 10: US8 — Client Summary (Priority: P2)

**Goal**: Owner can view a client's details, outstanding balance, and recent transaction history.

**Independent Test**: Create a client, open the summary, verify balance shows 0 (no invoices exist yet).

> ⚠️ **Before implementing**: Read spec.md (User Story 8, FR-020, FR-021) and research.md (R-005). Outstanding balance is computed on-read — NOT stored. If no invoices/receipts exist (Phase 5 not yet implemented), balance is 0. Follow the constitution Section 9 compute-on-read principle.

- [x] T031 [US8] Add balance query to `ClientRepository` in `motaz_app_flutter/lib/features/clients/data/client_repository.dart`
  - **Objective**: Compute outstanding balance from invoices and receipts tables.
  - **Scope**: Add `Future<int> getOutstandingBalance(String clientId)` that queries: `SELECT COALESCE(SUM(total), 0) FROM sales_invoices WHERE clientId = :clientId AND status != 'VOIDED'` minus `SELECT COALESCE(SUM(amount), 0) FROM receipts WHERE clientId = :clientId AND status != 'VOIDED'`. Return as `int` (minor-unit). If the invoices/receipts tables exist but have no rows for this client, return 0. If the tables don't have the expected structure yet (Phase 5), use a try-catch and return 0.
  - **Dependencies**: T022.
  - **Verification**: Returns 0 when no invoices exist. Returns correct balance when invoices/receipts exist. Result is minor-unit integer.

- [x] T032 [US8] Add transaction history query to `ClientRepository` in `motaz_app_flutter/lib/features/clients/data/client_repository.dart`
  - **Objective**: Fetch recent transactions for a client.
  - **Scope**: Add `Future<List<Map<String, dynamic>>> getRecentTransactions(String clientId, {int limit = 20})` that queries the most recent invoices, receipts, and returns linked to this client, ordered by date descending, limited to `limit` results. Return each as a Map with keys: `type` (INVOICE/RECEIPT/RETURN), `date`, `amount`, `status`. If tables don't have data yet, return empty list. Use try-catch defensively since invoice/receipt tables may not have the expected columns until Phase 5.
  - **Dependencies**: T022.
  - **Verification**: Returns empty list when no transactions exist. Returns correct results when data exists.

- [x] T033 [US8] Create `ClientSummaryScreen` in `motaz_app_flutter/lib/features/clients/presentation/client_summary_screen.dart`
  - **Objective**: Show client details, balance, and transaction history.
  - **Files**: Create `motaz_app_flutter/lib/features/clients/presentation/client_summary_screen.dart`.
  - **Scope**:
    - `ConsumerStatefulWidget` that takes a `Client` as parameter.
    - Top section: display client details (name, phone, email, address, note, clientCode) in a `Card`.
    - Middle section: display outstanding balance in a prominent `Card` with formatted value `(balance / 100).toStringAsFixed(2) + ' ر.ي.'`. Show "لا توجد مستحقات" if balance is 0.
    - Bottom section: display recent transactions in a `ListView` showing type, date, and amount. Show "لا توجد معاملات" if empty.
    - Add an edit button (icon in AppBar) that navigates to `ClientFormScreen(existingClient: client)`.
    - AppBar title: client's displayName.
    - All text in Arabic.
  - **Dependencies**: T031, T032, T028.
  - **Verification**: Screen shows client details. Balance shows 0 when no invoices. Edit button works. Arabic text throughout.

- [x] T034 [US8] Wire client summary navigation from `ClientListScreen` in `motaz_app_flutter/lib/features/clients/presentation/client_list_screen.dart`
  - **Objective**: Tapping a client goes to the summary screen (not directly to edit form).
  - **Scope**: Change the `onTap` handler (from T029) to navigate to `ClientSummaryScreen(client: client)` instead of directly to `ClientFormScreen`. The edit flow is now accessible from the summary screen's AppBar edit button.
  - **Dependencies**: T033, T029.
  - **Verification**: Tapping a client opens the summary. Edit is available from the summary's AppBar.

**Checkpoint**: Client summary shows details, computed balance, and transaction history. Balance is 0 when no invoices exist. Edit accessible from summary.

---

## Phase 11: Polish & Cross-Cutting Concerns

**Purpose**: Final quality improvements, consistency checks, and validation.

- [ ] T035 Verify all product and client screens render correctly in Arabic RTL layout
  - **Objective**: Test all 5 screens (ProductListScreen, ProductFormScreen, ClientListScreen, ClientFormScreen, ClientSummaryScreen) render correctly in RTL.
  - **Scope**: Run the app, navigate to each screen, verify text alignment is right-to-left, form fields are right-aligned, and icons/buttons are correctly positioned. Fix any RTL issues found.
  - **Dependencies**: T034.
  - **Verification**: All screens render correctly in RTL. No left-aligned text that should be right-aligned.

- [ ] T036 [P] Verify offline create/edit/disable cycle for products and clients
  - **Objective**: End-to-end offline test. Turn off connectivity, create a product, edit it, disable it, create a client, edit it. Verify all changes are saved locally and all SyncOutbox entries are created.
  - **Scope**: Manual verification. Check the SyncOutbox table has entries for each mutation. Verify no errors in the console.
  - **Dependencies**: T034.
  - **Verification**: All CRUD operations work offline. SyncOutbox entries exist for every mutation.

- [ ] T037 [P] Verify sync cycle picks up product and client outbox entries
  - **Objective**: Ensure the existing sync coordinator processes product and client mutations correctly.
  - **Scope**: Create products/clients offline, restore connectivity, verify the sync coordinator pushes the outbox entries to the server. Check server-side database has the records.
  - **Dependencies**: T036.
  - **Verification**: Products and clients appear on the server after sync. Outbox entries cleared after successful push.

- [x] T038 Remove placeholder screen files
  - **Objective**: Clean up unused placeholder files.
  - **Files**: Delete `motaz_app/flutter/lib/features/products/presentation/placeholder_screen.dart` and `motaz_app/flutter/lib/features/clients/presentation/placeholder_screen.dart`.
  - **Scope**: Remove the files. Verify no imports reference them. Run `flutter analyze` to confirm no errors.
  - **Dependencies**: T014, T026.
  - **Verification**: Placeholder files deleted. Flutter analyze passes with no errors. All 30 tests pass.

**Checkpoint**: All screens RTL-correct. Offline lifecycle verified. Sync verified. Placeholders removed.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Schema)**: No dependencies — start immediately.
- **Phase 2 (FieldClassifier)**: Depends on Phase 1 (T005 code generation).
- **Phases 3-6 (US1-US4, Products)**: Depend on Phase 2 completion.
- **Phases 7-9 (US5-US7, Clients)**: Depend on Phase 2 completion. Can run in parallel with Product phases.
- **Phase 10 (US8, Client Summary)**: Depends on Phase 8 (client edit exists).
- **Phase 11 (Polish)**: Depends on all previous phases.

### User Story Dependencies

- **US1 (Add Product)**: After Phase 2 — no dependencies on other stories.
- **US2 (Edit Product)**: After US1 (needs repository and list screen).
- **US3 (Disable Product)**: After US1 (needs repository).
- **US4 (Search Products)**: After US1 (needs list screen and providers).
- **US5 (Add Client)**: After Phase 2 — no dependencies on product stories.
- **US6 (Edit Client)**: After US5.
- **US7 (Search Clients)**: After US5.
- **US8 (Client Summary)**: After US6 (uses edit form).

### Within Each User Story

- Repository before providers.
- Providers before screens.
- Screens before router updates.

### Parallel Opportunities

- T001, T002, T003, T004 are all independent (different files).
- T007, T008 modify the same file — execute sequentially or as one edit.
- Product stories (US1-US4) and Client stories (US5-US7) are fully independent — can be built in parallel.
- T035, T036, T037 are independent verification tasks.

---

## Implementation Strategy

### MVP First (US1 + US5 Only)

1. Complete Phase 1: Schema migration (T001-T006)
2. Complete Phase 2: FieldClassifier (T007-T009)
3. Complete Phase 3: US1 — Add Product (T010-T014)
4. Complete Phase 7: US5 — Add Client (T022-T026)
5. **STOP and VALIDATE**: Both Add flows work offline.

### Full Delivery

1. Schema + FieldClassifier → Foundation ready
2. US1 (Add Product) → US2 (Edit) → US3 (Disable) → US4 (Search) → Products complete
3. US5 (Add Client) → US6 (Edit) → US7 (Search) → US8 (Summary) → Clients complete
4. Polish → Verified and clean

---

## Notes

- [P] tasks = different files, no dependencies.
- All monetary values must be stored as minor-unit integers. Do NOT use `double` in the money path.
- Product names are unique (case-insensitive). Client names are NOT unique.
- Disabled products must not appear in invoice autocomplete (Phase 5 will use `activeProductSearchProvider`).
- Client outstanding balance is computed on-read, never cached.
- All text labels and error messages must be in Arabic.
- All screens must use RTL layout.
- Every mutation (create, update, toggleActive) must create a SyncOutbox entry in the same Drift transaction.
- Commit after each task or logical group.
