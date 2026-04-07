# Tasks: Invoices & Receipts

**Input**: Design documents from `/specs/005-invoices-receipts/`  
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/endpoints.md ✅, quickstart.md ✅

**Tests**: Not explicitly requested — test tasks omitted.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

**⚠️ CRITICAL INSTRUCTION FOR IMPLEMENTATION MODEL**: Before implementing ANY task, read the following repository documents as the source of truth. Do NOT guess architecture, business rules, or framework behavior from memory:
- `.specify/memory/constitution.md` — non-negotiable rules
- `specs/005-invoices-receipts/spec.md` — functional requirements FR-001 to FR-030
- `specs/005-invoices-receipts/plan.md` — technical context, structure, constitution check
- `specs/005-invoices-receipts/research.md` — 9 technical decisions
- `specs/005-invoices-receipts/data-model.md` — entity fields, constraints, state transitions
- `specs/005-invoices-receipts/contracts/endpoints.md` — repository method signatures
- `docs/implementation-plan.md` — master implementation plan (Phase 5 section)

**Stack rules enforced**:
- Flutter frontend, flutter_riverpod for state, Drift for local SQLite
- Money as minor-unit integers only — no `double` anywhere in the money path
- All mutations: entity + outbox in single `_db.transaction()`
- Financial conflicts never silently auto-merged (FieldClassifier already configured)
- Void wins over edit (already configured in FieldClassifier)
- Arabic RTL for all UI text

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1–US9)
- Exact file paths included in every task

---

## Phase 1: Foundational — FIFO Allocator & Invoice Repository Core

**Purpose**: Build the shared data layer that ALL user stories depend on. Must be complete before any UI work begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

### T001 — Create FIFO receipt allocator helper

- [x] T001 Create FIFO allocation engine in `motaz_app_flutter/lib/features/receipts/data/receipt_allocator.dart`

**Objective**: Build a reusable pure-function helper that computes FIFO allocations for a given client and receipt amount. This is consumed by both ReceiptRepository (for general receipts) and InvoiceRepository (for reallocation on invoice void).

**Before implementing**: Read `specs/005-invoices-receipts/research.md` §3 (FIFO Allocation Engine) and `specs/005-invoices-receipts/data-model.md` §ReceiptAllocation for the exact field list.

**Files to create**:
- `motaz_app_flutter/lib/features/receipts/data/receipt_allocator.dart`

**Exact scope**:
1. Create a class `ReceiptAllocator` with a constructor that takes `AppDatabase _db`.
2. Implement method `Future<List<ReceiptAllocationCompanion>> allocateFifo(String clientId, int amount, {String? excludeInvoiceId})`:
   - Query all ACTIVE invoices for the client: `SELECT * FROM sales_invoices WHERE clientId = ? AND status = 0` ordered by `invoiceDate ASC, createdAt ASC`.
   - If `excludeInvoiceId` is provided, exclude that invoice from the query (used during invoice void reallocation).
   - For each invoice, compute its remaining balance: `invoice.total - SUM(allocations WHERE receipt.status = ACTIVE)`.
   - Use a custom SQL query: `SELECT COALESCE(SUM(ra.allocated_amount), 0) AS paid FROM receipt_allocations ra INNER JOIN receipts r ON ra.receipt_id = r.id WHERE ra.invoice_id = ? AND r.status = 0`.
   - Iterate through invoices oldest-first, allocating from `amount` until exhausted.
   - For each allocation, produce a `ReceiptAllocationCompanion` with: `id` (UUID v4), `receiptId` (will be filled by caller), `invoiceId`, `allocatedAmount`, `createdAt`, `updatedAt`.
   - Return the list. If `amount` exceeds all outstanding balances, the remaining amount is simply unallocated (client credit — per clarification in spec §Clarifications).
3. All amounts are `int` (minor-unit integers). No `double` anywhere.
4. Import `uuid` for ID generation.

**Dependencies**: None — this is the first task.

**Acceptance criteria**:
- File compiles with `dart analyze` (no errors).
- Method signature matches: `Future<List<ReceiptAllocationCompanion>> allocateFifo(String clientId, int amount, {String? excludeInvoiceId})`.
- The `receiptId` field in each returned `ReceiptAllocationCompanion` uses `Value.absent()` — the caller sets it.
- No `double` in any arithmetic.

---

### T002 — Create InvoiceRepository: create method with local ref and atomic payment

- [x] T002 Create the InvoiceRepository with `create` method in `motaz_app_flutter/lib/features/invoices/data/invoice_repository.dart`

**Objective**: Build the invoice creation flow including local reference generation (`INV-<deviceCode>-<seq>`), atomic save of invoice + lines + optional receipt + optional allocation + outbox entries.

**Before implementing**: Read `specs/005-invoices-receipts/research.md` §1 (Local Reference Generation), §2 (Atomic Invoice + Receipt Creation), §8 (Outbox Pattern). Read `specs/005-invoices-receipts/data-model.md` for all entity fields. Read `motaz_app_flutter/lib/features/products/data/product_repository.dart` for the established transaction + outbox pattern.

**Files to create**:
- `motaz_app_flutter/lib/features/invoices/data/invoice_repository.dart`

