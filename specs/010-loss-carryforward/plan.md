# Implementation Plan

Use existing Riverpod, Drift and Serverpod layers. No new runtime dependencies. Fresh database assumption removes legacy policy conversion.

1. Pure MonthlyProfit value and focused arithmetic test.
2. Add snapshot/loss columns, Drift v13 upgrade and generated Serverpod migration/client.
3. Read-only local timeline, atomic chronological settlement, explicit reapproval and audit/outbox tests.
4. Financial conflict classification, duplicate CREATE protection and server arithmetic validation tests.
5. Reactive settlement UI, dashboard and monthly reports/PDF; fix returns, monthly boundaries and duplicate daily discount.
6. Focused tests after each file; final relevant Flutter/server regression suites. Keep analyze/format manual. Never run tests against production Neon.

Deployment: prepare additive migration and matching clients; actual production deployment is a separate operation. Upgrade both devices together before syncing the new schema.
