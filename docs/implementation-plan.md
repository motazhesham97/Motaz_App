# Motaz_App — Master Implementation Plan v2

**Version**: 2.0.0
**Date**: 2026-03-16
**Constitution**: v1.3.0
**Status**: Approved baseline

---

## 1. Final Goal

Build a Business Management and Accounting application for a single business entity, operating offline-first on Android and Windows.

The MVP must deliver:

- Products and Clients
- Sales invoices with editing constraints
- Receipts (invoice-linked and general with FIFO allocation)
- Expenses (5 approved categories)
- Partial sales returns with reversal logic
- Monthly profit distribution across Owner / Partner / The Margin
- Internal party balances with draw support
- Dashboard with defined KPI cards
- Reports with date-range filtering
- PDF export for all reports and client statements (Arabic RTL)
- Automatic synchronization between local devices and Neon

---

## 2. Frozen Decisions

These decisions are fixed and documented in the constitution v1.3.0.

### Product / Business
- Single-owner only in MVP — one user, no staff, no sharing
- Periodic accounting model, not per-unit cost accounting
- Monthly net profit = Net Sales − Operational Expenses − Production Expenses
- Net profit distributed equally across Owner, Partner, The Margin (integer shares, remainder to Margin)
- Official profit distribution is monthly only; other periods are reporting views only
- Draws (OWNER_DRAW, PARTNER_DRAW, MARGIN_DRAW) affect only the corresponding internal account balance
- Currency: YER only (2 decimal places, minor-unit integer storage)
- Taxes: out of scope in MVP
- Inventory tracking: out of scope in MVP
- Multi-currency: out of scope in MVP
- Due dates and payment terms: out of scope in MVP

### Architecture
- Frontend: Flutter
- Backend: Serverpod (Dart)
- Local database: SQLite, accessed via **Drift**
- Cloud database: PostgreSQL on Neon
- Attachments: Cloudinary
- State management: **flutter_riverpod**
- Planning workflow: Spec Kit
- App architecture: Offline-first
- Flutter project structure: **Feature-First Modular Monolith**
- Financial records must never use hard delete
- Financial conflicts must never be silently auto-merged
- If one device voids and another edits the same financial record: **void wins**
- Attachments are preserved when a record is voided

---

## 3. What This Document Is

This is a **master implementation plan**, not a feature specification.

- Database / Backend / Frontend are implementation **tracks**
- The later specifications are **vertical functional slices**:
  1. Foundation & Sync
  2. Sales & Clients & Receipts
  3. Expenses & Profit Distribution
  4. Partial Returns & Reversals
  5. Reports & Dashboard & PDF

This document is the execution blueprint. The correct next step after this document is to extract the 5 vertical specifications, not to create layer-based specs.

---

## 4. Approved Runtime Architecture

### 4.1 On Device
- Flutter application
- SQLite local database (via Drift)
- Local repositories (Riverpod providers)
- Sync outbox
- Locally staged attachments
- Local report queries (compute-on-read)
- Local PDF generation

### 4.2 In the Cloud
- Serverpod services
- Neon PostgreSQL
- Cloudinary for attachments
- Sync services
- Reporting services (minimal in MVP — local-first is primary)
- Audit services
- Attachment approval/upload services

### 4.3 Core Operating Rule

Every mutation must follow this sequence:

1. Save locally to SQLite
2. Update local state
3. Register mutation in sync outbox
4. When internet is available:
   - Push local changes to server
   - Pull server changes
   - Reconcile and resolve conflicts
   - Update local database
   - Rebuild affected state if needed

---

## 5. Financial Representation

All monetary handling is fixed at this level:

| Concern | Rule |
|---|---|
| Domain logic | Minor-unit integers (2 decimal places) |
| Sync payloads | Minor-unit integers |
| Local SQLite | INTEGER (minor units) |
| Cloud PostgreSQL | BIGINT (minor units) |
| UI display | Formatted as YER with 2 decimal places |
| Precision | No `double` anywhere in the money path |

**Example**: 1250.00 YER is stored internally as `125000`

---

## 6. Engineering Workstreams

Three parallel tracks, delivering in phases:

| Track | Focus |
|---|---|
| **A — Data Layer** | SQLite schema (Drift), Neon schema, migrations, constraints, indexes |
| **B — Backend** | Serverpod endpoints, sync services, accounting services, reporting, attachments, audit |
| **C — Flutter App** | Local repositories, sync coordinator, Riverpod state, feature modules, forms, reports, PDF, dashboard |

