# Data Model: Sync Foundation

**Date**: 2026-04-04  
**Feature**: 003-sync-foundation

---

## Existing Entities (Phase 2 — No Schema Changes Required)

Phase 2 already delivered all 16 Drift tables and 16 Serverpod models. The sync foundation phase does **not** add new database entities. All required tables/models already exist:

| Entity | Phase 2 Status | Sync Role |
|--------|---------------|-----------|
| **SyncOutbox** | ✅ Complete | Mutation queue: entity type, entity ID, operation, payload, row version, device ID, retry count, status, createdAt |
| **SyncCursor** | ✅ Complete | Pull cursor: entity type, last row version, last pulled timestamp, updatedAt |
| **ConflictLog** | ✅ Complete | Conflict record: both payloads, conflict type, resolution status, device ID |
| **Device** | ✅ Complete | Device identity: UUID, device code, platform, device name, next invoice sequence |
| **AttachmentMetadata** | ✅ Complete | Cloud reference: parent entity type/ID, storage reference, secure URL |
| **LocalAttachmentStaging** | ✅ Complete | Upload queue: parent entity type/ID, local file path, upload status |
| **AuditEvent** | ✅ Complete | Immutable log: entity type/ID, operation, diff data, device ID |

### Enums Used by Sync

| Enum | Values | Usage |
|------|--------|-------|
| **SyncStatus** | PENDING, SYNCED, CONFLICT, FAILED | Per-entity sync state on financial rows |
| **SyncOutboxStatus** | PENDING, IN_PROGRESS, COMPLETED, FAILED | Outbox entry lifecycle |
| **ParentEntityType** | SALES_INVOICE, RECEIPT, PRODUCT, CLIENT, EXPENSE, SALES_RETURN | Polymorphic FK for outbox, cursor, conflict, audit, attachment |
| **AuditOperation** | CREATE, UPDATE, VOID | Operation type in outbox and audit |
| **ConflictStatus** | PENDING, RESOLVED | Conflict lifecycle |
| **RecordStatus** | ACTIVE, VOIDED | Financial record void state |

---

## New Application-Layer Models (No Database Tables)

These are Dart-only runtime models that live in the sync feature module. They are **not** persisted to the database — they are used for coordinator state, endpoint payloads, and UI state.

### SyncState (Runtime State)

Represents the current state of the sync coordinator for UI consumption.

| Field | Type | Description |
|-------|------|-------------|
| status | `SyncPhase` | idle, pushing, pulling, error |
| pendingCount | int | Number of PENDING + IN_PROGRESS outbox entries |
| lastSyncedAt | DateTime? | Timestamp of last successful full cycle |
| errorMessage | String? | Human-readable error from last failure |
| unresolvedConflictCount | int | Number of PENDING ConflictLog records |

### SyncPhase (Enum — App Layer Only)

| Value | Meaning |
|-------|---------|
| idle | No sync in progress |
| pushing | Push cycle active |
| pulling | Pull cycle active |
| error | Last cycle failed |

### PushRequest (Endpoint Payload)

Sent from client to server for each outbox entry.

| Field | Type | Description |
|-------|------|-------------|
| outboxId | UUID | SyncOutbox entry ID |
| entityType | ParentEntityType | Which entity table |
| entityId | UUID | The entity's PK |
| operation | AuditOperation | CREATE, UPDATE, VOID |
| payload | String (JSON) | Full entity snapshot |
| rowVersion | int | Local row version |
| deviceId | UUID | Originating device |

### PushResponse (Endpoint Response)

Returned from server after processing a push.

| Field | Type | Description |
|-------|------|-------------|
| success | bool | Whether push was accepted |
| newRowVersion | int? | Server-assigned row version (if accepted) |
| conflictId | UUID? | ConflictLog ID (if conflict emitted) |
| errorCode | String? | Error code (if rejected) |
| errorMessage | String? | Human-readable error (if rejected) |

### PullRequest (Endpoint Payload)

Sent from client to server to request changes.

