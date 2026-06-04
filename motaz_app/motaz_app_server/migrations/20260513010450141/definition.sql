BEGIN;

--
-- Function: gen_random_uuid_v7()
-- Source: https://gist.github.com/kjmph/5bd772b2c2df145aa645b837da7eca74
-- License: MIT (copyright notice included on the generator source code).
--
create or replace function gen_random_uuid_v7()
returns uuid
as $$
begin
  -- use random v4 uuid as starting point (which has the same variant we need)
  -- then overlay timestamp
  -- then set version 7 by flipping the 2 and 1 bit in the version 4 string
  return encode(
    set_bit(
      set_bit(
        overlay(uuid_send(gen_random_uuid())
                placing substring(int8send(floor(extract(epoch from clock_timestamp()) * 1000)::bigint) from 3)
                from 1 for 6
        ),
        52, 1
      ),
      53, 1
    ),
    'hex')::uuid;
end
$$
language plpgsql
volatile;

--
-- Class AttachmentMetadata as table attachment_metadata
--
CREATE TABLE "attachment_metadata" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "parentEntityType" text NOT NULL,
    "parentEntityId" uuid NOT NULL,
    "storageReference" text NOT NULL,
    "secureUrl" text,
    "fileType" text NOT NULL,
    "fileSize" bigint,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deviceId" uuid NOT NULL,
    "rowVersion" bigint NOT NULL DEFAULT 1,
    "syncStatus" text NOT NULL DEFAULT 'PENDING'::text
);

-- Indexes
CREATE INDEX "attachment_parent_idx" ON "attachment_metadata" USING btree ("parentEntityType", "parentEntityId");

--
-- Class AuditEvent as table audit_event
--
CREATE TABLE "audit_event" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "entityType" text NOT NULL,
    "entityId" uuid NOT NULL,
    "operation" text NOT NULL,
    "diffData" text NOT NULL,
    "deviceId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "audit_entity_idx" ON "audit_event" USING btree ("entityType", "entityId");
CREATE INDEX "audit_created_idx" ON "audit_event" USING btree ("createdAt");

--
-- Class ClientRecord as table client
--
CREATE TABLE "client" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "displayName" text NOT NULL,
    "phone" text,
    "email" text,
    "address" text,
    "note" text,
    "clientCode" text,
    "isActive" boolean NOT NULL DEFAULT true,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deviceId" uuid NOT NULL,
    "rowVersion" bigint NOT NULL DEFAULT 1,
    "syncStatus" text NOT NULL DEFAULT 'PENDING'::text
);

-- Indexes
CREATE INDEX "client_display_name_idx" ON "client" USING btree ("displayName");

--
-- Class ConflictLog as table conflict_log
--
CREATE TABLE "conflict_log" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "entityType" text NOT NULL,
    "entityId" uuid NOT NULL,
    "localPayload" text NOT NULL,
    "remotePayload" text NOT NULL,
    "conflictType" text NOT NULL,
    "resolutionStatus" text NOT NULL DEFAULT 'PENDING'::text,
    "resolvedAt" timestamp without time zone,
    "resolutionData" text,
    "createdAt" timestamp without time zone NOT NULL,
    "deviceId" uuid NOT NULL
);

-- Indexes
CREATE INDEX "conflict_entity_idx" ON "conflict_log" USING btree ("entityType", "entityId");
CREATE INDEX "conflict_status_idx" ON "conflict_log" USING btree ("resolutionStatus");

--
-- Class Device as table device
--
CREATE TABLE "device" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "deviceName" text NOT NULL,
    "platform" text NOT NULL,
    "deviceCode" text NOT NULL,
    "nextInvoiceSequence" bigint NOT NULL DEFAULT 1,
    "nextReceiptSequence" bigint NOT NULL DEFAULT 1,
    "nextReturnSequence" bigint NOT NULL DEFAULT 1,
    "createdAt" timestamp without time zone NOT NULL,
    "lastActiveAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "device_code_idx" ON "device" USING btree ("deviceCode");