---

## 7. Project Structure

Feature-First Modular Monolith inside the Flutter app:

```
lib/
  core/
  features/
    products/
      data/
      domain/
      application/
      presentation/
    clients/
    invoices/
    receipts/
    expenses/
    returns/
    profit_distribution/
    reports/
    dashboard/
    sync/
```

This is an implementation structure, not a constitutional rule.

---

## 8. Core Entities

### 8.1 Reference / Master Data
- **Product**
- **Client**
- **Device**

### 8.2 Financial Transactions
- **SalesInvoice** — with UUID primary key + `local_ref` (format: `INV-<deviceCode>-<localSequence>`)
- **SalesInvoiceLine**
- **Receipt** — invoice-linked or general client receipt
- **ReceiptAllocation** — explicit FIFO allocation records
- **Expense** — with category enum (5 types)
- **SalesReturn** — partial financial return
- **SalesReturnLine**

### 8.3 Sync / Audit
- **SyncOutbox** — mutation queue with entity type, ID, operation, payload, row version, retry count
- **SyncCursor** — last-pull timestamp per entity type
- **ConflictLog** — explicit conflict records requiring user resolution
- **AuditEvent** — immutable event log for every financial mutation

### 8.4 Attachments
- **AttachmentMetadata** — Cloudinary reference, linked to invoice or receipt
- **LocalAttachmentStaging** — offline attachment queue

### 8.5 Invoice Numbering

Each invoice has two identifiers:

| Identifier | Purpose |
|---|---|
| `id` (UUID) | True internal primary key |
| `local_ref` | Human-readable local reference: `INV-<deviceCode>-<localSequence>` |
| `official_no` | Null in MVP — reserved for future authoritative numbering |

- `deviceCode` is fixed per device
- `localSequence` increments locally per device
- Local creation never depends on an online central sequence

---

## 9. Derived Data Strategy

**MVP decision: compute-on-read**, not materialized projections.

| Concern | Approach |
|---|---|
| Source of truth | Raw transactional tables only |
| Local reports | Computed from SQLite via Drift queries |
| Server reports | Computed from PostgreSQL queries/views (minimal in MVP) |
| Synced projections | None — no synced materialized reporting entities in MVP |

**Explicitly stored (not derived caches):**
- ReceiptAllocation — real business record
- AuditEvent — immutable audit log
- ConflictLog — real conflict record

**Computed on read:**
- Client balance
- Monthly net profit
- Monthly party shares
- Party balances
- Sales by product
- Receivables aging
- Dashboard summaries

---

## 10. Executable Accounting Rules

### 10.1 Net Sales
```
Net Sales = Active Invoice Totals − Invoice Discounts − Active Financial Returns
```

### 10.2 Net Profit
```
Net Profit = Net Sales − Operational Expenses − Production Expenses
```

### 10.3 Monthly Distribution
```
owner_share  = trunc(net_profit / 3)
partner_share = trunc(net_profit / 3)
margin_share  = net_profit − owner_share − partner_share
```
trunc means round toward zero.

Distribution is performed monthly only. Other periods are reporting views only.

### 10.4 Party Balances
```
Party Balance = Accumulated Monthly Shares − Draws ± Valid Reversals
```
Balances may go negative with no minimum floor.

### 10.5 Receivables
Active invoices with remaining unpaid balances.

### 10.6 Client Credits
If an invoice is fully paid and then a partial return is created, a client credit is created.
Cash refund workflows are out of scope in MVP.

### 10.7 Receipts
Two types:
- **Invoice-linked receipt** — created during or after invoice creation. If `paidAmount > 0` at invoice creation, invoice and receipt are saved in the same local transaction.
- **General client receipt** — payment on account, auto-allocated by FIFO to oldest unpaid invoices.

### 10.8 Invoice Total
```
Invoice Total = Σ(line_qty × unit_price) − invoice_level_discount
```

---

## 11. Sync Strategy

### 11.1 Local-First Writes
Every create, update, void, return, receipt, and expense action writes locally first and never waits for network.

### 11.2 Outbox Model
Every mutation is stored in `sync_outbox` with: entity type, entity ID, operation type, payload snapshot, local row version, retry count, created_at.

### 11.3 Push / Pull Cycle

**Push**: Send local mutations to server. Server validates identity, row version, conflict rules, and accounting rules.

**Pull**: Retrieve changed rows since cursor, voided records, conflicts, and server-applied versions.

### 11.4 Conflict Rules

