# Feature Specification: Products & Clients

**Feature Branch**: `004-products-clients`  
**Created**: 2026-04-05  
**Status**: Draft  
**Input**: Phase 4 from docs/implementation-plan.md — "Products & Clients: Complete the core reference data flows"

## Clarifications

### Session 2026-04-05

- Q: Should email and address count as valid identifying fields for the "at least one" rule, or only phone/note/client code? → A: Any of phone, email, address, note, or client code satisfies the rule.

## User Scenarios & Testing

### User Story 1 — Add a Product (Priority: P1)

The business owner opens the Products screen and taps "Add Product." They enter the product name, an optional description, a default sale price, a cost price, a unit label (e.g., "piece," "kg"), and optionally a SKU. On save, the product is persisted locally and appears immediately in the product list. The product is queued for sync to the server.

**Why this priority**: Products are the foundation for invoice line items. Without products, no invoices can be created. This is the most critical prerequisite for the commercial engine.

**Independent Test**: Open the app in airplane mode, create a product with name "عصير مانجو" and price 500.00 YER. Verify it appears in the product list. Toggle connectivity and verify it syncs to the server.

**Acceptance Scenarios**:

1. **Given** the owner is on the Products screen, **When** they tap "Add Product" and fill in name "عصير مانجو," default sale price 50000 (500.00 YER), unit "قطعة," and save, **Then** the product is stored locally with syncStatus PENDING and appears at the top of the product list.
2. **Given** a product with name "عصير مانجو" already exists, **When** the owner creates another product with the same name, **Then** the system shows an error message indicating the product name must be unique.
3. **Given** the owner leaves the name field empty, **When** they attempt to save, **Then** the system shows a validation error and does not save.
4. **Given** the owner enters a negative default sale price, **When** they attempt to save, **Then** the system shows a validation error.

---

### User Story 2 — Edit a Product (Priority: P1)

The owner selects an existing product from the list or detail screen and taps "Edit." They can change the name, description, default sale price, cost price, unit, or SKU. Changing the default sale price does not affect any existing invoice lines — it only sets the default for future invoice lines. The product name uniqueness constraint is still enforced (excluding the current product).

**Why this priority**: Products evolve — prices change, descriptions are corrected. Edit capability is essential for day-to-day operations.

**Independent Test**: Create a product, edit its name and price, save, and verify the updated values appear in the product list.

**Acceptance Scenarios**:

1. **Given** a product "عصير مانجو" exists with price 500.00 YER, **When** the owner edits the price to 600.00 YER and saves, **Then** the product shows 600.00 YER in the list and the change is queued for sync.
2. **Given** products "عصير مانجو" and "شاي أحمر" exist, **When** the owner edits "شاي أحمر" to have the name "عصير مانجو," **Then** the system shows a uniqueness error.
3. **Given** a product was synced (syncStatus SYNCED), **When** the owner edits it, **Then** the syncStatus changes to PENDING and a new outbox entry is created.

---

### User Story 3 — Disable a Product (Priority: P2)

The owner can mark a product as disabled (inactive). Disabled products no longer appear in invoice product search/autocomplete but remain visible in the product list with a clear "disabled" indicator. Disabled products already used in existing invoices continue to display correctly in those invoices. The owner can re-enable a disabled product at any time.

**Why this priority**: Seasonal or discontinued items need to be hidden from daily use without losing historical data.

**Independent Test**: Create a product, disable it, verify it doesn't appear in invoice autocomplete, then re-enable it and verify it reappears.

**Acceptance Scenarios**:

1. **Given** an active product "عصير مانجو," **When** the owner disables it, **Then** the product shows a disabled indicator in the product list and its isActive field is set to false.
2. **Given** a disabled product, **When** the owner searches for products while creating an invoice, **Then** the disabled product does not appear in the autocomplete results.
3. **Given** an existing invoice contains a disabled product, **When** the owner views that invoice, **Then** the disabled product's name and details are still displayed correctly.
4. **Given** a disabled product, **When** the owner re-enables it, **Then** it reappears in invoice product autocomplete.

---

### User Story 4 — Search Products (Priority: P1)

The owner can search/filter products by name from the product list screen. The search is local (runs on SQLite), works offline, and returns results as the owner types (live filtering). The search is case-insensitive and supports partial matches.

**Why this priority**: With many products, finding specific items quickly is essential for usability.

**Independent Test**: Create 50 products, type 3 characters in the search box, verify the list filters to show only matching products within 1 second.

**Acceptance Scenarios**:

1. **Given** products "عصير مانجو," "عصير برتقال," and "شاي أحمر" exist, **When** the owner types "عصير," **Then** only "عصير مانجو" and "عصير برتقال" appear.
2. **Given** no products match the search term, **When** the owner types "xyz," **Then** the list shows an empty state message.
3. **Given** the device is offline, **When** the owner searches, **Then** results still appear from local data.

---