--
-- Class Expense as table expense
--
CREATE TABLE "expense" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "category" text NOT NULL,
    "amount" bigint NOT NULL,
    "expenseDate" timestamp without time zone NOT NULL,
    "note" text,
    "status" text NOT NULL DEFAULT 'ACTIVE'::text,
    "voidReason" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deviceId" uuid NOT NULL,
    "rowVersion" bigint NOT NULL DEFAULT 1,
    "syncStatus" text NOT NULL DEFAULT 'PENDING'::text
);

-- Indexes
CREATE INDEX "expense_date_idx" ON "expense" USING btree ("expenseDate");
CREATE INDEX "expense_category_idx" ON "expense" USING btree ("category");
CREATE INDEX "expense_status_idx" ON "expense" USING btree ("status");

--
-- Class LocalAttachmentStaging as table local_attachment_staging
--
CREATE TABLE "local_attachment_staging" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "parentEntityType" text NOT NULL,
    "parentEntityId" uuid NOT NULL,
    "localFilePath" text NOT NULL,
    "fileType" text NOT NULL,
    "fileSize" bigint,
    "uploadStatus" text NOT NULL DEFAULT 'PENDING'::text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "staging_upload_status_idx" ON "local_attachment_staging" USING btree ("uploadStatus");

--
-- Class MonthlyDistribution as table monthly_distribution
--
CREATE TABLE "monthly_distribution" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "year" bigint NOT NULL,
    "month" bigint NOT NULL,
    "netProfit" bigint NOT NULL,
    "ownerShare" bigint NOT NULL,
    "partnerShare" bigint NOT NULL,
    "marginShare" bigint NOT NULL,
    "status" text NOT NULL DEFAULT 'ACTIVE'::text,
    "voidReason" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deviceId" uuid NOT NULL,
    "rowVersion" bigint NOT NULL DEFAULT 1,
    "syncStatus" text NOT NULL DEFAULT 'PENDING'::text
);

-- Indexes
CREATE UNIQUE INDEX "monthly_distribution_year_month_idx" ON "monthly_distribution" USING btree ("year", "month");
CREATE INDEX "monthly_distribution_status_idx" ON "monthly_distribution" USING btree ("status");

--
-- Class OwnerAccount as table owner_account
--
CREATE TABLE "owner_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "singletonKey" bigint NOT NULL DEFAULT 1,
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "owner_singleton_idx" ON "owner_account" USING btree ("singletonKey");
CREATE UNIQUE INDEX "owner_auth_user_idx" ON "owner_account" USING btree ("authUserId");

--
-- Class Product as table product
--
CREATE TABLE "product" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "name" text NOT NULL,
    "description" text,
    "defaultSalePrice" bigint NOT NULL,
    "unit" text,
    "sku" text,
    "isActive" boolean NOT NULL DEFAULT true,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deviceId" uuid NOT NULL,
    "rowVersion" bigint NOT NULL DEFAULT 1,
    "syncStatus" text NOT NULL DEFAULT 'PENDING'::text
);

-- Indexes
CREATE UNIQUE INDEX "product_name_idx" ON "product" USING btree ("name");

--
-- Class Receipt as table receipt
--
CREATE TABLE "receipt" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "localRef" text,
    "officialNo" text,
    "receiptType" text NOT NULL,
    "clientId" uuid NOT NULL,
    "invoiceId" uuid,
    "amount" bigint NOT NULL,
    "receiptDate" timestamp without time zone NOT NULL,
    "note" text,
    "status" text NOT NULL DEFAULT 'ACTIVE'::text,
    "voidReason" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deviceId" uuid NOT NULL,
    "rowVersion" bigint NOT NULL DEFAULT 1,
    "syncStatus" text NOT NULL DEFAULT 'PENDING'::text
);

-- Indexes
CREATE INDEX "receipt_client_idx" ON "receipt" USING btree ("clientId");
CREATE INDEX "receipt_date_idx" ON "receipt" USING btree ("receiptDate");
CREATE INDEX "receipt_status_idx" ON "receipt" USING btree ("status");
CREATE UNIQUE INDEX "receipt_official_no_idx" ON "receipt" USING btree ("officialNo");

