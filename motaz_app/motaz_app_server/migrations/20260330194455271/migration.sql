BEGIN;

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
--
CREATE TABLE "client" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "displayName" text NOT NULL,
    "phone" text,
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
--
CREATE TABLE "device" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "deviceName" text NOT NULL CHECK (char_length("deviceName") BETWEEN 1 AND 255),
    "platform" text NOT NULL,
    "deviceCode" text NOT NULL CHECK (char_length("deviceCode") = 4),
    "nextInvoiceSequence" bigint NOT NULL DEFAULT 1,
    "createdAt" timestamp without time zone NOT NULL,
    "lastActiveAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "device_code_idx" ON "device" USING btree ("deviceCode");

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
--
CREATE TABLE "product" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "name" text NOT NULL,
    "description" text,
    "defaultSalePrice" bigint NOT NULL,
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
-- ACTION CREATE TABLE
--
CREATE TABLE "receipt" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
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

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
CREATE INDEX "invoice_date_idx" ON "sales_invoice" USING btree ("invoiceDate");
CREATE INDEX "invoice_client_idx" ON "sales_invoice" USING btree ("clientId");
CREATE INDEX "invoice_status_idx" ON "sales_invoice" USING btree ("status");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "sales_invoice_line" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "invoiceId" uuid NOT NULL,
    "productId" uuid NOT NULL,
    "quantity" bigint NOT NULL CHECK ("quantity" > 0),
    "unitPrice" bigint NOT NULL CHECK ("unitPrice" > 0),
    "lineTotal" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "invoice_line_invoice_idx" ON "sales_invoice_line" USING btree ("invoiceId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "sales_return" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
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

--
-- ACTION CREATE TABLE
--
CREATE TABLE "sales_return_line" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "returnId" uuid NOT NULL,
    "invoiceLineId" uuid NOT NULL,
    "returnedQuantity" bigint NOT NULL CHECK ("returnedQuantity" >= 0),
    "returnedAmount" bigint NOT NULL CHECK ("returnedAmount" >= 0),
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "return_line_return_idx" ON "sales_return_line" USING btree ("returnId");

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE TABLE
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
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "attachment_metadata"
    ADD CONSTRAINT "attachment_metadata_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "audit_event"
    ADD CONSTRAINT "audit_event_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "client"
    ADD CONSTRAINT "client_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "conflict_log"
    ADD CONSTRAINT "conflict_log_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "expense"
    ADD CONSTRAINT "expense_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "product"
    ADD CONSTRAINT "product_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
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
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "sync_outbox"
    ADD CONSTRAINT "sync_outbox_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR motaz_app
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('motaz_app', '20260330194455271', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260330194455271', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260213194423028', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260213194423028', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260129181112269', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181112269', "timestamp" = now();


COMMIT;
