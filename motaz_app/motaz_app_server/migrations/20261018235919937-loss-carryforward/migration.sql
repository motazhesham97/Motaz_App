BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "monthly_distribution" ADD COLUMN "netSales" bigint NOT NULL DEFAULT 0;
ALTER TABLE "monthly_distribution" ADD COLUMN "operationalExpenses" bigint NOT NULL DEFAULT 0;
ALTER TABLE "monthly_distribution" ADD COLUMN "productionExpenses" bigint NOT NULL DEFAULT 0;
ALTER TABLE "monthly_distribution" ADD COLUMN "profitBeforeCarry" bigint NOT NULL DEFAULT 0;
ALTER TABLE "monthly_distribution" ADD COLUMN "currentMonthLoss" bigint NOT NULL DEFAULT 0;
ALTER TABLE "monthly_distribution" ADD COLUMN "carriedLossIn" bigint NOT NULL DEFAULT 0;
ALTER TABLE "monthly_distribution" ADD COLUMN "carriedLossOut" bigint NOT NULL DEFAULT 0;

--
-- MIGRATION VERSION FOR motaz_app
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('motaz_app', '20261018235919937-loss-carryforward', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261018235919937-loss-carryforward', "timestamp" = now();

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