--
-- Class ReceiptAllocation as table receipt_allocation
--
CREATE TABLE "receipt_allocation" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "receiptId" uuid NOT NULL,
    "invoiceId" uuid NOT NULL,
    "allocatedAmount" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "allocation_receipt_idx" ON "receipt_allocation" USING btree ("receiptId");
CREATE INDEX "allocation_invoice_idx" ON "receipt_allocation" USING btree ("invoiceId");

--
-- Class SalesInvoice as table sales_invoice
--
CREATE TABLE "sales_invoice" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "localRef" text NOT NULL,
    "officialNo" text,
    "clientId" uuid NOT NULL,
    "invoiceDate" timestamp without time zone NOT NULL,
    "discount" bigint NOT NULL DEFAULT 0,
    "total" bigint NOT NULL,
    "note" text,
    "status" text NOT NULL DEFAULT 'ACTIVE'::text,
    "voidReason" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deviceId" uuid NOT NULL,
    "rowVersion" bigint NOT NULL DEFAULT 1,
    "syncStatus" text NOT NULL DEFAULT 'PENDING'::text
);

-- Indexes
CREATE UNIQUE INDEX "invoice_local_ref_idx" ON "sales_invoice" USING btree ("localRef");
CREATE UNIQUE INDEX "invoice_official_no_idx" ON "sales_invoice" USING btree ("officialNo");
CREATE INDEX "invoice_date_idx" ON "sales_invoice" USING btree ("invoiceDate");
CREATE INDEX "invoice_client_idx" ON "sales_invoice" USING btree ("clientId");
CREATE INDEX "invoice_status_idx" ON "sales_invoice" USING btree ("status");

--
-- Class SalesInvoiceLine as table sales_invoice_line
--
CREATE TABLE "sales_invoice_line" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "invoiceId" uuid NOT NULL,
    "productId" uuid NOT NULL,
    "quantity" bigint NOT NULL,
    "unitPrice" bigint NOT NULL,
    "lineTotal" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "invoice_line_invoice_idx" ON "sales_invoice_line" USING btree ("invoiceId");

--
-- Class SalesReturn as table sales_return
--
CREATE TABLE "sales_return" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "localRef" text,
    "officialNo" text,
    "invoiceId" uuid NOT NULL,
    "returnDate" timestamp without time zone NOT NULL,
    "totalReturnedAmount" bigint NOT NULL,
    "note" text,
    "status" text NOT NULL DEFAULT 'ACTIVE'::text,
    "voidReason" text,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deviceId" uuid NOT NULL,
    "rowVersion" bigint NOT NULL DEFAULT 1,
    "syncStatus" text NOT NULL DEFAULT 'PENDING'::text
);

-- Indexes
CREATE INDEX "return_invoice_idx" ON "sales_return" USING btree ("invoiceId");
CREATE INDEX "return_date_idx" ON "sales_return" USING btree ("returnDate");
CREATE INDEX "return_status_idx" ON "sales_return" USING btree ("status");
CREATE UNIQUE INDEX "return_official_no_idx" ON "sales_return" USING btree ("officialNo");

--
-- Class SalesReturnLine as table sales_return_line
--
CREATE TABLE "sales_return_line" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "returnId" uuid NOT NULL,
    "invoiceLineId" uuid NOT NULL,
    "returnedQuantity" bigint NOT NULL,
    "returnedAmount" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "return_line_return_idx" ON "sales_return_line" USING btree ("returnId");

--
-- Class SyncCursor as table sync_cursor
--
CREATE TABLE "sync_cursor" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "entityType" text NOT NULL,
    "lastPulledAt" timestamp without time zone,
    "lastRowVersion" bigint NOT NULL DEFAULT 0,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "cursor_entity_type_idx" ON "sync_cursor" USING btree ("entityType");

