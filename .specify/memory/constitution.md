<!--
Sync Impact Report
- Version change: 1.2.0 -> 1.3.0
- Modified principles:
  I. Product Truth: Added taxes out of scope and inventory out of scope.
     Added monetary precision rule (2 decimal places, minor-unit integer storage).
  II. Non-negotiables: Added void-wins conflict resolution rule.
      Added attachment preservation on void rule.
  VI. Security Rules: Clarified authentication as email+password through Serverpod.
- Added sections: none
- Removed sections: none
- Templates requiring updates: implementation plan must reference v1.3.0
- Follow-up TODOs: Finalize Master Implementation Plan v2
-->

# Motaz_App Constitution

## Core Principles

### I. Product Truth
- The app is a custom Business Management and Accounting application for a single business entity.
- The system is single-owner in MVP. One user only. No staff roles. No sharing.
- The core accounting model is periodic, not per-unit cost accounting.
- Monthly net profit is calculated as: Net Sales - Operational Expenses - Production Expenses.
- Net profit is distributed across exactly three internal accounts: Owner, Partner, and The Margin.
- Profit is split into 3 equal parts. Owner share and Partner share must always be whole integers. Any remainder goes to The Margin.
- Profit distribution into Owner, Partner, and The Margin is performed only on monthly periods. Daily, weekly, yearly, and custom-range profit reports are reporting views only and do not create distributable share entries.
- Owner Draw, Partner Draw, and Margin Draw do not affect net profit. They affect only the balance of their respective internal accounts.
- Draws are manual monetary entries that can happen at any time. They are not restricted to after monthly distribution.
- The Margin is an internal account with no special rules beyond receiving its profit share, receiving remainders, allowing draws, and being allowed to go negative.
- The app must run on Android and Windows.
- The app must work offline first, then sync automatically when connectivity returns.
- The system is single-currency only in MVP: Yemeni Rial (YER). No exchange rates. No multi-currency.
- All monetary values use two decimal places. Money is stored internally as minor-unit integers to avoid floating-point precision errors. Example: 1250.00 YER is stored as 125000.
- Taxes are out of scope in MVP.
- Inventory tracking is out of scope in MVP.

### II. Non-negotiables
- Offline-first is mandatory. Every create, edit, cancel, return, receipt, and expense action must save locally first without requiring internet.
- Financial records must never use hard delete in MVP. Invoices, receipts, returns, expenses, and allocation records must use void/cancel semantics with audit history.
- Product deletion is not allowed. Products may be disabled instead of deleted.
- Every sales invoice must belong to exactly one client. Anonymous cash sales are not allowed in MVP.
- Financial conflicts must never be silently auto-merged across devices.
- If one device voids a financial record while another device edits the same record before sync, void takes precedence.
- Invoice numbering is non-authoritative in MVP. Local creation must not depend on online sequential numbering.
- Attachments are allowed only for sales invoices and receipts.
- Attachment files must not be stored inside PostgreSQL binary fields. Files must live in Cloudinary, while metadata and storage references are stored in the database.
- Attachments selected while offline must be staged locally and uploaded later through the approved sync/upload pipeline when connectivity returns.
- When a record is voided, its attachments must be preserved. They must remain linked to the voided record and must not be auto-deleted. This ensures auditability and evidence preservation.

### III. Tech Constraints
- Frontend: Flutter.
- Target platforms in MVP: Android and Windows.
- Backend framework: Serverpod (Dart).
- The backend must expose sync, reporting, attachment, and audit-related endpoints through Serverpod services.
- Primary cloud database: PostgreSQL on Neon.
- Local on-device database: SQLite.
- Architecture: Offline-first with automatic background synchronization to Neon when the network is available.
- Structured business data must be saved locally first, then synchronized to Neon when connectivity is available.
- Attachment binary files must not be stored in Neon. Only attachment metadata and storage references are stored in Neon.
- Attachment storage provider: Cloudinary.
- Attachment uploads must use secure server-approved upload flows. Clients must not directly perform unsafe attachment writes to cloud services.
- Planning and specification workflow: Spec Kit.
- Code generation/planning model preference: GLM-5.
- MVP device target: 1 Android phone + 1 Windows laptop. The architecture should remain extensible for multiple devices later.
- No special device registration confirmation is required in MVP.

