BEGIN;

--
-- ACTION CREATE TABLE
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
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "monthly_distribution"
    ADD CONSTRAINT "monthly_distribution_fk_0"
    FOREIGN KEY("deviceId")
    REFERENCES "device"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR motaz_app
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('motaz_app', '20260507233236466', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260507233236466', "timestamp" = now();

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
