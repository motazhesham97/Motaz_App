# Feature Specification: Expenses & Monthly Profit Distribution

**Feature Branch**: `006-expenses-profit`  
**Created**: 2026-04-07  
**Status**: Draft  
**Input**: Phase 6 from `docs/implementation-plan.md` — Expenses & Monthly Profit Distribution

---

## User Scenarios & Testing

### User Story 1 — Record an Expense (Priority: P1) 🎯 MVP

The owner records a business expense by selecting one of the five approved categories, entering an amount, date, and optional note. The expense is saved locally and queued for sync.

**Why this priority**: Expenses are the foundational input to the profit engine. Without expenses, no profit calculation is possible.

**Independent Test**: While offline, create an expense under "OPERATIONAL" for 5,000 YER, verify it appears in the expense list with correct amount, category, and date.

**Acceptance Scenarios**:

1. **Given** the owner is on the expense form, **When** they select category "OPERATIONAL", enter 5,000 YER, set today's date, and tap save, **Then** the expense is persisted locally with status ACTIVE, appears in the expense list, and a sync outbox entry is created.
2. **Given** the owner is creating an expense, **When** they leave the amount empty or enter zero, **Then** the save is blocked with a validation error.
3. **Given** the owner is creating an expense, **When** they do not select a category, **Then** the save is blocked with a validation error.

---

### User Story 2 — Edit an Expense (Priority: P1)

The owner edits a previously created active expense to correct the category, amount, date, or note.

**Why this priority**: Data entry errors are common; the owner must be able to correct mistakes immediately.

**Independent Test**: Create an expense, edit its amount, verify the updated amount is reflected in the list and in profit calculations.

**Acceptance Scenarios**:

1. **Given** an active expense exists, **When** the owner opens it and changes the amount from 5,000 to 7,000 YER and saves, **Then** the expense amount is updated, `rowVersion` increments, `syncStatus` is set to PENDING, and an UPDATE outbox entry is created.
2. **Given** a voided expense exists, **When** the owner attempts to edit it, **Then** the edit option is not available or is blocked.

---

### User Story 3 — Void an Expense (Priority: P1)

The owner voids an expense that was entered in error. A reason is required. The expense remains in the system with VOIDED status.

**Why this priority**: Voiding is the only deletion mechanism; required for accounting correctness and audit trail.

**Independent Test**: Create an expense, void it with reason "duplicate entry", verify it shows as voided and is excluded from profit calculations.

**Acceptance Scenarios**:

1. **Given** an active expense exists, **When** the owner voids it with reason "duplicate entry", **Then** the expense status changes to VOIDED, the reason is stored, an UPDATE outbox entry is created, and the expense is excluded from all profit and report calculations.
2. **Given** the owner tries to void an expense without a reason, **Then** the void is blocked.
3. **Given** an already-voided expense, **When** the owner tries to void it again, **Then** the action is rejected.

---

### User Story 4 — View and Search Expenses (Priority: P1)

The owner views a list of all expenses, searches by category or note text, and sees voided expenses visually distinguished.

**Why this priority**: The owner needs to review and manage expenses to verify their records and audit spending.

**Independent Test**: Create 5 expenses across different categories, open the expense list, filter by category, and verify correct filtering and display.

**Acceptance Scenarios**:

1. **Given** multiple expenses exist, **When** the owner opens the expense list, **Then** expenses are displayed newest-first by expense date, showing category, amount, date, and status.
2. **Given** the owner enters a search query, **When** the query matches a category name or note, **Then** only matching expenses are shown with 300ms debounce.
3. **Given** voided expenses exist in the list, **Then** they are displayed with reduced opacity and a "ملغى" (voided) badge.

---

### User Story 5 — View Monthly Profit Report (Priority: P2)

The owner views the computed monthly profit for any given month. The system calculates net sales minus relevant expenses for the selected month.

**Why this priority**: The profit report drives the distribution engine that allocates shares to the three parties.

**Independent Test**: Create invoices totaling 50,000 YER and expenses totaling 15,000 YER (10,000 OPERATIONAL + 5,000 PRODUCTION) in the same month. Verify net profit shows 35,000 YER. Verify OWNER_DRAW, PARTNER_DRAW, and MARGIN_DRAW expenses are excluded from the profit calculation.

