# Endpoint Contracts: Sync Foundation

**Date**: 2026-04-04  
**Feature**: 003-sync-foundation

All endpoints are Serverpod-style class methods on endpoint classes. Authentication is required for all sync endpoints (owner's session).

---

## 1. DeviceEndpoint

### `registerDevice(DeviceRegistrationRequest request) → DeviceRegistrationResponse`

**Purpose**: Register or update a device identity on the server.

| Aspect | Detail |
|--------|--------|
| Auth | Required (owner session) |
| Method | Serverpod endpoint call |
| Idempotent | Yes — re-registration updates `lastActiveAt` |

**Request**: `DeviceRegistrationRequest` (deviceId, deviceCode, platform, deviceName)

**Response**:
```
DeviceRegistrationResponse {
  bool success
  String? errorMessage
}
```

**Error Conditions**:
- Unauthenticated → 401
- Invalid device data → 400

---

## 2. SyncEndpoint

### `push(PushRequest request) → PushResponse`

**Purpose**: Push a single outbox mutation to the server.

| Aspect | Detail |
|--------|--------|
| Auth | Required (owner session) |
| Idempotent | Yes — same outboxId re-push is accepted if already processed |
| Conflict behavior | Row version mismatch triggers conflict detection per field classification |

**Request**: `PushRequest` (outboxId, entityType, entityId, operation, payload, rowVersion, deviceId)

**Response**:
```
PushResponse {
  bool success
  int? newRowVersion       // assigned by server if accepted
  String? conflictId       // ConflictLog UUID if conflict emitted
  String? errorCode        // e.g., "ROW_VERSION_MISMATCH", "VOID_WINS", "VALIDATION_ERROR"
  String? errorMessage
}
```

**Server Logic**:
1. Validate device identity exists and matches authenticated session.
2. Check if outboxId was already processed (idempotency key) → return cached response.
3. Load current server entity by entityId.
4. Compare rowVersion:
   - Match → accept write, increment server row version, return `newRowVersion`.
   - Mismatch → classify changed fields:
     - All changes on auto-merge fields → apply last-write-wins, return success.
     - Any change on conflict-required field → check void-wins rule:
       - If one version is VOIDED → apply void-wins, return success with void applied.
       - Else → emit ConflictLog, return `conflictId`.
5. Write AuditEvent for the mutation.
6. Return PushResponse.

**Error Conditions**:
- Unauthenticated → 401
- Unknown device → 403
- Invalid payload / missing fields → 400 (non-retryable)
- Server internal error → 500 (retryable)

---

### `pull(PullRequest request) → PullResponse`

**Purpose**: Pull changed rows for an entity type since the client's cursor position.

| Aspect | Detail |
|--------|--------|
| Auth | Required (owner session) |
| Pagination | Cursor-based, max `limit` rows per response |

**Request**: `PullRequest` (entityType, sinceRowVersion, deviceId, limit)

**Response**:
```
PullResponse {
  ParentEntityType entityType
  List<Map<String, dynamic>> rows     // entity rows as JSON
  List<ConflictPayload> conflicts     // new conflicts for this device
  bool hasMore                        // pagination continuation
  int latestRowVersion                // highest row version in response
}
```

**Server Logic**:
1. Validate device identity.
2. Query entity table for rows with `rowVersion > sinceRowVersion`, ordered by rowVersion ASC, limited to `limit`.
3. Query ConflictLog for unresolved conflicts for `deviceId` and `entityType` created since last pull.
4. Return rows + conflicts + pagination flag.

**Error Conditions**:
- Unauthenticated → 401
- Unknown entity type → 400
- Server error → 500

---

### `resolveConflict(ConflictResolutionRequest request) → ConflictResolutionResponse`

**Purpose**: Owner resolves a pending conflict by choosing local or remote version.

| Aspect | Detail |
|--------|--------|
| Auth | Required (owner session) |
| Idempotent | Yes — resolving an already-resolved conflict returns the existing resolution |

**Request**:
```
ConflictResolutionRequest {
  String conflictId          // ConflictLog UUID
  String chosenVersion       // "local" or "remote"
}
```

**Response**:
```
ConflictResolutionResponse {
  bool success
  int? newRowVersion          // server row version after resolution applied
  String? errorMessage
}
```

**Server Logic**:
1. Load ConflictLog by ID.
2. If already RESOLVED → return cached result.
3. Apply chosen version:
   - "local" → overwrite server entity with local payload, increment row version.
   - "remote" → keep server entity as-is, return current row version.
4. Mark ConflictLog as RESOLVED with resolution timestamp and chosen version.
5. Write AuditEvent for the resolution.
6. Return response.

---

## 3. AttachmentEndpoint

### `requestUploadApproval(AttachmentUploadRequest request) → AttachmentUploadApproval`

**Purpose**: Request server approval and signed URL for Cloudinary upload.

| Aspect | Detail |
|--------|--------|
| Auth | Required (owner session) |
| Validation | File type must be image/jpeg, image/png, or application/pdf. Max size: 10MB. Parent entity must exist. |

**Request**: `AttachmentUploadRequest` (parentEntityType, parentEntityId, fileType, fileSize)

**Response**:
```
AttachmentUploadApproval {
  bool approved
  String? uploadUrl          // signed Cloudinary URL
  String? uploadPreset       // Cloudinary upload preset
  String? rejectionReason
}
```

---

### `confirmUpload(AttachmentConfirmRequest request) → AttachmentConfirmResponse`

**Purpose**: Confirm a successful Cloudinary upload and store the reference.

**Request**:
```
AttachmentConfirmRequest {
  String parentEntityType
  String parentEntityId
  String publicId             // Cloudinary public_id
  String secureUrl            // Cloudinary secure_url
  String fileType
  int fileSize
}
```

**Response**:
```
AttachmentConfirmResponse {
  bool success
  String? attachmentMetadataId    // created AttachmentMetadata UUID
  String? errorMessage
}
```

**Server Logic**:
1. Validate parent entity exists and is not voided (but still link if voided per constitution — void preserves attachments).
2. Create AttachmentMetadata row with Cloudinary reference.
3. Write AuditEvent.
4. Return response.

---

## Endpoint Summary

| Endpoint | Method | Purpose |
|----------|--------|---------|
| DeviceEndpoint | registerDevice | Register/update device identity |
| SyncEndpoint | push | Push one outbox mutation |
| SyncEndpoint | pull | Pull changed rows since cursor |
| SyncEndpoint | resolveConflict | Owner resolves a conflict |
| AttachmentEndpoint | requestUploadApproval | Get signed Cloudinary upload URL |
| AttachmentEndpoint | confirmUpload | Confirm upload and store reference |