**Exact scope**:
1. Create class `InvoiceRepository` with constructor `InvoiceRepository(this._db)` taking `AppDatabase`.
2. Add `final _uuid = const Uuid()`.
3. Implement `Future<SalesInvoice> create({required String clientId, required DateTime invoiceDate, required int discount, required String note, required List<SalesInvoiceLinesCompanion> lines, required int paidAmount, required String deviceId})`:
   - Validate: `lines.isNotEmpty` (throw if empty).
   - Validate: `paidAmount >= 0`.
   - Compute `subtotal = Σ(line.quantity × line.unitPrice)` for each line.
   - Compute each `line.lineTotal = line.quantity × line.unitPrice`.
   - Validate: `discount <= subtotal` (throw if exceeds).
   - Compute `total = subtotal - discount`.
   - Validate: `paidAmount <= total` (throw if exceeds).
   - Generate local ref:
     - Read device: `SELECT * FROM devices WHERE id = ?` using `deviceId`.
     - Read current `nextInvoiceSequence` from the device row.
     - Format: `'INV-${device.deviceCode}-${sequence.toString().padLeft(3, '0')}'`.
   - Generate invoice UUID.
   - Inside a single `_db.transaction(() async { ... })`:
     a. Insert the `SalesInvoice` row with all fields (id, localRef, officialNo=null, clientId, invoiceDate, discount, total, note, status=ACTIVE, voidReason=null, timestamps, deviceId, rowVersion=1, syncStatus=PENDING).
     b. Insert each `SalesInvoiceLine` row (id=UUID, invoiceId, productId, quantity, unitPrice, lineTotal, timestamps).
     c. Increment `nextInvoiceSequence` on the device: `UPDATE devices SET next_invoice_sequence = next_invoice_sequence + 1 WHERE id = ?`.
     d. Create outbox entry for SALES_INVOICE (operation=CREATE).
     e. Create outbox entry for each SALES_INVOICE_LINE (operation=CREATE).
     f. If `paidAmount > 0`:
        - Generate receipt UUID.
        - Insert `Receipt` row (type=INVOICE_LINKED, clientId, invoiceId, amount=paidAmount, receiptDate=invoiceDate, note=null, status=ACTIVE, timestamps, deviceId, rowVersion=1, syncStatus=PENDING).
        - Insert `ReceiptAllocation` row (id=UUID, receiptId, invoiceId, allocatedAmount=paidAmount, timestamps).
        - Create outbox entry for RECEIPT (operation=CREATE).
        - Create outbox entry for RECEIPT_ALLOCATION (operation=CREATE).
     g. Return the inserted `SalesInvoice` row.
4. Build JSON payloads for each outbox entry following the established pattern in `ProductRepository`.
5. All monetary fields are `int`. No `double`.

**Dependencies**: T001 (ReceiptAllocator exists but not needed for this method — only for void).

**Acceptance criteria**:
- File compiles with `dart analyze`.
- `create()` method inserts invoice + N lines + optional receipt + optional allocation + all outbox entries in one transaction.
- `localRef` format matches `INV-XXXX-001` pattern.
- Device `nextInvoiceSequence` is incremented atomically.
- `paidAmount = 0` creates no receipt.
- All amounts are `int`.

---

### T003 — Add query methods to InvoiceRepository

- [x] T003 Add query and helper methods to `motaz_app_flutter/lib/features/invoices/data/invoice_repository.dart`

**Objective**: Add all read-only query methods needed by UI screens and other repositories.

**Before implementing**: Read `specs/005-invoices-receipts/contracts/endpoints.md` §InvoiceRepository for exact method signatures. Read `specs/005-invoices-receipts/data-model.md` §Computed Values.

**Files to update**:
- `motaz_app_flutter/lib/features/invoices/data/invoice_repository.dart`

**Exact scope — add these methods**:
1. `Future<SalesInvoice> getById(String id)` — select single invoice by ID.
2. `Stream<List<SalesInvoice>> watchAll()` — watch all invoices ordered by `invoiceDate DESC, createdAt DESC`.
3. `Future<List<SalesInvoiceLine>> getLinesForInvoice(String invoiceId)` — select lines for an invoice.
4. `Future<List<Receipt>> getReceiptsForInvoice(String invoiceId)` — select ACTIVE receipts where `invoiceId = ?`.
5. `Future<int> getCollectedAmount(String invoiceId)` — `SELECT COALESCE(SUM(ra.allocated_amount), 0) FROM receipt_allocations ra INNER JOIN receipts r ON ra.receipt_id = r.id WHERE ra.invoice_id = ? AND r.status = 0`. Returns `int`.
6. `Future<int> getRemainingBalance(String invoiceId)` — `invoice.total - getCollectedAmount(invoiceId)`. Returns `int`.
7. `Future<bool> hasActiveReceipts(String invoiceId)` — `SELECT COUNT(*) FROM receipts WHERE invoiceId = ? AND status = 0`. Returns `count > 0`.
8. `Future<bool> hasActiveReturns(String invoiceId)` — `SELECT COUNT(*) FROM sales_returns WHERE invoiceId = ? AND status = 0`. Returns `count > 0`.

**Dependencies**: T002 (file exists).

**Acceptance criteria**:
- All 8 methods added and compile.
- `getCollectedAmount` uses a JOIN query to only count ACTIVE receipt allocations.
- `getRemainingBalance` calls `getCollectedAmount` internally — no duplicated SQL.
- All return types are correct per contracts/endpoints.md.

---

### T004 — Add update method to InvoiceRepository

- [x] T004 Add `update` method to `motaz_app_flutter/lib/features/invoices/data/invoice_repository.dart`

**Objective**: Implement invoice editing with the three-state constraint system.

**Before implementing**: Read `specs/005-invoices-receipts/spec.md` FR-008 and FR-009 for the exact editing rules. Read `specs/005-invoices-receipts/research.md` §5 (Invoice Edit State Detection).

**Files to update**:
- `motaz_app_flutter/lib/features/invoices/data/invoice_repository.dart`

**Exact scope**:
1. Implement `Future<void> update({required String id, required String clientId, required DateTime invoiceDate, required int discount, required String? note, required List<SalesInvoiceLinesCompanion> lines, required String deviceId})`:
   - Fetch existing invoice via `getById(id)`.
   - Check `existing.status != RecordStatus.VOIDED` — throw if voided (FR-009).
   - Check `hasActiveReturns(id)`:
     - If true: throw error — only note is editable when returns exist (FR-008, returns-constrained). A separate `updateNote` method should be used by the UI.
   - Validate: `lines.isNotEmpty`.
   - Compute new `subtotal`, validate `discount <= subtotal`.
   - Compute new `total = subtotal - discount`.
   - Check `hasActiveReceipts(id)`:
     - If true: `collectedAmount = getCollectedAmount(id)`. Validate `total >= collectedAmount` (FR-008, receipt-constrained).
   - Inside `_db.transaction(() async { ... })`:
     a. Delete existing lines: `DELETE FROM sales_invoice_lines WHERE invoiceId = ?`.
     b. Insert new lines with new UUIDs.
     c. Update the invoice row (clientId, invoiceDate, discount, total, note, updatedAt, rowVersion+1, syncStatus=PENDING).
     d. Create outbox entry for SALES_INVOICE (operation=UPDATE).
     e. Create outbox entry for each new SALES_INVOICE_LINE (operation=CREATE — replacing old lines).