--
-- Class SyncOutbox as table sync_outbox
--
CREATE TABLE "sync_outbox" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "entityType" text NOT NULL,
    "entityId" uuid NOT NULL,
    "operation" text NOT NULL,
    "payload" text NOT NULL,
    "rowVersion" bigint NOT NULL,
    "deviceId" uuid NOT NULL,
    "retryCount" bigint NOT NULL DEFAULT 0,
    "status" text NOT NULL DEFAULT 'PENDING'::text,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "outbox_status_idx" ON "sync_outbox" USING btree ("status");
CREATE INDEX "outbox_created_idx" ON "sync_outbox" USING btree ("createdAt");

--
-- Class CloudStorageEntry as table serverpod_cloud_storage
--
CREATE TABLE "serverpod_cloud_storage" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "addedTime" timestamp without time zone NOT NULL,
    "expiration" timestamp without time zone,
    "byteData" bytea NOT NULL,
    "verified" boolean NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_path_idx" ON "serverpod_cloud_storage" USING btree ("storageId", "path");
CREATE INDEX "serverpod_cloud_storage_expiration" ON "serverpod_cloud_storage" USING btree ("expiration");

--
-- Class CloudStorageDirectUploadEntry as table serverpod_cloud_storage_direct_upload
--
CREATE TABLE "serverpod_cloud_storage_direct_upload" (
    "id" bigserial PRIMARY KEY,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "expiration" timestamp without time zone NOT NULL,
    "authKey" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_cloud_storage_direct_upload_storage_path" ON "serverpod_cloud_storage_direct_upload" USING btree ("storageId", "path");

--
-- Class FutureCallEntry as table serverpod_future_call
--
CREATE TABLE "serverpod_future_call" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "serializedObject" text,
    "serverId" text NOT NULL,
    "identifier" text
);

-- Indexes
CREATE INDEX "serverpod_future_call_time_idx" ON "serverpod_future_call" USING btree ("time");
CREATE INDEX "serverpod_future_call_serverId_idx" ON "serverpod_future_call" USING btree ("serverId");
CREATE INDEX "serverpod_future_call_identifier_idx" ON "serverpod_future_call" USING btree ("identifier");

--
-- Class ServerHealthConnectionInfo as table serverpod_health_connection_info
--
CREATE TABLE "serverpod_health_connection_info" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "active" bigint NOT NULL,
    "closing" bigint NOT NULL,
    "idle" bigint NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_connection_info_timestamp_idx" ON "serverpod_health_connection_info" USING btree ("timestamp", "serverId", "granularity");

