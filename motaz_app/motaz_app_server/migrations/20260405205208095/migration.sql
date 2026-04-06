BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "client" ADD COLUMN "email" text;
ALTER TABLE "client" ADD COLUMN "address" text;
--
-- ACTION CREATE TABLE
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
-- ACTION ALTER TABLE
--
ALTER TABLE "product" ADD COLUMN "costPrice" bigint;
ALTER TABLE "product" ADD COLUMN "unit" text;
ALTER TABLE "product" ADD COLUMN "sku" text;

--
-- MIGRATION VERSION FOR motaz_app
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('motaz_app', '20260405205208095', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260405205208095', "timestamp" = now();

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