2. Implement `Future<void> updateNote(String id, String? note, String deviceId)`:
   - Fetch existing, check not voided.
   - Update only `note`, `updatedAt`, `rowVersion+1`, `syncStatus=PENDING`.
   - Create outbox entry for SALES_INVOICE (operation=UPDATE).

**Dependencies**: T003 (query methods exist).

**Acceptance criteria**:
- Voided invoices cannot be updated (throws).
- Return-constrained invoices can only use `updateNote`.
- Receipt-constrained invoices enforce `total >= collectedAmount`.
- Lines are deleted and re-inserted (clean replace).
- All in single transaction with outbox entries.

---

### T005 — Add voidInvoice method to InvoiceRepository

- [x] T005 Add `voidInvoice` method to `motaz_app_flutter/lib/features/invoices/data/invoice_repository.dart`

**Objective**: Implement invoice voiding with receipt allocation reallocation.

**Before implementing**: Read `specs/005-invoices-receipts/spec.md` FR-010, US4 scenarios. Read `specs/005-invoices-receipts/research.md` §6 (Invoice Void with Receipt Reallocation). Read `specs/005-invoices-receipts/spec.md` §Clarifications (freed amounts become client credit if no other invoices).

**Files to update**:
- `motaz_app_flutter/lib/features/invoices/data/invoice_repository.dart`

**Exact scope**:
1. Implement `Future<void> voidInvoice(String id, String reason, String deviceId)`:
   - Validate `reason.trim().isNotEmpty` — throw if empty.
   - Fetch existing invoice via `getById(id)`.
   - Validate `existing.status == RecordStatus.ACTIVE` — throw if already voided.
   - Inside `_db.transaction(() async { ... })`:
     a. Get all ACTIVE receipt allocations for this invoice: `SELECT ra.* FROM receipt_allocations ra INNER JOIN receipts r ON ra.receipt_id = r.id WHERE ra.invoice_id = ? AND r.status = 0`.
     b. Collect the distinct `receiptId` values from those allocations.
     c. Delete all allocations for this invoice: `DELETE FROM receipt_allocations WHERE invoiceId = ?` (use Drift delete statement).
     d. Update the invoice: `status = VOIDED, voidReason = reason, updatedAt, rowVersion+1, syncStatus=PENDING`.
     e. Create outbox entry for SALES_INVOICE (operation=UPDATE) with full payload including status=VOIDED.
     f. For each affected receipt (from step b):
        - Use `ReceiptAllocator.allocateFifo(clientId, receipt.amount, excludeInvoiceId: id)` to compute new allocations.
        - Set `receiptId` on each returned allocation companion.
        - Insert each new allocation row.
        - Create outbox entry for each new RECEIPT_ALLOCATION (operation=CREATE).
2. Import `ReceiptAllocator` from `../../receipts/data/receipt_allocator.dart`.

**Dependencies**: T001 (ReceiptAllocator), T004 (file has all prior methods).

**Acceptance criteria**:
- Empty reason throws.
- Already-voided invoice throws.
- Allocations for the voided invoice are deleted.
- Affected receipts are re-allocated via FIFO to other invoices (excluding the voided one).
- If no other unpaid invoices exist, receipts remain ACTIVE with no allocations (client credit).
- All in single transaction with outbox entries.

---

## Phase 2: Receipt Repository

**Purpose**: Build the receipt data layer that depends on the allocator and invoice repository.

### T006 — Create ReceiptRepository with createInvoiceLinked method

- [x] T006 Create ReceiptRepository in `motaz_app_flutter/lib/features/receipts/data/receipt_repository.dart`

**Objective**: Build receipt creation for invoice-linked receipts.

**Before implementing**: Read `specs/005-invoices-receipts/spec.md` FR-013, FR-014, FR-020. Read `specs/005-invoices-receipts/contracts/endpoints.md` §ReceiptRepository. Follow the transaction + outbox pattern from `ProductRepository`.

**Files to create**:
- `motaz_app_flutter/lib/features/receipts/data/receipt_repository.dart`

**Exact scope**:
1. Create class `ReceiptRepository` with `ReceiptRepository(this._db)`.
2. Add `final _uuid = const Uuid()`.
3. Implement `Future<Receipt> createInvoiceLinked({required String clientId, required String invoiceId, required int amount, required DateTime receiptDate, String? note, required String deviceId})`:
   - Validate `amount > 0` — throw if not positive.
   - Fetch invoice by ID, validate `invoice.status == RecordStatus.ACTIVE` — throw if voided (FR-020).
   - Validate `invoice.clientId == clientId` — throw if client mismatch.
   - Get remaining balance via InvoiceRepository query: `SELECT invoice.total - COALESCE(SUM(ra.allocated_amount), 0) FROM ...`.
   - Validate `amount <= remainingBalance` — throw if exceeds (FR-014).
   - Generate receipt UUID.
   - Inside `_db.transaction(() async { ... })`:
     a. Insert `Receipt` row (type=INVOICE_LINKED, clientId, invoiceId, amount, receiptDate, note, status=ACTIVE, timestamps, deviceId, rowVersion=1, syncStatus=PENDING).
     b. Insert `ReceiptAllocation` row (id=UUID, receiptId, invoiceId, allocatedAmount=amount, timestamps).
     c. Create outbox entry for RECEIPT (operation=CREATE).
     d. Create outbox entry for RECEIPT_ALLOCATION (operation=CREATE).
   - Return the inserted Receipt.
4. Add query methods:
   - `Future<Receipt> getById(String id)`.
   - `Stream<List<Receipt>> watchAll()` — ordered by `receiptDate DESC, createdAt DESC`.
   - `Future<List<ReceiptAllocation>> getAllocationsForReceipt(String receiptId)`.

