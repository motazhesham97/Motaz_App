BEGIN;

DROP INDEX IF EXISTS "monthly_distribution_year_month_idx";
CREATE INDEX "monthly_distribution_year_month_idx"
    ON "monthly_distribution" USING btree ("year", "month");

--
-- MIGRATION VERSION FOR motaz_app
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('motaz_app', '20260509021500000', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260509021500000', "timestamp" = now();

COMMIT;