--
-- Class ServerHealthMetric as table serverpod_health_metric
--
CREATE TABLE "serverpod_health_metric" (
    "id" bigserial PRIMARY KEY,
    "name" text NOT NULL,
    "serverId" text NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    "isHealthy" boolean NOT NULL,
    "value" double precision NOT NULL,
    "granularity" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_health_metric_timestamp_idx" ON "serverpod_health_metric" USING btree ("timestamp", "serverId", "name", "granularity");

--
-- Class LogEntry as table serverpod_log
--
CREATE TABLE "serverpod_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "reference" text,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "logLevel" bigint NOT NULL,
    "message" text NOT NULL,
    "error" text,
    "stackTrace" text,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_log_sessionLogId_idx" ON "serverpod_log" USING btree ("sessionLogId");

--
-- Class MessageLogEntry as table serverpod_message_log
--
CREATE TABLE "serverpod_message_log" (
    "id" bigserial PRIMARY KEY,
    "sessionLogId" bigint NOT NULL,
    "serverId" text NOT NULL,
    "messageId" bigint NOT NULL,
    "endpoint" text NOT NULL,
    "messageName" text NOT NULL,
    "duration" double precision NOT NULL,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

--
-- Class MethodInfo as table serverpod_method
--
CREATE TABLE "serverpod_method" (
    "id" bigserial PRIMARY KEY,
    "endpoint" text NOT NULL,
    "method" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_method_endpoint_method_idx" ON "serverpod_method" USING btree ("endpoint", "method");

--
-- Class DatabaseMigrationVersion as table serverpod_migrations
--
CREATE TABLE "serverpod_migrations" (
    "id" bigserial PRIMARY KEY,
    "module" text NOT NULL,
    "version" text NOT NULL,
    "timestamp" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_migrations_ids" ON "serverpod_migrations" USING btree ("module");

--
-- Class QueryLogEntry as table serverpod_query_log
--
CREATE TABLE "serverpod_query_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "sessionLogId" bigint NOT NULL,
    "messageId" bigint,
    "query" text NOT NULL,
    "duration" double precision NOT NULL,
    "numRows" bigint,
    "error" text,
    "stackTrace" text,
    "slow" boolean NOT NULL,
    "order" bigint NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_query_log_sessionLogId_idx" ON "serverpod_query_log" USING btree ("sessionLogId");

--
-- Class ReadWriteTestEntry as table serverpod_readwrite_test
--
CREATE TABLE "serverpod_readwrite_test" (
    "id" bigserial PRIMARY KEY,
    "number" bigint NOT NULL
);

--
-- Class RuntimeSettings as table serverpod_runtime_settings
--
CREATE TABLE "serverpod_runtime_settings" (
    "id" bigserial PRIMARY KEY,
    "logSettings" json NOT NULL,
    "logSettingsOverrides" json NOT NULL,
    "logServiceCalls" boolean NOT NULL,
    "logMalformedCalls" boolean NOT NULL
);

--
-- Class SessionLogEntry as table serverpod_session_log
--
CREATE TABLE "serverpod_session_log" (
    "id" bigserial PRIMARY KEY,
    "serverId" text NOT NULL,
    "time" timestamp without time zone NOT NULL,
    "module" text,
    "endpoint" text,
    "method" text,
    "duration" double precision,
    "numQueries" bigint,
    "slow" boolean,
    "error" text,
    "stackTrace" text,
    "authenticatedUserId" bigint,
    "userId" text,
    "isOpen" boolean,
    "touched" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "serverpod_session_log_serverid_idx" ON "serverpod_session_log" USING btree ("serverId");
CREATE INDEX "serverpod_session_log_time_idx" ON "serverpod_session_log" USING btree ("time");
CREATE INDEX "serverpod_session_log_touched_idx" ON "serverpod_session_log" USING btree ("touched");
CREATE INDEX "serverpod_session_log_isopen_idx" ON "serverpod_session_log" USING btree ("isOpen");

--
-- Class RefreshToken as table serverpod_auth_core_jwt_refresh_token
--
CREATE TABLE "serverpod_auth_core_jwt_refresh_token" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "scopeNames" json NOT NULL,
    "extraClaims" text,
    "method" text NOT NULL,
    "fixedSecret" bytea NOT NULL,
    "rotatingSecretHash" text NOT NULL,
    "lastUpdatedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Indexes
CREATE INDEX "serverpod_auth_core_jwt_refresh_token_last_updated_at" ON "serverpod_auth_core_jwt_refresh_token" USING btree ("lastUpdatedAt");

--
-- Class UserProfile as table serverpod_auth_core_profile
--
CREATE TABLE "serverpod_auth_core_profile" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userName" text,
    "fullName" text,
    "email" text,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "imageId" uuid
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_profile_user_profile_email_auth_user_id" ON "serverpod_auth_core_profile" USING btree ("authUserId");

--
-- Class UserProfileImage as table serverpod_auth_core_profile_image
--
CREATE TABLE "serverpod_auth_core_profile_image" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "userProfileId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "storageId" text NOT NULL,
    "path" text NOT NULL,
    "url" text NOT NULL
);

--
-- Class ServerSideSession as table serverpod_auth_core_session
--
CREATE TABLE "serverpod_auth_core_session" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "scopeNames" json NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastUsedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" timestamp without time zone,
    "expireAfterUnusedFor" bigint,
    "sessionKeyHash" bytea NOT NULL,
    "sessionKeySalt" bytea NOT NULL,
    "method" text NOT NULL
);

--
-- Class AuthUser as table serverpod_auth_core_user
--
CREATE TABLE "serverpod_auth_core_user" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL,
    "scopeNames" json NOT NULL,
    "blocked" boolean NOT NULL
);

--
-- Class AnonymousAccount as table serverpod_auth_idp_anonymous_account
--
CREATE TABLE "serverpod_auth_idp_anonymous_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

--
-- Class AppleAccount as table serverpod_auth_idp_apple_account
--
CREATE TABLE "serverpod_auth_idp_apple_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "userIdentifier" text NOT NULL,
    "refreshToken" text NOT NULL,
    "refreshTokenRequestedWithBundleIdentifier" boolean NOT NULL,
    "lastRefreshedAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "email" text,
    "isEmailVerified" boolean,
    "isPrivateEmail" boolean,
    "firstName" text,
    "lastName" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_apple_account_identifier" ON "serverpod_auth_idp_apple_account" USING btree ("userIdentifier");

--
-- Class EmailAccount as table serverpod_auth_idp_email_account
--
CREATE TABLE "serverpod_auth_idp_email_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "email" text NOT NULL,
    "passwordHash" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_email_account_email" ON "serverpod_auth_idp_email_account" USING btree ("email");

--
-- Class EmailAccountPasswordResetRequest as table serverpod_auth_idp_email_account_password_reset_request
--
CREATE TABLE "serverpod_auth_idp_email_account_password_reset_request" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "emailAccountId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "challengeId" uuid NOT NULL,
    "setPasswordChallengeId" uuid
);

--
-- Class EmailAccountRequest as table serverpod_auth_idp_email_account_request
--
CREATE TABLE "serverpod_auth_idp_email_account_request" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "email" text NOT NULL,
    "challengeId" uuid NOT NULL,
    "createAccountChallengeId" uuid
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_email_account_request_email" ON "serverpod_auth_idp_email_account_request" USING btree ("email");

--
-- Class FacebookAccount as table serverpod_auth_idp_facebook_account
--
CREATE TABLE "serverpod_auth_idp_facebook_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "fullName" text,
    "firstName" text,
    "lastName" text
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_facebook_account_user_identifier" ON "serverpod_auth_idp_facebook_account" USING btree ("userIdentifier");

--
-- Class FirebaseAccount as table serverpod_auth_idp_firebase_account
--
CREATE TABLE "serverpod_auth_idp_firebase_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "created" timestamp without time zone NOT NULL,
    "email" text,
    "phone" text,
    "userIdentifier" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_firebase_account_user_identifier" ON "serverpod_auth_idp_firebase_account" USING btree ("userIdentifier");

--
-- Class GitHubAccount as table serverpod_auth_idp_github_account
--
CREATE TABLE "serverpod_auth_idp_github_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "created" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_github_account_user_identifier" ON "serverpod_auth_idp_github_account" USING btree ("userIdentifier");

--
-- Class GoogleAccount as table serverpod_auth_idp_google_account
--
CREATE TABLE "serverpod_auth_idp_google_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "created" timestamp without time zone NOT NULL,
    "email" text NOT NULL,
    "userIdentifier" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_google_account_user_identifier" ON "serverpod_auth_idp_google_account" USING btree ("userIdentifier");

--
-- Class MicrosoftAccount as table serverpod_auth_idp_microsoft_account
--
CREATE TABLE "serverpod_auth_idp_microsoft_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "userIdentifier" text NOT NULL,
    "email" text,
    "created" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_microsoft_account_user_identifier" ON "serverpod_auth_idp_microsoft_account" USING btree ("userIdentifier");

--
-- Class PasskeyAccount as table serverpod_auth_idp_passkey_account
--
CREATE TABLE "serverpod_auth_idp_passkey_account" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "authUserId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "keyId" bytea NOT NULL,
    "keyIdBase64" text NOT NULL,
    "clientDataJSON" bytea NOT NULL,
    "attestationObject" bytea NOT NULL,
    "originalChallenge" bytea NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "serverpod_auth_idp_passkey_account_key_id_base64" ON "serverpod_auth_idp_passkey_account" USING btree ("keyIdBase64");

--
-- Class PasskeyChallenge as table serverpod_auth_idp_passkey_challenge
--
CREATE TABLE "serverpod_auth_idp_passkey_challenge" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "createdAt" timestamp without time zone NOT NULL,
    "challenge" bytea NOT NULL
);