### IV. Data Rules
- The system must store products, clients, sales invoices, invoice lines, receipts, expenses, partial sales returns, return lines, attachment metadata, device records, sync cursors, conflict logs, audit events, and explicit receipt allocation records.
- Product names must be unique.
- Client names are not globally unique. Each client must have a primary display name and at least one additional identifying field to distinguish duplicates in search and UI, such as phone number, note, or client code.
- Invoice discounts are allowed only at the invoice level, not the line level.
- Invoice line unit price defaults from the product record but may be changed during invoice creation.
- Client balances must support both debtor and creditor states.
- The approved expense categories in MVP are: OWNER_DRAW, PARTNER_DRAW, MARGIN_DRAW, OPERATIONAL, PRODUCTION. Only OPERATIONAL and PRODUCTION are included in net profit calculation.
- Partial returns must be financial returns, not note-only markers.
- A partial return reduces the related invoice outstanding balance if unpaid amounts remain. If the invoice is already fully paid, the return creates a client credit balance. Cash refund workflows are out of scope in MVP.
- A partial return can be voided/cancelled, which requires a reason, audit history, and reversal of all accounting effects.
- Receivables in MVP mean active invoices with remaining unpaid balances.
- There are no invoice due dates and no payment terms in MVP. Receivables aging is based on invoice date and remaining unpaid balance.
- The system supports two receipt types: invoice-linked receipts and general client receipts (payment on account from the client page).
- General client receipts must be auto-allocated using FIFO to the client's oldest unpaid invoices first.
- FIFO receipt allocations must be stored explicitly. If an invoice is voided or reduced after allocation, affected allocations must be recalculated deterministically and re-applied to the client's oldest remaining unpaid invoices.
- Invoice editing is allowed as long as the invoice is not voided.
- If no receipts and no returns exist, invoice editing is unrestricted.
- If receipts exist, the new invoice total must not be lower than the amount already collected.
- If returns exist, only non-financial fields may be edited in MVP, such as notes and attachment metadata. Client, discount, invoice lines, quantities, and prices must not be edited.
- Profit reports must use invoice dates, return dates, and expense dates.
- Collection reports must use receipt dates.
- Every report and every client statement must support a custom date range with Start Date and End Date.
- Reports and client statements may additionally support quick filters such as Today, This Week, This Month, This Year, and All Time.
- Monthly profit share distribution must allocate integer-only shares to Owner and Partner, with any remainder assigned to The Margin.
- Balances for Owner, Partner, and The Margin may go negative with no minimum floor.
- All financial rows must keep created/updated timestamps, device origin, row version, sync state, and auditability fields.
- Receivables aging buckets are: Current, 1–30 days, 31–60 days, 61–90 days, 90+ days, based on invoice date and remaining unpaid balance.
- Fiscal year is the calendar year: January to December. No custom fiscal year in MVP.
- PDF export is required in MVP for every report and every client statement.
- PDF export must respect the currently selected filters, including custom Start Date and End Date ranges.
- PDF output must support Arabic content and correct RTL rendering.
- PDF export should work from local data whenever possible so that offline-first behavior is preserved.

### V. UX Rules
- Product creation, client creation, invoice creation, receipt entry, expense entry, return entry, and cancellation must work fully offline.
- Free-text product search/autocomplete is the primary way to build an invoice.
- Client selection is mandatory for each invoice.
- Invoice total must be computed automatically from lines and invoice-level discount.
- Paid amount may be full or partial. A receipt record must be created for any collected amount.
- History is first-class: invoices, expenses, receipts, returns, and client statements must be searchable and filterable by date and relevant entity.
- Dashboard is mandatory in MVP.
- Reports are mandatory in MVP, including sales, profit, expenses by type, client statement, receivables, party balances, and sales by product.
- All report screens and all client statement screens must provide Start Date and End Date filtering.
- Users must be able to generate a PDF copy for any report or client statement for the selected period.
- Void/cancel flows must require a reason and must preserve audit history.
- The MVP is Arabic-first. The UI must support full RTL layout from day one. English is not required in MVP.

### VI. Security Rules
- The client must never write directly to the cloud database without the approved sync/API path.
- All synced operations must be authenticated as the single owner account in MVP. Authentication uses Serverpod email and password authentication.
- All server-side writes and reads must validate record identity, row version, and conflict rules.
- Financial conflicts must be detected server-side and surfaced explicitly to the user for resolution.
- Sensitive logs must contain request IDs and safe metadata only. No full attachment contents, no secret values, and no unsafe payload dumps.
- Devices must be identifiable so the system can track sync origin and conflict source.
- File uploads must use secure server-approved upload flows. The database stores only attachment metadata and storage references.
- Data access must remain scoped to the single business entity in MVP and must be designed so future multi-tenant expansion is possible without breaking isolation.

## Governance
- **Definition of Done for any feature**:
  - Works fully offline and syncs correctly when connectivity returns.
  - Works correctly on both Android and Windows.
  - Preserves accounting correctness after create, edit, void, partial payment, partial return, and resync scenarios.
  - Preserves audit history for every financial mutation.
  - Includes local persistence, sync behavior, and conflict handling where applicable.
  - Produces correct results in reports, client statements, and dashboard summaries.
  - Avoids hard delete for financial records and verifies void behavior end-to-end.
  - Includes tests for calculation rules, balance effects, PDF generation correctness, and sync/conflict edge cases.

- **Amendment procedure**: Any change to this constitution must be documented with version bump, rationale, and impact assessment.
- **Versioning policy**: MAJOR for backward-incompatible governance changes, MINOR for new principles or material expansions, PATCH for clarifications.
- **Compliance review**: All feature specs and plans must pass a Constitution Check gate before implementation.

**Version**: 1.3.0 | **Ratified**: 2026-03-14 | **Last Amended**: 2026-03-16