| Field | Type | Description |
|-------|------|-------------|
| entityType | ParentEntityType | Which entity table to pull |
| sinceRowVersion | int | Cursor position — return rows with version > this |
| deviceId | UUID | Requesting device |
| limit | int | Max rows per page (default 100) |

### PullResponse (Endpoint Response)

Returned from server with changed rows.

| Field | Type | Description |
|-------|------|-------------|
| entityType | ParentEntityType | Which entity table |
| rows | List\<Map\<String, dynamic>> | Changed entity rows as JSON |
| conflicts | List\<ConflictPayload> | Any new conflicts detected during server-side processing |
| hasMore | bool | Whether more pages exist |
| latestRowVersion | int | Highest row version in this response |

### ConflictPayload (Nested in PullResponse)

| Field | Type | Description |
|-------|------|-------------|
| entityType | ParentEntityType | Entity type |
| entityId | UUID | Entity PK |
| localPayload | String (JSON) | The device's version |
| remotePayload | String (JSON) | The server's version |
| conflictType | String | Description of conflict (e.g., "amount_mismatch") |

### DeviceRegistrationRequest (Endpoint Payload)

Sent on first sync to register the device.

| Field | Type | Description |
|-------|------|-------------|
| deviceId | UUID | Device UUID |
| deviceCode | String | 4-char hex code |
| platform | DevicePlatform | ANDROID or WINDOWS |
| deviceName | String | OS hostname |

### AttachmentUploadRequest (Endpoint Payload)

Sent to request upload approval.

| Field | Type | Description |
|-------|------|-------------|
| parentEntityType | ParentEntityType | SALES_INVOICE or RECEIPT |
| parentEntityId | UUID | Parent record PK |
| fileType | String | MIME type (e.g., image/jpeg) |
| fileSize | int | File size in bytes |

### AttachmentUploadApproval (Endpoint Response)

Returned with signed upload credentials.

| Field | Type | Description |
|-------|------|-------------|
| approved | bool | Whether upload is allowed |
| uploadUrl | String? | Signed Cloudinary upload URL |
| uploadPreset | String? | Cloudinary upload preset |
| rejectionReason | String? | Why rejected (if not approved) |

---

## Field Classification: Auto-Merge vs Conflict-Required

### Auto-Merge Fields (Last-Write-Wins, No Conflict Record)

| Entity | Fields |
|--------|--------|
| Client | displayName, phone, note, clientCode |
| Product | description, isActive |
| SalesInvoice | note |
| Receipt | note |
| Expense | note |
| SalesReturn | note |
| AttachmentMetadata | all fields except parentEntityType, parentEntityId |

### Conflict-Required Fields (Must Emit ConflictLog)

| Entity | Fields |
|--------|--------|
| Product | name, defaultSalePrice |
| SalesInvoice | clientId, invoiceDate, discount, total, status, voidReason |
| SalesInvoiceLine | invoiceId, productId, quantity, unitPrice, lineTotal |
| Receipt | receiptType, clientId, invoiceId, amount, receiptDate, status, voidReason |
| ReceiptAllocation | receiptId, invoiceId, allocatedAmount |
| Expense | category, amount, expenseDate, status, voidReason |
| SalesReturn | invoiceId, returnDate, totalReturnedAmount, status, voidReason |
| SalesReturnLine | returnId, invoiceLineId, returnedQuantity, returnedAmount |

---

## State Transitions

### Outbox Entry Lifecycle

```
PENDING → IN_PROGRESS → COMPLETED
                      → FAILED (retryable: back to PENDING on next retry)
                      → FAILED (permanent: stays FAILED until manual retry)
```

### Entity SyncStatus Lifecycle

```
PENDING (new/modified locally, not yet pushed)
  → SYNCED (push accepted, server confirmed)
  → CONFLICT (push rejected, conflict emitted)
  → FAILED (push permanently failed)
```

### Conflict Lifecycle

```
PENDING (created during push/pull)
  → RESOLVED (owner chose a version)
```

### Attachment Staging Lifecycle

```
PENDING (file selected offline)
  → UPLOADING (upload in progress)
  → UPLOADED (Cloudinary confirmed)
  → FAILED (upload failed, awaiting retry)
```