--
-- Class RateLimitedRequestAttempt as table serverpod_auth_idp_rate_limited_request_attempt
--
CREATE TABLE "serverpod_auth_idp_rate_limited_request_attempt" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "domain" text NOT NULL,
    "source" text NOT NULL,
    "nonce" text NOT NULL,
    "ipAddress" text,
    "attemptedAt" timestamp without time zone NOT NULL,
    "extraData" json
);

-- Indexes
CREATE INDEX "serverpod_auth_idp_rate_limited_request_attempt_composite" ON "serverpod_auth_idp_rate_limited_request_attempt" USING btree ("domain", "source", "nonce", "attemptedAt");

--
-- Class SecretChallenge as table serverpod_auth_idp_secret_challenge
--
CREATE TABLE "serverpod_auth_idp_secret_challenge" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid_v7(),
    "challengeCodeHash" text NOT NULL
);

--
-- Foreign relations for "attachment_metadata" table
--
ALTER TABLE ONLY "attachment_metadata"
    ADD CONSTRAINT "attachment_metadata_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "audit_event" table
--
ALTER TABLE ONLY "audit_event"
    ADD CONSTRAINT "audit_event_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "client" table
--
ALTER TABLE ONLY "client"
    ADD CONSTRAINT "client_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "conflict_log" table