**Dependencies**: T003 (InvoiceRepository query methods for remaining balance computation).

**Acceptance criteria**:
- Amount > 0 enforced.
- Voided invoice rejected.
- Amount ≤ remaining balance enforced.
- Receipt + allocation + outbox entries in single transaction.
- All amounts are `int`.

---

### T007 — Add createGeneral method to ReceiptRepository

- [x] T006 Create ReceiptRepository in `motaz_app_flutter/lib/features/receipts/data/receipt_repository.dart`

**Objective**: Build general client receipt creation with FIFO auto-allocation.

**Before implementing**: Read `specs/005-invoices-receipts/spec.md` FR-015, FR-016, US6 scenarios. Read `specs/005-invoices-receipts/research.md` §3 (FIFO Allocation Engine).

**Files to update**:
- `motaz_app_flutter/lib/features/receipts/data/receipt_repository.dart`

**Exact scope**:
1. Implement `Future<Receipt> createGeneral({required String clientId, required int amount, required DateTime receiptDate, String? note, required String deviceId})`:
   - Validate `amount > 0`.
   - Generate receipt UUID.
   - Use `ReceiptAllocator(db).allocateFifo(clientId, amount)` to compute FIFO allocations.
   - Inside `_db.transaction(() async { ... })`:
     a. Insert `Receipt` row (type=GENERAL, clientId, invoiceId=null, amount, receiptDate, note, status=ACTIVE, timestamps, deviceId, rowVersion=1, syncStatus=PENDING).
     b. For each allocation from the allocator:
        - Set `receiptId` to the receipt UUID.
        - Insert the allocation row.
        - Create outbox entry for RECEIPT_ALLOCATION (operation=CREATE).
     c. Create outbox entry for RECEIPT (operation=CREATE).
   - Return the inserted Receipt.
2. Import `ReceiptAllocator`.

**Dependencies**: T001 (ReceiptAllocator), T006 (file exists).

**Acceptance criteria**:
- Amount > 0 enforced.
- FIFO allocations created for oldest invoices first.
- If no unpaid invoices, receipt saved with zero allocations (client credit per spec §Clarifications).
- If amount exceeds all outstanding invoices, partial allocation + unallocated remainder.
- All in single transaction.

---

### T008 — Add voidReceipt method to ReceiptRepository

- [x] T008 Add `voidReceipt` method to `motaz_app_flutter/lib/features/receipts/data/receipt_repository.dart`

**Objective**: Build receipt voiding with allocation reversal.

**Before implementing**: Read `specs/005-invoices-receipts/spec.md` FR-017, FR-018, FR-021, US7 scenarios. Read `specs/005-invoices-receipts/research.md` §7 (Receipt Void Behavior).

**Files to update**:
- `motaz_app_flutter/lib/features/receipts/data/receipt_repository.dart`

**Exact scope**:
1. Implement `Future<void> voidReceipt(String id, String reason, String deviceId)`:
   - Validate `reason.trim().isNotEmpty` — throw if empty.
   - Fetch existing receipt via `getById(id)`.
   - Validate `existing.status == RecordStatus.ACTIVE` — throw if already voided (FR-021).
   - Inside `_db.transaction(() async { ... })`:
     a. Delete all allocations for this receipt: `DELETE FROM receipt_allocations WHERE receiptId = ?`.
     b. Update the receipt: `status = VOIDED, voidReason = reason, updatedAt, rowVersion+1, syncStatus=PENDING`.
     c. Create outbox entry for RECEIPT (operation=UPDATE) with full payload.
   - **Important**: Per FR-018, do NOT re-allocate other receipts. Only the voided receipt's allocations are removed.

**Dependencies**: T006 (file exists).

**Acceptance criteria**:
- Empty reason throws.
- Already-voided receipt throws (FR-021).
- All allocations for this receipt are deleted.
- Receipt status set to VOIDED.
- NO re-allocation triggered (per FR-018 — this is different from invoice void).
- All in single transaction with outbox entry.

---

## Phase 3: Providers (Application Layer)

**Purpose**: Build Riverpod providers that expose repositories and reactive data streams to the UI.

### T009 — Create InvoiceProviders

- [x] T010 [P] Create receipt providers in `motaz_app_flutter/lib/features/receipts/application/receipt_providers.dart`

**Objective**: Create Riverpod providers for invoice list, search, and repository access.

**Before implementing**: Read `motaz_app_flutter/lib/features/products/application/product_providers.dart` for the established pattern. Read `specs/005-invoices-receipts/spec.md` FR-022, FR-023.

**Files to create**:
- `motaz_app_flutter/lib/features/invoices/application/invoice_providers.dart`

**Exact scope**:
1. `final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) { ... })` — wraps `InvoiceRepository(ref.watch(appDatabaseProvider))`.
2. `final invoiceListProvider = StreamProvider<List<SalesInvoice>>((ref) { ... })` — `db.select(db.salesInvoices)..orderBy([(t) => OrderingTerm.desc(t.invoiceDate)])` then `.watch()`.
3. `final invoiceSearchProvider = StreamProvider.family<List<SalesInvoice>, String>((ref, query) { ... })` — filter by `t.localRef.like('%$q%')` OR join with clients table to match `client.displayName.like('%$q%')`. Order by invoiceDate DESC.
   - **Note**: For client name search, use a custom select query joining `sales_invoices` with `clients` since Drift doesn't easily chain cross-table filters in `.watch()`. Alternative: filter client name in Dart after fetching. Choose the simpler approach — filter in Dart by first fetching all invoices and mapping client names.

**Dependencies**: T003 (InvoiceRepository complete).

**Acceptance criteria**:
- File compiles.
- All 3 providers created with correct types.
- List provider orders by invoiceDate DESC.
- Search provider filters by localRef or client name.

---

### T010 — Create ReceiptProviders

- [x] T010 [P] Create receipt providers in `motaz_app_flutter/lib/features/receipts/application/receipt_providers.dart`

