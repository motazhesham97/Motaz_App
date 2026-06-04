BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "beneficiary" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "displayName" text NOT NULL,
    "phone" text,
    "sourceClientId" uuid,
    "isActive" boolean NOT NULL DEFAULT true,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deviceId" uuid NOT NULL,
    "rowVersion" bigint NOT NULL DEFAULT 1,
    "syncStatus" text NOT NULL DEFAULT 'PENDING'::text
);

-- Indexes
CREATE INDEX "beneficiary_display_name_idx" ON "beneficiary" USING btree ("displayName");
CREATE INDEX "beneficiary_source_client_idx" ON "beneficiary" USING btree ("sourceClientId");

--
-- ACTION ALTER TABLE
--
ALTER TABLE "device" ADD COLUMN "nextSampleSequence" bigint NOT NULL DEFAULT 1;
--
-- ACTION CREATE TABLE
--
CREATE TABLE "free_sample" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "localRef" text NOT NULL,
    "officialNo" text,
    "beneficiaryId" uuid NOT NULL,
    "sampleDate" timestamp without time zone NOT NULL,
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
CREATE UNIQUE INDEX "free_sample_local_ref_idx" ON "free_sample" USING btree ("localRef");
CREATE UNIQUE INDEX "free_sample_official_no_idx" ON "free_sample" USING btree ("officialNo");
CREATE INDEX "free_sample_beneficiary_idx" ON "free_sample" USING btree ("beneficiaryId");
CREATE INDEX "free_sample_date_idx" ON "free_sample" USING btree ("sampleDate");
CREATE INDEX "free_sample_status_idx" ON "free_sample" USING btree ("status");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "free_sample_line" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "sampleId" uuid NOT NULL,
    "productId" uuid NOT NULL,
    "quantity" bigint NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "updatedAt" timestamp without time zone NOT NULL,
    "deviceId" uuid NOT NULL,
    "rowVersion" bigint NOT NULL DEFAULT 1,
    "syncStatus" text NOT NULL DEFAULT 'PENDING'::text
);

-- Indexes
CREATE INDEX "free_sample_line_sample_idx" ON "free_sample_line" USING btree ("sampleId");
CREATE INDEX "free_sample_line_product_idx" ON "free_sample_line" USING btree ("productId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "beneficiary"
    ADD CONSTRAINT "beneficiary_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "free_sample"
    ADD CONSTRAINT "free_sample_fk_0"
    FOREIGN KEY("beneficiaryId")
    REFERENCES "beneficiary"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "free_sample"
    ADD CONSTRAINT "free_sample_fk_1"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "free_sample_line"
    ADD CONSTRAINT "free_sample_line_fk_0"
    FOREIGN KEY("sampleId")
    REFERENCES "free_sample"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "free_sample_line"
    ADD CONSTRAINT "free_sample_line_fk_1"
    FOREIGN KEY("productId")
    REFERENCES "product"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "free_sample_line"
    ADD CONSTRAINT "free_sample_line_fk_2"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR motaz_app
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('motaz_app', '20260519231104187', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260519231104187', "timestamp" = now();

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
