# Progress

- [x] Specify fresh database assumption and accounting rules.
- [x] Pure arithmetic and focused tests.
- [x] Local/server schema and generated migration (prepared, not applied to PostgreSQL).
- [x] Timeline, settlement, explicit reapproval, persistence and focused tests.
- [x] Sync/server validation, contracts and actual local PostgreSQL endpoint tests.
- [x] UI, dashboard, reports and PDF; focused widget tests and rendered PDF inspection.
- [x] Regression verification and release instructions (88 Flutter tests, 26 backend tests; debug bundle compiled).
- [x] Apply and verify migration on isolated PostgreSQL; exercise chronological validation, replay/conflict and audit rollback.
- [ ] Multi-connection concurrency stress testing beyond sequential duplicate/replay cases.
- [ ] Android/Windows two-device offline/reconnect and reapproval acceptance run.
- [ ] Production rollout with the additive migration and matching device versions (separate authorization).

Verification details and manual commands: docs/reviews/loss-carryforward-implementation-2026-10-19.md.

No production Neon operations, deployment, analyze or format commands were performed.