--
ALTER TABLE ONLY "conflict_log"
    ADD CONSTRAINT "conflict_log_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "expense" table
--
ALTER TABLE ONLY "expense"
    ADD CONSTRAINT "expense_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "monthly_distribution" table
--
ALTER TABLE ONLY "monthly_distribution"
    ADD CONSTRAINT "monthly_distribution_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "product" table
--
ALTER TABLE ONLY "product"
    ADD CONSTRAINT "product_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "receipt" table
--
ALTER TABLE ONLY "receipt"
    ADD CONSTRAINT "receipt_fk_0"
    FOREIGN KEY("clientId")
    REFERENCES "client"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "receipt"
    ADD CONSTRAINT "receipt_fk_1"
    FOREIGN KEY("invoiceId")
    REFERENCES "sales_invoice"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "receipt"
    ADD CONSTRAINT "receipt_fk_2"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "receipt_allocation" table
--
ALTER TABLE ONLY "receipt_allocation"
    ADD CONSTRAINT "receipt_allocation_fk_0"
    FOREIGN KEY("receiptId")
    REFERENCES "receipt"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "receipt_allocation"
    ADD CONSTRAINT "receipt_allocation_fk_1"
    FOREIGN KEY("invoiceId")
    REFERENCES "sales_invoice"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "sales_invoice" table
--
ALTER TABLE ONLY "sales_invoice"
    ADD CONSTRAINT "sales_invoice_fk_0"
    FOREIGN KEY("clientId")
    REFERENCES "client"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "sales_invoice"
    ADD CONSTRAINT "sales_invoice_fk_1"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "sales_invoice_line" table
--
ALTER TABLE ONLY "sales_invoice_line"
    ADD CONSTRAINT "sales_invoice_line_fk_0"
    FOREIGN KEY("invoiceId")
    REFERENCES "sales_invoice"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "sales_invoice_line"
    ADD CONSTRAINT "sales_invoice_line_fk_1"
    FOREIGN KEY("productId")
    REFERENCES "product"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "sales_return" table
--
ALTER TABLE ONLY "sales_return"
    ADD CONSTRAINT "sales_return_fk_0"
    FOREIGN KEY("invoiceId")
    REFERENCES "sales_invoice"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "sales_return"
    ADD CONSTRAINT "sales_return_fk_1"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "sales_return_line" table