**Auto-merge (last-write-wins) allowed for:**
- `client.displayName`, `client.phone`, `client.note`, `client.clientCode`
- `product.description`, `product.isActive`
- `invoice.note`, `receipt.note`, `expense.note`, `return.note`
- Attachment metadata only

**Conflict required, no silent merge for:**
- Any monetary amount, quantity, price, discount, or financial date
- `invoice.clientId`, invoice lines, receipt allocations
- Returns, expense type, monthly distribution rows
- `product.name`, `product.defaultSalePrice`

**Hard rule**: If one device edits and another device voids the same financial record → **void wins**.

---

## 12. Attachment Strategy

### 12.1 Scope
Attachments are allowed only for invoices and receipts.

### 12.2 Offline Handling
If the user adds an attachment while offline: store locally as staged attachment, link to parent record, upload later when connectivity returns.

### 12.3 Cloud Flow
1. Flutter requests upload approval through Serverpod
2. Serverpod validates and applies upload policy
3. File is uploaded to Cloudinary
4. Neon stores only: public ID / asset reference, secure URL, metadata, owner entity type / ID

### 12.4 Preservation on Void
When a record is voided, its attachments remain preserved and linked. No auto-deletion.

---

## 13. Reports and PDF Strategy

### 13.1 Date Filtering
Every report and every client statement must support Start Date and End Date.

Optional quick filters: Today, This Week, This Month, This Year, All Time.

### 13.2 Required MVP Reports
1. Sales Report
2. Sales by Product
3. Expenses by Type
4. Profit Report
5. Client Statement
6. Receivables Report
7. Receivables Aging
8. Party Balances Report

### 13.3 PDF Export
- Available for every report and every client statement
- Uses the currently selected filters
- Generated locally from local data (offline-first)
- Must support Arabic content and correct RTL rendering
- Library: **pdf** + **printing** packages (pure Dart)
- Arabic fonts must be embedded properly

### 13.4 Reporting Data Source in MVP
- **Primary**: local SQLite queries (compute-on-read via Drift)
- **Backend reporting endpoints**: not critical in MVP, may exist minimally or be deferred
- Reports must work fully offline

---

## 14. Dashboard Specification

The MVP dashboard contains exactly these cards:

| Card | Data |
|---|---|
| Today Net Sales | Sum of today's active invoice totals minus returns |
| This Month Net Sales | Sum of current month's active invoice totals minus returns |
| This Month Net Profit | Net sales minus operational and production expenses for current month |
| Outstanding Receivables Total | Total remaining unpaid balances across all active invoices |
| Owner Balance | Accumulated shares minus draws |
| Partner Balance | Accumulated shares minus draws |
| Margin Balance | Accumulated shares minus draws plus remainders |
| This Month Expense Summary by Type | Breakdown of current month expenses by the 5 categories |
| Recent Activity Feed | Latest 10 actions: invoice, receipt, expense, return, void |

**Out of scope for MVP dashboard**: top products, top clients, advanced analytics charts.

---

## 15. Authentication

| Concern | Decision |
|---|---|
| Mechanism | Serverpod email + password authentication |
| Scope | One owner account only |
| Staff / sharing | Not in MVP |
| Social login | Not in MVP |
| Device identity | Tracked separately; does not replace user authentication |

All synced operations must be authenticated through the owner account.

---

## 16. Tech Stack Summary

| Technology | Purpose |
|---|---|
| **Flutter** | Frontend framework (Android + Windows) |
| **Serverpod** | Backend framework (Dart) |
| **Drift** | Local SQLite access, schema, migrations, queries |
| **flutter_riverpod** | State management |
| **Neon PostgreSQL** | Cloud database |
| **Cloudinary** | Attachment file storage |
| **pdf + printing** | PDF generation with Arabic RTL |
| **Serverpod ORM** | Server-side database access and code-generated protocol classes |

### Serverpod Adoption Level
- **Use deeply**: auth, protocol classes, generated models, endpoints, services, standard ORM, migrations
- **Raw SQL**: allowed only where justified — heavy reporting queries, optimized aggregations, specialized cases

---

## 17. Phased Execution Plan

### Phase 0 — Freeze & Bootstrap
**Goal**: Lock all decisions before coding.

**Deliverables:**
- Constitution frozen (v1.3.0) ✓
- Master Implementation Plan v2 (this document) ✓
- Spec extraction map
- Tech stack summary ✓
- Project structure direction ✓
- Naming conventions
- Monetary representation decision ✓
- Sync protocol draft

---

