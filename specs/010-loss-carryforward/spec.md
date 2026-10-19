# Monthly Loss Carryforward

Date: 2026-10-19. Constitution: 1.4.0. Owner-approved starting point: empty business database, no legacy distributions or loss conversion.

## Rules

- All money is integer minor units. Invoice total already includes its discount; subtract returns once by return date.
- operatingProfit = netSales - operationalExpenses - productionExpenses.
- currentMonthLoss = min(operatingProfit, 0).
- netProfit = operatingProfit + carriedLossIn (loss values are nonpositive).
- carriedLossOut = min(netProfit, 0); distributable = max(netProfit, 0).
- Owner and partner receive (distributable ~/ 3 ~/ 1000) * 1000 each; margin receives the remainder. All shares are nonnegative.
- A zero/loss month is an approved monthly settlement with three zero shares. Draws and party additions do not change profit.
- Months are continuous from the first financial activity/settlement; missing completed months are settled oldest-first. Empty months preserve carry. December continues into January.
- Current/future months are preview-only. Reading reports never creates settlements or outbox entries.
- Editing dated financial sources or voiding a settlement makes affected approved months require review. Preserve approved values until explicit reapproval, oldest-first, as chosen by the owner. Note/client/receipt-only changes do not trigger profit reapproval.
- Auto settlement pauses on stale/voided settlements or unresolved financial sync operations/conflicts. Manual offline settlement remains supported.
- A full-month report includes carry; nonmonthly reports show period operating result without repeatedly deducting monthly carry. They do not create shares.

## Storage / Safety

Extend MonthlyDistribution in Drift and Serverpod with netSales, operationalExpenses, productionExpenses, profitBeforeCarry, currentMonthLoss, carriedLossIn, carriedLossOut. Compare financial snapshots and chronology to derive review state, including after pulls/restores. A global loss balance is not used.

Save the settlement, audit before/after and outbox atomically. Existing deterministic month IDs and unique year/month constraints remain. Identical repeated monthly CREATE is idempotent; differing CREATE is an explicit conflict. Backend checks snapshot arithmetic, signs, rounding, and calendar values. Deploy matching generated server/client models and upgrade both devices together.

## Acceptance

1. Operating results -5000, -2000, +4000, +8000 produce closing carry -5000, -7000, -3000, 0 and distributable 0, 0, 0, 5000.
2. Previous carry -1000 plus operating +1000 produces net zero and three zero shares.
3. A loss-only month persists offline and survives reopening; successful retry never doubles its loss.
4. A past edit shows pending review, keeps previous approved shares, pauses new automatic settlement, and explicit reapproval updates the chronological chain and party balances.
5. Discounts apply once; returns and voids affect the correct month. Reports, dashboard, and final PDF agree for a full month.
6. A second device creating the same month with different figures produces a conflict; restore detects changed loss fields.