**Objective**: Create Riverpod providers for receipt list, search, and repository access.

**Before implementing**: Follow the same pattern as `invoice_providers.dart` and `product_providers.dart`.

**Files to create**:
- `motaz_app_flutter/lib/features/receipts/application/receipt_providers.dart`

**Exact scope**:
1. `final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) { ... })`.
2. `final receiptListProvider = StreamProvider<List<Receipt>>((ref) { ... })` — ordered by `receiptDate DESC`.
3. `final receiptSearchProvider = StreamProvider.family<List<Receipt>, String>((ref, query) { ... })` — filter by client name (fetch all, filter in Dart by joining client displayName).

**Dependencies**: T008 (ReceiptRepository complete).

**Acceptance criteria**:
- File compiles.
- All 3 providers created.
- List provider orders by receiptDate DESC.

---

## Phase 4: US1 — Create a Sales Invoice (Priority: P1) 🎯 MVP

**Goal**: Owner can create an invoice with client selection, product autocomplete, line items, discount, and optional payment capture.

**Independent Test**: While offline, create an invoice for an existing client with 2 products, verify invoice appears in list with correct total and local ref.

### T011 — Create invoice form screen

- [x] T011 [US1] Create invoice form screen in `motaz_app_flutter/lib/features/invoices/presentation/invoice_form_screen.dart`

TheoldString was be,

**Objective**: Build the invoice creation form with client selection, product autocomplete line builder, discount, paid amount, and save.

**Before implementing**: Read `specs/005-invoices-receipts/spec.md` US1, US2 (payment capture), FR-001 through FR-007. Read `specs/005-invoices-receipts/research.md` §9 (Product Autocomplete). Read `motaz_app_flutter/lib/features/products/presentation/product_form_screen.dart` for the established form pattern.

**Files to create**:
- `motaz_app_flutter/lib/features/invoices/presentation/invoice_form_screen.dart`

**Exact scope**:
1. `InvoiceFormScreen` — a `ConsumerStatefulWidget` accepting optional `existingInvoice` for edit mode.
2. **For create mode** (this task — edit mode handled in T015):
   - Client selection: A button/widget that opens a dialog or dropdown to select a client from `clientListProvider`. Display selected client name. Mandatory — validate before save.
   - Invoice date: `DateTime` field defaulting to `DateTime.now()`. Allow date picker.
   - Line items builder: A dynamic list of line item rows. Each row has:
     - Product autocomplete `TextField` using `activeProductSearchProvider`. On select, populate productId and default unitPrice from `product.defaultSalePrice`.
     - Quantity `TextField` (integer ≥ 1, validated).
     - Unit price `TextField` (displayed in YER with 2 decimals, converted to/from minor-unit integers — same pattern as `ProductFormScreen` price fields).
     - Line total display: `quantity × unitPrice` formatted as YER.
     - Remove line button.
   - "Add line" button to append a new empty row. At least 1 line required (validated on save).
   - Discount `TextField` (displayed in YER, converted to minor-unit integer). Validated: `discount ≤ subtotal`.
   - Subtotal display: `Σ(line totals)` formatted as YER.
   - Total display: `subtotal - discount` formatted as YER.
   - Paid amount `TextField` (displayed in YER, converted to minor-unit integer). Validated: `paidAmount ≤ total` and `paidAmount ≥ 0`.
   - Note `TextField` (optional, multiline).
   - Save button: calls `invoiceRepositoryProvider.create(...)`.
3. All labels in Arabic:
   - "إنشاء فاتورة" (title), "العميل *" (client), "تاريخ الفاتورة" (date), "المنتج" (product), "الكمية" (quantity), "سعر الوحدة" (unit price), "إجمالي السطر" (line total), "إضافة سطر" (add line), "الخصم" (discount), "الإجمالي الفرعي" (subtotal), "الإجمالي" (total), "المبلغ المدفوع" (paid amount), "ملاحظة" (note), "حفظ" (save).
4. After save, navigate back (pop).
5. Show loading indicator during save. Catch errors and display via `SnackBar`.
6. Get `deviceId` from `deviceServiceProvider.ensureCurrentDevice()`.

**Dependencies**: T009 (invoice providers), T010 (receipt providers — not strictly needed but for completeness).

**Acceptance criteria**:
- Form renders all fields.
- Client selection is mandatory — save blocked without client.
- At least 1 line item required.
- Product autocomplete shows only active products.
- Unit price defaults from product but can be overridden.
- Discount ≤ subtotal enforced.
- Paid amount ≤ total enforced.
- All price/amount fields convert between display format (YER 2 decimals) and minor-unit integers.
- No `double` in the save path.
- Arabic labels on all fields.

---

## Phase 5: US8 — View Invoice List and Details (Priority: P1)

**Goal**: Owner can view, search, and navigate invoices with full detail view.

**Independent Test**: Create 5 invoices, open the list, search by client name, tap one to see full details.

### T012 — Create invoice list screen