**Acceptance Scenarios**:

1. **Given** a month has net sales of 50,000 YER and profit-affecting expenses of 15,000 YER (OPERATIONAL + PRODUCTION only), **When** the owner views the monthly profit, **Then** net profit displays as 35,000 YER.
2. **Given** a month has OWNER_DRAW expenses of 3,000 YER, **When** the owner views the monthly profit, **Then** the draw is NOT subtracted from net profit (draws affect party balance only, not profit).
3. **Given** a month has no invoices, **When** the owner views the monthly profit, **Then** net profit displays as the negative of total profit-affecting expenses (net loss).

---

### User Story 6 — Distribute Monthly Profit (Priority: P2)

The owner triggers the monthly profit distribution for a completed month. The system splits net profit into three equal integer shares, assigning any remainder to The Margin.

**Why this priority**: This is the core accounting action that determines how profits are allocated to the three parties.

**Independent Test**: For a month with net profit of 100 YER (10,000 minor units), verify: Owner gets 3,333, Partner gets 3,333, Margin gets 3,334.

**Acceptance Scenarios**:

1. **Given** net profit for January 2026 is 100,000 minor units, **When** the owner distributes, **Then** Owner share = 33,333, Partner share = 33,333, Margin share = 33,334 (remainder to Margin).
2. **Given** net profit for a month is negative (net loss), **When** the owner distributes, **Then** all three parties receive negative shares (Owner and Partner get `trunc(loss/3)`, Margin receives the remainder).
3. **Given** a distribution already exists for a month, **When** the owner tries to distribute again, **Then** the action is blocked (one distribution per month).
4. **Given** no invoices and no expenses exist for a month, **When** the owner attempts distribution, **Then** the system creates a distribution with zero shares for all parties.

---

### User Story 7 — Record a Draw (Priority: P2)

The owner records a draw for Owner, Partner, or The Margin. A draw is an expense with one of the three draw categories.

**Why this priority**: Draws are the mechanism for parties to withdraw accumulated profits and must be tracked independently from operational expenses.

**Independent Test**: Record a 10,000 YER OWNER_DRAW, verify it appears as an expense, does NOT affect net profit, and reduces the Owner's party balance.

**Acceptance Scenarios**:

1. **Given** the owner creates an expense with category OWNER_DRAW for 10,000 YER, **When** saved, **Then** it is stored as a regular expense but is excluded from net profit calculation and deducted from the Owner's party balance.
2. **Given** the owner creates a PARTNER_DRAW, **Then** it deducts from Partner's balance only.
3. **Given** the owner creates a MARGIN_DRAW, **Then** it deducts from Margin's balance only.
4. **Given** the Owner's balance is 5,000 YER, **When** an OWNER_DRAW of 8,000 YER is created, **Then** the draw is allowed and the Owner's balance becomes -3,000 YER (negative balances are permitted).

---

### User Story 8 — View Party Balances (Priority: P2)

The owner views the current balance for Owner, Partner, and The Margin, calculated as accumulated monthly shares minus draws.

**Why this priority**: Party balances are essential for the owner to track what each party has earned and withdrawn.

**Independent Test**: After distributing profits for 2 months and recording draws, verify all three balances are calculated correctly.

**Acceptance Scenarios**:

1. **Given** distributions exist for January (30,000 each) and February (15,000 each), and OWNER_DRAW of 20,000 exists, **When** the owner views party balances, **Then** Owner = 25,000 (45,000 - 20,000), Partner = 45,000, Margin = 45,000 + any remainders.
2. **Given** no distributions and no draws exist, **When** the owner views party balances, **Then** all balances show 0.
3. **Given** a party has more draws than accumulated shares, **Then** that party's balance is displayed as a negative number.

---

### User Story 9 — Dashboard Expense and Profit Cards (Priority: P3)

The owner sees the following dashboard cards: This Month Net Profit, Owner Balance, Partner Balance, Margin Balance, and This Month Expense Summary by Type.

