BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "party_adjustment" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "party" text NOT NULL,
    "amount" bigint NOT NULL,
    "adjustmentDate" timestamp without time zone NOT NULL,
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
CREATE INDEX "party_adjustment_party_idx" ON "party_adjustment" USING btree ("party");
CREATE INDEX "party_adjustment_date_idx" ON "party_adjustment" USING btree ("adjustmentDate");
CREATE INDEX "party_adjustment_status_idx" ON "party_adjustment" USING btree ("status");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "party_adjustment"
    ADD CONSTRAINT "party_adjustment_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR motaz_app
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('motaz_app', '20260518005655099', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260518005655099', "timestamp" = now();

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