### Phase 1 — Workspace Foundation
**Goal**: Create the project foundation.

**Backend:**
- Create Serverpod project
- Configure Neon connection and environments
- Logging and error handling
- Serverpod email+password auth for owner account

**Frontend:**
- Create Flutter app shell
- Routing, theme, RTL baseline, localization baseline (Arabic-first)
- Dependency injection baseline (Riverpod)
- Connectivity monitoring baseline

**Data:**
- Drift integration and database bootstrap
- Migration baseline
- UUID and device identity bootstrap

**Deliverables:**
- Repository initialized, build pipelines working
- Local DB opens correctly, server connects to Neon
- Basic sync contract skeleton created

---

### Phase 2 — Core Data Model
**Goal**: Build the canonical local and cloud schema.

**Includes:**
- Products, clients, invoices, invoice lines
- Receipts, receipt allocations, expenses
- Returns, return lines, attachment metadata
- Devices, audit events, conflicts
- Sync cursors, sync outbox

**Key Deliverables:**
- Local SQLite schema complete (Drift)
- Neon schema complete (Serverpod ORM + migrations)
- Constraints and search indexes verified

---

### Phase 3 — Sync Foundation
**Goal**: Build the real sync engine.

**Backend:**
- Push service, pull service
- Row version checks, conflict emission
- Device registration, sync cursor logic

**Frontend:**
- Sync coordinator, outbox processor
- Connectivity-triggered sync, manual retry
- Sync status badge, pending changes state

**Data:**
- Outbox queue, conflict staging
- Last-pull cursor, retry/backoff rules

**Deliverables:**
- Two-way sync working
- Device A / Device B reconciliation working
- Explicit conflict records working

---

### Phase 4 — Products & Clients
**Goal**: Complete the core reference data flows.

**Products**: Add, edit, disable, unique name validation, local search
**Clients**: Add, edit, search, duplicate-name-friendly UX, required identifying extra field, client summary baseline

**Deliverables:**
- Products feature stable offline
- Clients feature stable offline
- Duplicate-name UI is usable

---

### Phase 5 — Invoices & Receipts
**Goal**: Launch the core commercial transaction engine.

**Invoices:**
- Create invoice with product autocomplete, line editing, invoice-level discount
- Mandatory client selection, local save
- Payment capture at invoice creation (paidAmount > 0 → invoice-linked receipt in same transaction)
- Edit rules (unrestricted / receipt-constrained / return-constrained)
- Void with reason
- Local ref format: `INV-<deviceCode>-<localSequence>`

**Receipts:**
- Invoice-linked receipt (during or after invoice creation)
- General client receipt with FIFO allocation engine
- Void receipt with reallocation

**Accounting outcomes:**
- Totals, remaining balance, client balance, allocation persistence

**Deliverables:**
- Invoice lifecycle stable
- Receipt lifecycle stable
- FIFO allocation stable
- Client statement foundation stable

---

### Phase 6 — Expenses & Monthly Profit Distribution
**Goal**: Complete the periodic accounting engine.

**Expenses**: Add / edit / void, 5 approved categories, filtering, local and synced persistence

**Profit Engine:**
- Monthly net sales, monthly profit
- Monthly owner share, partner share, margin remainder
- Party balances (may go negative)

**Dashboard partial**: Monthly profit card, party balance cards, expense summary cards

**Deliverables:**
- Monthly accounting engine correct
- Negative balances supported and tested
- Distributions reproducible and deterministic

---

### Phase 7 — Partial Returns & Reversals
**Goal**: Complete the return and reversal logic.

**Returns:**
- Create partial return from invoice (quantity and amount validation)
- Financial effect: reduces outstanding balance or creates client credit
- Void return with reason, audit history, reversal of all accounting effects

**Reversals:**
- Receipt allocation recalculation when needed
- Invoice adjustment rules, return reversal rules

**Deliverables:**
- Return lifecycle stable
- Reversal logic stable
- No accounting drift after return / void sequences

---

### Phase 8 — Reports, Statements, Dashboard, PDF
**Goal**: Turn the system into a real daily operating tool.

**Reports**: Sales by period, sales by product, expenses by type, profit by period, receivables, receivables aging, party balances, client statement

**Dashboard**: All 9 KPI cards as specified in §14

**PDF**: Client statement PDF, all report PDFs, Arabic RTL rendering, selected date range support, embedded Arabic fonts

**Deliverables:**
- Reports complete (all 8 + dashboard)
- PDF complete with Arabic RTL
- All computed from local data (compute-on-read)

