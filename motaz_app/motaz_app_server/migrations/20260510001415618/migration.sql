BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "device" ADD COLUMN "nextReceiptSequence" bigint NOT NULL DEFAULT 1;
ALTER TABLE "device" ADD COLUMN "nextReturnSequence" bigint NOT NULL DEFAULT 1;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "receipt" ADD COLUMN "localRef" text;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "sales_return" ADD COLUMN "localRef" text;

--
-- MIGRATION VERSION FOR motaz_app
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('motaz_app', '20260510001415618', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260510001415618', "timestamp" = now();

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