### User Story 5 — Add a Client (Priority: P1)

The owner opens the Clients screen and taps "Add Client." They enter the client's display name (required) and at least one additional identifying field: phone number, email, address, note, or client code. On save, the client is persisted locally and queued for sync.

**Why this priority**: Clients are required for every invoice. This is a prerequisite for the commercial engine.

**Independent Test**: Open the app offline, create a client with name "أحمد محمد" and phone "777123456," verify the client appears in the client list.

**Acceptance Scenarios**:

1. **Given** the owner is on the Clients screen, **When** they tap "Add Client," enter name "أحمد محمد," phone "777123456," and save, **Then** the client is stored locally with syncStatus PENDING.
2. **Given** the owner enters only a name with no phone, email, address, note, or client code, **When** they attempt to save, **Then** the system shows a validation message requiring at least one additional identifying field.
3. **Given** two clients with name "أحمد محمد" already exist, **When** the owner creates a third client with the same name, **Then** the system allows it (client names are not unique) but the identifying fields help distinguish them in the list.

---

### User Story 6 — Edit a Client (Priority: P1)

The owner selects an existing client and taps "Edit." They can modify the display name, phone, email, address, note, or client code. Changes are saved locally and queued for sync.

**Why this priority**: Client information changes frequently — phone numbers, addresses, and notes are updated regularly.

**Independent Test**: Create a client, edit the phone number, save, verify the updated phone appears in the client detail.

**Acceptance Scenarios**:

1. **Given** a client "أحمد محمد" with phone "777123456," **When** the owner edits the phone to "777654321" and saves, **Then** the updated phone is shown and the change is queued for sync.
2. **Given** a client was synced, **When** the owner edits it, **Then** the syncStatus changes to PENDING.
3. **Given** a client has an existing note, **When** the owner clears all identifying fields (phone, email, address, note, client code become empty), **Then** the system shows a validation error requiring at least one identifying field.

---

### User Story 7 — Search Clients (Priority: P1)

The owner can search clients by name, phone number, or client code from the client list screen. The search is local, works offline, and provides live filtering as the owner types. When multiple clients share the same name, the list displays the distinguishing fields (phone, client code, note) alongside the name to help the owner identify the correct record.

**Why this priority**: Fast client lookup is essential for invoice creation and account management.

**Independent Test**: Create 3 clients named "أحمد" with different phone numbers, search "أحمد," verify all 3 appear with their distinguishing phone numbers visible.

**Acceptance Scenarios**:

1. **Given** clients "أحمد محمد (777111)" and "أحمد محمد (777222)" exist, **When** the owner types "أحمد," **Then** both clients appear with their phone numbers shown as distinguishing fields.
2. **Given** a client with code "C001," **When** the owner types "C001," **Then** that client appears in the results.
3. **Given** a client with phone "777123456," **When** the owner types "777123," **Then** that client appears in the results.

---

### User Story 8 — Client Summary (Priority: P2)

When the owner taps on a client in the list, they see a client summary screen showing the client's details, outstanding balance (total of unpaid invoices), and a brief history of recent transactions (invoices, receipts, returns) linked to this client.

**Why this priority**: Understanding a client's financial status at a glance improves daily business operations and decision-making.

**Independent Test**: Create a client, create 2 invoices for them, make a partial payment. Open the client summary and verify the balance is correct.

**Acceptance Scenarios**:

1. **Given** client "أحمد محمد" has 2 active invoices totaling 100,000 (1000.00 YER) and a receipt of 40,000 (400.00 YER), **When** the owner opens the client summary, **Then** the outstanding balance shows 60,000 (600.00 YER).
2. **Given** a client with no invoices, **When** the owner opens the client summary, **Then** the outstanding balance shows 0 and the transaction history is empty.
3. **Given** a client has a voided invoice, **When** the owner views the summary, **Then** the voided invoice does not contribute to the outstanding balance but may appear in the transaction history with a "voided" indicator.

---

### Edge Cases

- What happens when the owner creates a product with extremely long name (250+ characters)? The system should enforce a reasonable maximum length.
- What happens when two devices create the same product name simultaneously while offline? The sync engine should detect the duplicate name and surface a conflict.
- What happens when a product used in active invoices is disabled? Existing invoices remain unaffected; the product simply stops appearing in autocomplete for new invoices.
- What happens when the owner edits a client while another device also edits the same client? Auto-merge fields (displayName, phone, note, clientCode) merge via last-write-wins per the constitution. No conflict is raised for these fields.
- What happens when the owner searches with special characters or emoji? The search should handle them gracefully without crashing.
- What happens when there are 1000+ products? The product list should remain performant with local search returning results within 1 second.

## Requirements

### Functional Requirements

#### Products