**Why this priority**: Dashboard cards provide at-a-glance financial status but are presentation-only — the underlying data comes from US5–US8.

**Independent Test**: Create expenses and distributions for the current month, verify the dashboard cards show correct computed values.

**Acceptance Scenarios**:

1. **Given** the current month has net sales of 100,000 YER and expenses of 30,000 YER (OPERATIONAL + PRODUCTION), **When** the owner views the dashboard, **Then** the "This Month Net Profit" card shows 70,000 YER.
2. **Given** the current month has 5,000 OPERATIONAL + 3,000 PRODUCTION + 2,000 OWNER_DRAW, **When** the owner views the expense summary card, **Then** it shows a breakdown by all 5 categories with correct amounts.
3. **Given** distributions exist for multiple months, **When** the owner views the dashboard, **Then** Owner, Partner, and Margin balance cards reflect the cumulative balance (shares minus draws).

---

### Edge Cases

- What happens when a distribution is created and then an invoice for that month is voided? The distribution remains unchanged — redistributions are not auto-triggered. The owner must manually void and recreate the distribution if needed.
- What happens when the net profit for a month is exactly 0? Distribution creates zero shares for all three parties.
- What happens when the net profit is 1 minor unit? Owner = 0, Partner = 0, Margin = 1.
- What happens when an expense is voided after a distribution is created for that month? The distribution is NOT automatically recalculated. The owner must void the distribution and create a new one to reflect the change.
- What happens when there are active returns in a month? Returns reduce net sales, which reduces net profit. The formula accounts for this: Net Sales = Active Invoice Totals − Discounts − Active Financial Returns.

---

## Requirements

### Functional Requirements

#### Expense Management

- **FR-001**: System MUST allow the owner to create an expense with: category (required), amount (required, positive integer in minor units), expense date (required), and note (optional).
- **FR-002**: System MUST restrict expense categories to exactly five values: OPERATIONAL, PRODUCTION, OWNER_DRAW, PARTNER_DRAW, MARGIN_DRAW.
- **FR-003**: System MUST persist every expense with: id (UUID), category, amount, expenseDate, note, status (ACTIVE/VOIDED), voidReason, createdAt, updatedAt, deviceId, rowVersion, and syncStatus.
- **FR-004**: System MUST create a sync outbox entry (operation: CREATE) within the same atomic transaction as the expense insert.
- **FR-005**: System MUST allow the owner to edit an active expense's category, amount, date, and note.
- **FR-006**: System MUST NOT allow editing a voided expense.
- **FR-007**: System MUST increment rowVersion and set syncStatus to PENDING on every edit, and create a sync outbox entry (operation: UPDATE).
- **FR-008**: System MUST allow the owner to void an active expense with a required reason string.
- **FR-009**: System MUST NOT allow voiding an already-voided expense.
- **FR-010**: System MUST set expense status to VOIDED, store the reason, increment rowVersion, set syncStatus to PENDING, and create a sync outbox entry (operation: UPDATE) — all within a single atomic transaction.
- **FR-011**: System MUST NOT hard-delete any expense record.

#### Expense Display

- **FR-012**: System MUST display expenses in a list ordered by expenseDate descending, then createdAt descending.
- **FR-013**: System MUST allow searching/filtering expenses by category name or note text.
- **FR-014**: System MUST apply a 300ms debounce to expense search.
- **FR-015**: System MUST visually distinguish voided expenses (reduced opacity, "ملغى" badge).
- **FR-016**: System MUST display category labels in Arabic: تشغيلي (OPERATIONAL), إنتاج (PRODUCTION), سحب مالك (OWNER_DRAW), سحب شريك (PARTNER_DRAW), سحب هامش (MARGIN_DRAW).

#### Profit Calculation

- **FR-017**: System MUST compute monthly net sales as: sum of active invoice totals for the month minus sum of active financial return amounts for the month.
- **FR-018**: System MUST compute monthly net profit as: monthly net sales minus sum of active OPERATIONAL expenses for the month minus sum of active PRODUCTION expenses for the month.
- **FR-019**: System MUST exclude OWNER_DRAW, PARTNER_DRAW, and MARGIN_DRAW expenses from net profit calculation.
- **FR-020**: System MUST use invoice dates for sales calculations, return dates for return calculations, and expense dates for expense calculations.