--
ALTER TABLE ONLY "sales_return_line"
    ADD CONSTRAINT "sales_return_line_fk_0"
    FOREIGN KEY("returnId")
    REFERENCES "sales_return"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "sales_return_line"
    ADD CONSTRAINT "sales_return_line_fk_1"
    FOREIGN KEY("invoiceLineId")
    REFERENCES "sales_invoice_line"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "sync_outbox" table
--
ALTER TABLE ONLY "sync_outbox"
    ADD CONSTRAINT "sync_outbox_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_log" table
--
ALTER TABLE ONLY "serverpod_log"
    ADD CONSTRAINT "serverpod_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_message_log" table
--
ALTER TABLE ONLY "serverpod_message_log"
    ADD CONSTRAINT "serverpod_message_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_query_log" table
--
ALTER TABLE ONLY "serverpod_query_log"
    ADD CONSTRAINT "serverpod_query_log_fk_0"
    FOREIGN KEY("sessionLogId")
    REFERENCES "serverpod_session_log"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_core_jwt_refresh_token" table
--
ALTER TABLE ONLY "serverpod_auth_core_jwt_refresh_token"
    ADD CONSTRAINT "serverpod_auth_core_jwt_refresh_token_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_core_profile" table
--
ALTER TABLE ONLY "serverpod_auth_core_profile"
    ADD CONSTRAINT "serverpod_auth_core_profile_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_core_profile"
    ADD CONSTRAINT "serverpod_auth_core_profile_fk_1"
    FOREIGN KEY("imageId")
    REFERENCES "serverpod_auth_core_profile_image"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_core_profile_image" table
--
ALTER TABLE ONLY "serverpod_auth_core_profile_image"
    ADD CONSTRAINT "serverpod_auth_core_profile_image_fk_0"
    FOREIGN KEY("userProfileId")
    REFERENCES "serverpod_auth_core_profile"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_core_session" table
--
ALTER TABLE ONLY "serverpod_auth_core_session"
    ADD CONSTRAINT "serverpod_auth_core_session_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_anonymous_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_anonymous_account"
    ADD CONSTRAINT "serverpod_auth_idp_anonymous_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_apple_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_apple_account"
    ADD CONSTRAINT "serverpod_auth_idp_apple_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_email_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_email_account_password_reset_request" table
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_0"
    FOREIGN KEY("emailAccountId")
    REFERENCES "serverpod_auth_idp_email_account"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_1"
    FOREIGN KEY("challengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_password_reset_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_password_reset_request_fk_2"
    FOREIGN KEY("setPasswordChallengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_email_account_request" table
--
ALTER TABLE ONLY "serverpod_auth_idp_email_account_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_request_fk_0"
    FOREIGN KEY("challengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "serverpod_auth_idp_email_account_request"
    ADD CONSTRAINT "serverpod_auth_idp_email_account_request_fk_1"
    FOREIGN KEY("createAccountChallengeId")
    REFERENCES "serverpod_auth_idp_secret_challenge"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_facebook_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_facebook_account"
    ADD CONSTRAINT "serverpod_auth_idp_facebook_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_firebase_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_firebase_account"
    ADD CONSTRAINT "serverpod_auth_idp_firebase_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_github_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_github_account"
    ADD CONSTRAINT "serverpod_auth_idp_github_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_google_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_google_account"
    ADD CONSTRAINT "serverpod_auth_idp_google_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_microsoft_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_microsoft_account"
    ADD CONSTRAINT "serverpod_auth_idp_microsoft_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;

--
-- Foreign relations for "serverpod_auth_idp_passkey_account" table
--
ALTER TABLE ONLY "serverpod_auth_idp_passkey_account"
    ADD CONSTRAINT "serverpod_auth_idp_passkey_account_fk_0"
    FOREIGN KEY("authUserId")
    REFERENCES "serverpod_auth_core_user"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR motaz_app
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('motaz_app', '20260513010450141', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260513010450141', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260129181112269', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181112269', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260213194423028', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260213194423028', "timestamp" = now();


COMMIT;
