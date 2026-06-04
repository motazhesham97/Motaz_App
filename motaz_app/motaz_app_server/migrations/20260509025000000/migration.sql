BEGIN;

DROP INDEX IF EXISTS "device_code_idx";
CREATE UNIQUE INDEX "device_code_idx"
    ON "device" USING btree ("deviceCode");

--
-- MIGRATION VERSION FOR motaz_app
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('motaz_app', '20260509025000000', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260509025000000', "timestamp" = now();

COMMIT;