#### Profit Distribution

- **FR-021**: System MUST allow the owner to distribute monthly profit for any completed month.
- **FR-022**: System MUST compute distribution as: `owner_share = trunc(net_profit / 3)`, `partner_share = trunc(net_profit / 3)`, `margin_share = net_profit - owner_share - partner_share`.
- **FR-023**: System MUST handle negative net profit (net loss): all three parties receive negative shares, with remainder (closest to zero) assigned to Margin.
- **FR-024**: System MUST block duplicate distributions for the same year-month.
- **FR-025**: System MUST persist each distribution with: id (UUID), year, month, netProfit, ownerShare, partnerShare, marginShare, createdAt, updatedAt, deviceId, rowVersion, syncStatus.
- **FR-026**: System MUST create a sync outbox entry for each distribution within the same atomic transaction.
- **FR-027**: System MUST allow voiding a distribution with a required reason, reversing the shares. Voiding a distribution does NOT automatically redistribute — it simply removes the shares.

#### Party Balances

- **FR-028**: System MUST compute Owner balance as: sum of ownerShare from all ACTIVE distributions minus sum of ACTIVE OWNER_DRAW expense amounts.
- **FR-029**: System MUST compute Partner balance as: sum of partnerShare from all ACTIVE distributions minus sum of ACTIVE PARTNER_DRAW expense amounts.
- **FR-030**: System MUST compute Margin balance as: sum of marginShare from all ACTIVE distributions minus sum of ACTIVE MARGIN_DRAW expense amounts.
- **FR-031**: System MUST allow party balances to go negative with no minimum floor.
- **FR-032**: System MUST display party balances in a dedicated screen and on dashboard cards.

#### Dashboard Cards

- **FR-033**: System MUST display a "This Month Net Profit" card on the dashboard showing the computed net profit for the current calendar month.
- **FR-034**: System MUST display "Owner Balance", "Partner Balance", and "Margin Balance" cards on the dashboard.
- **FR-035**: System MUST display a "This Month Expense Summary by Type" card showing a breakdown of current month's active expenses across all 5 categories.

### Key Entities

- **Expense**: A monetary business expense categorized into one of five types. Contains category, amount (minor-unit int), expenseDate, note, status, voidReason, and audit fields.
- **MonthlyDistribution**: A record of the profit split for a specific year-month. Contains year, month, netProfit, ownerShare, partnerShare, marginShare, status, and audit fields.
- **Party Balance** (computed, not stored): Derived value for each of the three parties calculated as accumulated distribution shares minus draws.

---

## Success Criteria

### Measurable Outcomes

- **SC-001**: Owner can create, edit, and void an expense in under 30 seconds each, fully offline.
- **SC-002**: Monthly profit calculation is deterministic — running it twice for the same month always produces the same result.
- **SC-003**: Profit distribution for a month with net profit of 100,000 minor units produces exactly: Owner 33,333 + Partner 33,333 + Margin 33,334 = 100,000 (no rounding loss).
- **SC-004**: Party balances are computed correctly after any combination of distributions and draws, including negative balance scenarios.
- **SC-005**: All expense and distribution mutations create sync outbox entries atomically — no orphaned writes.
- **SC-006**: Dashboard expense and profit cards update within 1 second of any underlying data change.
- **SC-007**: All monetary displays use YER format with 2 decimal places; no floating-point artifacts visible.

---

## Assumptions

- The fiscal year is the calendar year (January–December) per the constitution.
- "Completed month" for distribution purposes means any past or current month — the system does not enforce waiting until month-end.
- The MonthlyDistribution entity does not exist yet in the Drift schema and must be added as part of this feature.
- Returns affect net sales per the formula in the implementation plan, even though the Returns feature (Phase 7) is not yet implemented. The profit calculation queries should account for the returns table even if it is currently empty.
- Expense categories are stored as an enum index. No new categories can be added without a code change.

---

## Clarifications

_(None at this time — all business rules are explicitly defined in the constitution and implementation plan.)_
