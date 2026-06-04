BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "receipt" ADD COLUMN "officialNo" text;
CREATE UNIQUE INDEX "receipt_official_no_idx" ON "receipt" USING btree ("officialNo");
--
-- ACTION ALTER TABLE
--
CREATE UNIQUE INDEX "invoice_official_no_idx" ON "sales_invoice" USING btree ("officialNo");
--
-- ACTION ALTER TABLE
--
ALTER TABLE "sales_return" ADD COLUMN "officialNo" text;
CREATE UNIQUE INDEX "return_official_no_idx" ON "sales_return" USING btree ("officialNo");

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