- [x] T012 [US8] Create invoice list screen in `motaz_app_flutter/lib/features/invoices/presentation/invoice_list_screen.dart``

**Objective**: Build the invoice list with search, status display, and navigation to detail.

**Before implementing**: Read `specs/005-invoices-receipts/spec.md` FR-022, FR-023, US8 scenarios. Follow the pattern from `motaz_app_flutter/lib/features/products/presentation/product_list_screen.dart`.

**Files to create**:
- `motaz_app_flutter/lib/features/invoices/presentation/invoice_list_screen.dart`

**Exact scope**:
1. `InvoiceListScreen` — a `ConsumerStatefulWidget`.
2. Use `AppDrawerScaffold` with title "الفواتير" and currentRoute "/invoices".
3. Search bar with 300ms debounce (same pattern as ProductListScreen).
4. Use `invoiceListProvider` (no search) or `invoiceSearchProvider(query)` (with search).
5. Each list item shows:
   - `localRef` as title.
   - Subtitle: client name (fetch via `ref.watch(clientListProvider)` and map by clientId, or join in provider). Show `'${(invoice.total / 100).toStringAsFixed(2)} ر.ي.'` and remaining balance.
   - Status indicator: if voided, show "ملغية" in red with `Opacity(0.6)`.
6. FloatingActionButton (add icon) → navigate to `InvoiceFormScreen()`.
7. Tap → navigate to `InvoiceDetailScreen(invoiceId: invoice.id)`.

**Dependencies**: T009 (invoice providers).

**Acceptance criteria**:
- List displays invoices newest-first.
- Search filters by localRef or client name.
- Voided invoices show visual indicator.
- FAB navigates to create form.
- Tap navigates to detail screen.
- Arabic labels.

---

### T013 — Create invoice detail screen

- [x] T013 [US8] Create invoice detail screen in `motaz_app_flutter/lib/features/invoices/presentation/invoice_detail_screen.dart`

**Objective**: Show full invoice details including lines, receipts, remaining balance, and action buttons (edit, void, add receipt).

**Before implementing**: Read `specs/005-invoices-receipts/spec.md` FR-024, US8 scenario 3. Read `specs/005-invoices-receipts/spec.md` US3 (edit constraints), US4 (void), US5 (add receipt).

**Files to create**:
- `motaz_app_flutter/lib/features/invoices/presentation/invoice_detail_screen.dart`

**Exact scope**:
1. `InvoiceDetailScreen` — a `ConsumerStatefulWidget` accepting `String invoiceId`.
2. On `initState`, load all data via the repository:
   - Invoice via `getById`.
   - Lines via `getLinesForInvoice`.
   - Receipts via `getReceiptsForInvoice`.
   - Collected amount via `getCollectedAmount`.
   - Remaining balance via `getRemainingBalance`.
   - Client name via client repository `getById`.
   - Edit state: `hasActiveReceipts`, `hasActiveReturns`.
3. Display:
   - AppBar title: `localRef`.
   - Card 1 — Invoice info: client name, date, note, status badge (ACTIVE green / VOIDED red with reason).
   - Card 2 — Lines table/list: product name (resolve from product ID), quantity, unit price (formatted YER), line total (formatted YER).
   - Subtotal row, discount row, total row.
   - Card 3 — Payments: list of receipts (type, amount, date, status). Show "لا توجد دفعات" if empty.
   - Summary: collected amount and remaining balance.
4. Action buttons (show only for ACTIVE invoices):
   - "تعديل" (edit) → navigate to `InvoiceFormScreen(existingInvoice: invoice, lines: lines, editMode: ...)`. Determine edit mode from `hasReturns`/`hasReceipts`.
   - "إلغاء الفاتورة" (void) → show dialog asking for reason (required text field), then call `invoiceRepository.voidInvoice(...)`. On success, reload data.
   - "إضافة دفعة" (add receipt) → navigate to `ReceiptFormScreen(invoiceId: invoice.id, clientId: invoice.clientId, maxAmount: remainingBalance)`. Show only if `remainingBalance > 0`.
5. After returning from edit/void/receipt, reload all data.

**Dependencies**: T005 (void method), T009 (providers).

**Acceptance criteria**:
- All invoice data displayed correctly.
- Lines show product names resolved from ID.
- All monetary values formatted as YER with 2 decimals.
- Void dialog requires reason.
- Edit button navigates with correct edit constraints.
- Add receipt button hidden when fully paid or voided.
- Arabic labels.

---

## Phase 6: US3 — Edit a Sales Invoice (Priority: P1)

**Goal**: Owner can edit invoices with correct constraint enforcement based on receipt/return state.

**Independent Test**: Create an invoice with no payments, edit a line quantity, verify total recalculates.

### T014 — Implement edit mode in InvoiceFormScreen

- [x] T014 [US3] Add edit mode to `motaz_app_flutter/lib/features/invoices/presentation/invoice_form_screen.dart`

**Objective**: Extend the form screen to support editing existing invoices with correct constraint enforcement.

**Before implementing**: Read `specs/005-invoices-receipts/spec.md` FR-008, FR-009, US3 scenarios. Read `specs/005-invoices-receipts/research.md` §5 (Invoice Edit State Detection).

**Files to update**:
- `motaz_app_flutter/lib/features/invoices/presentation/invoice_form_screen.dart`

**Exact scope**:
1. Accept additional constructor params: `SalesInvoice? existingInvoice`, `List<SalesInvoiceLine>? existingLines`, `bool hasReceipts`, `bool hasReturns`, `int collectedAmount`.
2. In `initState`, if editing:
   - Populate all fields from `existingInvoice` and `existingLines`.
   - Convert minor-unit integers to display format for price fields.
3. Edit constraints:
   - If `hasReturns == true`: disable all fields except note. Show banner: "لا يمكن تعديل الحقول المالية بسبب وجود مرتجعات" (Cannot edit financial fields due to returns). Only call `updateNote()` on save.
   - If `hasReceipts == true && hasReturns == false`: all fields editable. On save, validate `newTotal >= collectedAmount`. Show helper text: "الحد الأدنى للإجمالي: ${(collectedAmount / 100).toStringAsFixed(2)} ر.ي." (Minimum total: X YER).
   - If neither: all fields editable, no constraint.
4. Change title to "تعديل فاتورة" in edit mode.
5. On save in edit mode, call `invoiceRepository.update(...)`.
6. Hide paid amount field in edit mode (payment capture only at creation).
7. Change client selection: in edit mode with receipts, client field can still be changed (per FR-008). In edit mode with returns, client field is disabled.

**Dependencies**: T011 (form screen exists), T004 (update method).

**Acceptance criteria**:
- Voided invoices cannot reach this screen (guard in detail screen).
- Returns-constrained: only note editable, all other fields disabled.
- Receipt-constrained: total ≥ collected enforced on save.
- Unrestricted: all fields editable.
- Correct method called on save (`update` vs `updateNote`).
- Paid amount field hidden in edit mode.

---

## Phase 7: US4 — Void a Sales Invoice (Priority: P1)

**Goal**: Owner can void an active invoice via the detail screen.

**Independent Test**: Create an invoice, void it with reason, verify it shows as voided.

### T015 — Void action already implemented in T013 (InvoiceDetailScreen)

The void action was implemented as part of T013 (invoice detail screen). This phase is satisfied.

**No additional task needed** — T013 includes the void dialog with reason and calls `invoiceRepository.voidInvoice(...)`.

---

## Phase 8: US5 — Create an Invoice-Linked Receipt (Priority: P1)

**Goal**: Owner can add a follow-up payment to an existing invoice.

**Independent Test**: Create an invoice for 1000 YER, pay 400 at creation, add a second receipt for 300, verify remaining balance is 300.

### T016 — Create receipt form screen

- [x] T016 [US5] Create receipt form screen in `motaz_app_flutter/lib/features/receipts/presentation/receipt_form_screen.dart`

**Objective**: Build a form for creating both invoice-linked and general receipts.

**Before implementing**: Read `specs/005-invoices-receipts/spec.md` FR-013, FR-014, FR-015, US5, US6 scenarios. Follow the form pattern from `ProductFormScreen`.

**Files to create**:
- `motaz_app_flutter/lib/features/receipts/presentation/receipt_form_screen.dart`

**Exact scope**:
1. `ReceiptFormScreen` — a `ConsumerStatefulWidget` accepting optional params:
   - `String? invoiceId` — if provided, creates invoice-linked receipt.
   - `String? clientId` — required for invoice-linked; selected by user for general.
   - `int? maxAmount` — max allowed amount for invoice-linked receipt.
2. **Invoice-linked mode** (when `invoiceId != null`):
   - Client is pre-set (from invoice) — display as read-only.
   - Amount field: validated `> 0` and `≤ maxAmount`.
   - Receipt date: default to now, date picker allowed.
   - Note: optional.
   - On save: call `receiptRepository.createInvoiceLinked(...)`.
3. **General mode** (when `invoiceId == null`):
   - Client selection (same widget as invoice form — select from clientListProvider).
   - Amount field: validated `> 0`.
   - Receipt date: default to now, date picker allowed.
   - Note: optional.
   - On save: call `receiptRepository.createGeneral(...)`.
4. Title: "إضافة دفعة مرتبطة بفاتورة" (invoice-linked) or "إضافة دفعة عامة" (general).
5. Amount displayed in YER with 2 decimals, converted to minor-unit integer on save.
6. Get `deviceId` from `deviceServiceProvider`.
7. Show loading, catch errors, pop on success.

**Dependencies**: T006 (createInvoiceLinked), T007 (createGeneral), T010 (receipt providers).

**Acceptance criteria**:
- Invoice-linked mode: client read-only, amount ≤ maxAmount enforced.
- General mode: client selection mandatory.
- Amount > 0 enforced in both modes.
- Correct repository method called based on mode.
- No `double` in save path.
- Arabic labels.

---

## Phase 9: US6 — Create a General Client Receipt with FIFO (Priority: P2)

**Goal**: Owner can create a general payment for a client with automatic FIFO allocation.

**Independent Test**: Create 3 invoices (1000, 800, 500), create general receipt for 1500, verify allocations.

### T017 — General receipt creation already implemented in T016

The general receipt form mode was implemented in T016 (receipt form screen). The FIFO logic is in T001 (allocator) and T007 (createGeneral method). This phase is satisfied.

**No additional task needed**.

---

## Phase 10: US7 — Void a Receipt (Priority: P2)

**Goal**: Owner can void a receipt, reversing its allocations.

**Independent Test**: Create an invoice for 1000, pay 600, void the receipt, verify remaining balance returns to 1000.

### T018 — Add void action to receipt list/detail

- [x] T018 [US7] Add void receipt action to `motaz_app_flutter/lib/features/receipts/presentation/receipt_list_screen.dart`

**Objective**: Add a popup menu or action to void a receipt from the receipt list.

**Before implementing**: Read `specs/005-invoices-receipts/spec.md` FR-017, FR-021, US7 scenarios.

**Files to update**:
- `motaz_app_flutter/lib/features/receipts/presentation/receipt_list_screen.dart` (created in T019 — adjusted dependency below)

**Exact scope**:
1. For each ACTIVE receipt in the list, add a `PopupMenuButton` with option "إلغاء السند" (void receipt).
2. On tap, show a dialog asking for void reason (required text field).
3. On confirm, call `receiptRepository.voidReceipt(id, reason, deviceId)`.
4. On success, the `StreamProvider` auto-refreshes the list.
5. For voided receipts, show "ملغى" badge and disable the menu.

**Dependencies**: T008 (voidReceipt method), T019 (receipt list screen exists).

**Acceptance criteria**:
- Void requires reason text.
- Already-voided receipts cannot be voided again.
- List refreshes after void.
- Arabic label "إلغاء السند".

---

## Phase 11: US9 — View Receipt List (Priority: P2)

**Goal**: Owner can view and search receipts.

**Independent Test**: Create several receipts of both types, verify list shows correct type labels and amounts.

### T019 — Create receipt list screen

- [x] T019 [US9] Create receipt list screen in `motaz_app_flutter/lib/features/receipts/presentation/receipt_list_screen.dart`

**Objective**: Build the receipt list with search, type labels, and status display.

**Before implementing**: Read `specs/005-invoices-receipts/spec.md` FR-025, FR-026, US9 scenarios. Follow pattern from `ProductListScreen`.

**Files to create**:
- `motaz_app_flutter/lib/features/receipts/presentation/receipt_list_screen.dart`

**Exact scope**:
1. `ReceiptListScreen` — `ConsumerStatefulWidget`.
2. Use `AppDrawerScaffold` with title "سندات القبض" and currentRoute "/receipts".
3. Search bar with 300ms debounce.
4. Use `receiptListProvider` or `receiptSearchProvider(query)`.
5. Each list item shows:
   - Client name (resolve from clientId).
   - Amount formatted as YER.
   - Type label: "مرتبط بفاتورة" (INVOICE_LINKED) or "دفعة عامة" (GENERAL).
   - Date.
   - Status: voided receipts show "ملغى" in red with `Opacity(0.6)`.
6. FloatingActionButton → navigate to `ReceiptFormScreen()` (general mode).
7. For ACTIVE receipts, `PopupMenuButton` with "إلغاء السند" (void) option — shows reason dialog, calls `voidReceipt`.

**Dependencies**: T010 (receipt providers).

**Acceptance criteria**:
- Receipts displayed newest-first.
- Type labels correct.
- Search filters by client name.
- Voided receipts have visual indicator.
- Void option on active receipts only.
- FAB navigates to general receipt form.
- Arabic labels.

---

## Phase 12: Router Update & Placeholder Cleanup

**Purpose**: Connect new screens to the app router and remove placeholders.

### T020 — Update app router

- [x] T020 Update router and remove placeholders in `motaz_app_flutter/lib/core/router/app_router.dart`

**Objective**: Replace invoice and receipt placeholder screens with real screens.

**Before implementing**: Read `motaz_app_flutter/lib/core/router/app_router.dart` current state. Check which placeholder imports to remove.

**Files to update**:
- `motaz_app_flutter/lib/core/router/app_router.dart`

**Files to delete**:
- `motaz_app_flutter/lib/features/invoices/presentation/placeholder_screen.dart`
- `motaz_app_flutter/lib/features/receipts/presentation/placeholder_screen.dart`

**Exact scope**:
1. Replace import of `InvoicesPlaceholderScreen` with `InvoiceListScreen`.
2. Replace import of `ReceiptsPlaceholderScreen` with `ReceiptListScreen`.
3. Update route `/invoices` to use `InvoiceListScreen()`.
4. Update route `/receipts` to use `ReceiptListScreen()`.
5. Delete the two placeholder files.

**Dependencies**: T012 (invoice list), T019 (receipt list).

**Acceptance criteria**:
- `/invoices` route renders `InvoiceListScreen`.
- `/receipts` route renders `ReceiptListScreen`.
- Placeholder files deleted.
- `dart analyze` shows no errors in router file.

---

## Phase 13: Polish & Verification

**Purpose**: Final verification and cleanup.

### T021 — Run static analysis and verify compilation

- [x] T021 Run `dart analyze` in `motaz_app_flutter/` and fix any errors or warnings in new files

**Objective**: Ensure all new code compiles cleanly.

**Exact scope**:
1. Run `dart analyze` from `motaz_app_flutter/`.
2. Fix any errors or warnings in files created/modified in this feature.
3. Do NOT fix pre-existing warnings in other files (sync module, etc.).

**Dependencies**: All previous tasks.

**Acceptance criteria**:
- `dart analyze` reports 0 errors and 0 warnings in invoice/receipt files.

---

### T022 — Verify end-to-end flow manually

- [x] T022 Verify: create invoice with payment, view in list, view detail, edit, void, create receipt, void receipt

**Objective**: Walk through the complete flow to ensure all pieces connect.

**Exact scope**:
1. Launch the app.
2. Create a product and a client (if not already present).
3. Create an invoice with 2 lines, a discount, and a paid amount.
4. Verify the invoice appears in the list with correct total and localRef.
5. Tap to see detail — verify lines, payment, remaining balance.
6. Edit the invoice — change a quantity, verify total recalculates.
7. Create a second invoice-linked receipt from the detail screen.
8. Void the receipt — verify remaining balance increases.
9. Void the invoice — verify it shows as voided.
10. Create a general receipt for the client — verify FIFO allocation.

**Dependencies**: T021 (clean compilation).

**Acceptance criteria**:
- All 10 steps complete without errors or crashes.
- All amounts display correctly in YER format.
- All Arabic labels render correctly in RTL.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational)**: No dependencies — start immediately. T001→T002→T003→T004→T005 (sequential).
- **Phase 2 (Receipt Repository)**: Depends on T001 (allocator). T006→T007→T008 (sequential).
- **Phase 3 (Providers)**: T009 depends on T005. T010 depends on T008. T009 and T010 can run in parallel.
- **Phase 4–11 (UI Screens)**: All depend on Phase 3 providers.
- **Phase 12 (Router)**: Depends on T012 and T019.
- **Phase 13 (Polish)**: Depends on all previous.

### Critical Path

```
T001 → T002 → T003 → T004 → T005 (InvoiceRepo complete)
T001 → T006 → T007 → T008 (ReceiptRepo complete)
T009 + T010 (Providers — parallel)
T011 → T014 (Invoice form + edit mode)
T012 → T013 (Invoice list + detail)
T016 (Receipt form)
T019 → T018 (Receipt list + void action)
T020 (Router update)
T021 → T022 (Verify)
```

### Parallel Opportunities

- T009 and T010 can run in parallel (different files, no dependencies on each other).
- T011, T012, T016, T019 can run partially in parallel once providers are ready (different files).

---

## Implementation Strategy

### MVP First (US1 + US8 Only)

1. Complete Phase 1: T001–T005 (InvoiceRepository)
2. Complete Phase 2: T006–T008 (ReceiptRepository)
3. Complete Phase 3: T009–T010 (Providers)
4. Complete Phase 4: T011 (Invoice form — create mode)
5. Complete Phase 5: T012, T013 (Invoice list + detail)
6. **STOP and VALIDATE**: Create an invoice, view it, verify total.

### Full Delivery

7. Phase 6: T014 (Edit mode)
8. Phase 8: T016 (Receipt form)
9. Phase 11: T019, T018 (Receipt list + void)
10. Phase 12: T020 (Router)
11. Phase 13: T021, T022 (Polish + verify)

---

## Notes

- All monetary values use `int` (minor units). Display conversion: `(value / 100).toStringAsFixed(2)`.
- All UI text in Arabic. RTL layout.
- Follow the transaction + outbox pattern established in `ProductRepository`.
- No schema migration needed — all tables exist from Phase 2.
- The `ReceiptAllocator` is shared between ReceiptRepository (general receipt) and InvoiceRepository (void reallocation).
- Do NOT implement attachment upload UI — that's a separate feature.
- Do NOT implement returns logic — that's Phase 7.
- Do NOT implement reports — that's Phase 8.