---

### Phase 9 — Hardening & Release Readiness
**Goal**: Make the system ready for real usage.

**Includes:**
- Performance tuning
- Sync failure recovery
- Migration upgrade tests
- Attachment failure tests
- PDF reliability
- Windows and Android QA
- Offline restart scenarios
- Conflict resolution UX polish
- Audit coverage validation

**Deliverables:**
- Release candidate
- Production checklist
- Known limitations document

---

## 18. Specifications To Extract

From this plan, 5 vertical specifications will be extracted:

| Spec | Covers |
|---|---|
| **001 — Foundation & Offline Sync** | Local DB (Drift), Neon schema (Serverpod ORM), sync engine, device identity, conflicts, staged attachments, auth |
| **002 — Sales, Clients & Receipts** | Products, clients, invoices (with local_ref, editing rules), receipts (both types, FIFO), client balances |
| **003 — Expenses & Profit Distribution** | Expense flows, monthly net profit, monthly distributions, party balances, draws |
| **004 — Partial Returns & Reversals** | Partial returns, client credits, reversal logic, return voiding, reallocation after changes |
| **005 — Reports, Dashboard & PDF** | Dashboard (9 cards), all 8 reports, date ranges, PDF export, Arabic RTL output |

---

## 19. Required Testing Scope

### Unit Tests
- Money calculations (minor-unit arithmetic, no floating-point)
- Discount allocation
- Monthly profit formula
- Profit distribution rule (integer split, remainder to Margin)
- FIFO allocation
- Client balance calculation
- Aging buckets
- Return effects and reversal effects

### Integration Tests
- Invoice + receipt flow (including payment at creation)
- Invoice edit with receipts (total ≥ collected)
- Invoice edit with returns (non-financial only)
- Invoice void with allocations
- Partial return on unpaid invoice
- Partial return on fully paid invoice (client credit)
- Receipt reallocation after invoice reduction
- Sync replay scenarios
- Void-wins conflict resolution

### Sync Tests
- Device A create, Device B sync
- Conflicting invoice edit
- Void-vs-edit (void must win)
- Offline attachment staging then upload
- Retry after network failure
- Auto-merge on allowed fields (notes, display metadata)
- Conflict emission on forbidden fields (amounts, prices)

### UI / Feature Tests
- Product search / autocomplete
- Invoice builder with payment capture
- Client statement filtering (date range)
- Report date range filtering
- Conflict resolution flows
- PDF generation trigger and Arabic RTL validation
- Dashboard KPI card correctness

---

## 20. Main Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Financial logic breaks due to uncontrolled edits | Strict domain services; no raw mutation from UI; invariant checks everywhere |
| Local and server reports diverge | Deterministic shared rules; identical formulas; same minor-unit money model; regression fixtures |
| Conflicts between phone and laptop | Explicit conflict records; no silent financial merge; void wins over edit |
| Offline attachment problems | Local staging; resumable upload strategy if needed; metadata-first association |
| Arabic PDF complexity | Standard printable templates; controlled font strategy; no overdesigned PDFs in MVP |
| Drift / Serverpod integration complexity | Well-defined boundary: Drift owns local, Serverpod ORM owns server; sync payloads bridge both |

---

## 21. Definition of Planning Completion

This implementation plan is considered complete when it can be converted into specs and tasks without ambiguity in:

- ✅ Business rules
- ✅ Sync rules (including void-wins, auto-merge allowlist)
- ✅ Money handling (2 decimal places, minor-unit integers)
- ✅ Returns and client credits
- ✅ FIFO allocations
- ✅ PDF and date filtering
- ✅ Attachment strategy (Cloudinary, staging, preservation on void)
- ✅ Backend choice (Serverpod with deep adoption)
- ✅ Storage choice (Drift local, Neon cloud, Cloudinary files)
- ✅ Auth choice (Serverpod email + password)
- ✅ State management (Riverpod)
- ✅ Project structure direction (Feature-First Modular Monolith)
- ✅ Invoice numbering (UUID + local_ref)
- ✅ Dashboard KPIs (9 cards defined)
- ✅ Derived data strategy (compute-on-read)

---

## 22. Next Steps

1. Keep this as the master implementation plan
2. Extract 5 vertical specs per §18
3. For each spec, generate:
   - `spec.md`
   - `plan.md`
   - `tasks.md`
4. Begin Phase 1 — Workspace Foundation

---

*Constitution reference: `.specify/memory/constitution.md` v1.3.0*
