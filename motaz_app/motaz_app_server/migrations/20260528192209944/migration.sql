BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "client" ADD COLUMN "creditLimit" bigint;
ALTER TABLE "client" ADD COLUMN "invoiceCheckIntervalDays" bigint;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "product" ADD COLUMN "shelfLifeDays" bigint;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "sales_invoice_line" ADD COLUMN "productionDate" timestamp without time zone;

--
-- MIGRATION VERSION FOR motaz_app
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('motaz_app', '20260528192209944', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260528192209944', "timestamp" = now();

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