- **FR-001**: System MUST allow the owner to create a new product with: name (required), description (optional), default sale price (required, non-negative), cost price (optional, non-negative), unit label (optional), SKU (optional).
- **FR-002**: System MUST enforce unique product names. Validation MUST occur locally before save and MUST be case-insensitive.
- **FR-003**: System MUST allow the owner to edit any product field. Name uniqueness MUST be re-validated on edit (excluding the current product).
- **FR-004**: System MUST NOT allow product deletion. Products may only be disabled (set isActive to false).
- **FR-005**: System MUST allow the owner to re-enable disabled products.
- **FR-006**: Disabled products MUST NOT appear in invoice product autocomplete/search.
- **FR-007**: Disabled products MUST still appear in the product management list with a clear visual indicator showing their disabled status.
- **FR-008**: System MUST provide live local search for products by name, returning results as the owner types.
- **FR-009**: All monetary values for products (defaultSalePrice, costPrice) MUST be stored as minor-unit integers (2 decimal places). Example: 500.00 YER = 50000.
- **FR-010**: Product creation and editing MUST work fully offline, saving to local SQLite and creating a sync outbox entry.
- **FR-011**: Product names MUST have a maximum length of 200 characters.
- **FR-012**: Product SKU, if provided, SHOULD be unique. The system MUST warn but MAY allow duplicate SKUs.

#### Clients

- **FR-013**: System MUST allow the owner to create a new client with: display name (required), phone (optional), email (optional), address (optional), note (optional), client code (optional).
- **FR-014**: System MUST require at least one identifying field (phone, email, address, note, or client code) in addition to the display name to help distinguish clients with the same name.
- **FR-015**: Client names are NOT required to be unique. Multiple clients MAY share the same display name.
- **FR-016**: System MUST allow the owner to edit any client field. The requirement for at least one identifying field MUST be re-validated on edit.
- **FR-017**: System MUST provide live local search for clients by display name, phone number, or client code.
- **FR-018**: When displaying clients with the same name, the system MUST show distinguishing fields (phone, client code, or note preview) alongside the name.
- **FR-019**: Client creation and editing MUST work fully offline, saving to local SQLite and creating a sync outbox entry.
- **FR-020**: System MUST display a client summary screen showing: client details, outstanding balance, and recent transaction history (invoices, receipts, returns).
- **FR-021**: Outstanding balance on the client summary MUST be computed on-read from active invoices and receipts — not stored as a cached field.
- **FR-022**: Client display name MUST have a maximum length of 200 characters.

#### Shared / Cross-Cutting

- **FR-023**: All product and client mutations MUST create a sync outbox entry for synchronization.
- **FR-024**: All product and client records MUST maintain created/updated timestamps, device origin, row version, and sync status fields.
- **FR-025**: Product and client list screens MUST support Arabic RTL layout.
- **FR-026**: Product and client forms MUST perform local validation before save and display clear Arabic error messages.

### Key Entities

- **Product**: Core reference entity representing something the business sells. Key attributes: name (unique), description, default sale price, cost price, unit, SKU, isActive flag, sync metadata.
- **Client**: Core reference entity representing a customer. Key attributes: display name (not unique), phone, email, address, note, client code, sync metadata. Outstanding balance is derived, not stored.

## Success Criteria

### Measurable Outcomes

- **SC-001**: Owner can create a product and see it in the list within 1 second, while fully offline.
- **SC-002**: Owner can create a client and see it in the list within 1 second, while fully offline.
- **SC-003**: Product search returns filtered results within 500 milliseconds for a list of up to 2000 products.
- **SC-004**: Client search returns filtered results within 500 milliseconds for a list of up to 2000 clients.
- **SC-005**: Duplicate product name is detected and rejected before save within 200 milliseconds.
- **SC-006**: Client summary screen loads and displays the correct outstanding balance within 2 seconds.
- **SC-007**: All product and client changes sync to the server within one sync cycle after connectivity is restored.
- **SC-008**: 100% of product and client screens render correctly in Arabic RTL layout.
- **SC-009**: Disabled products never appear in invoice autocomplete search results.
- **SC-010**: Clients with duplicate names are clearly distinguishable in all list views and search results.

## Assumptions

- The Drift local schema for Product and Client tables already exists from Phase 2 (002-core-data-model). This spec covers the application layer and UI, not the schema creation.
- The sync engine from Phase 3 (003-sync-foundation) is operational. Products and clients will use the existing outbox → push → pull pipeline without modifications to the sync layer.
- Auto-merge rules for client fields (displayName, phone, note, clientCode) and product fields (description, isActive) are already defined in the sync foundation FieldClassifier.
- The constitutional rule "product.name is conflict-required" means name changes on two devices will produce a conflict, not an auto-merge.
- Client outstanding balance is computed on-read using existing invoice and receipt data. This spec does not create invoices or receipts — it references them for the summary view. If no invoices exist yet, the balance simply shows zero.
- The "at least one identifying field" validation for clients is a UX rule enforced at the form level. The database schema does not enforce this constraint — it is an application-level validation.
