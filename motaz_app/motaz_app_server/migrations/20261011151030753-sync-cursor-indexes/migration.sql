BEGIN;

--
-- ACTION ALTER TABLE
--
CREATE INDEX "attachment_sync_cursor_idx" ON "attachment_metadata" USING btree ("rowVersion", "id");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "beneficiary_sync_cursor_idx" ON "beneficiary" USING btree ("rowVersion", "id");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "client_sync_cursor_idx" ON "client" USING btree ("rowVersion", "id");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "expense_sync_cursor_idx" ON "expense" USING btree ("rowVersion", "id");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "free_sample_sync_cursor_idx" ON "free_sample" USING btree ("rowVersion", "id");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "free_sample_line_sync_cursor_idx" ON "free_sample_line" USING btree ("rowVersion", "id");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "monthly_distribution_sync_cursor_idx" ON "monthly_distribution" USING btree ("rowVersion", "id");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "party_adjustment_sync_cursor_idx" ON "party_adjustment" USING btree ("rowVersion", "id");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "product_sync_cursor_idx" ON "product" USING btree ("rowVersion", "id");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "receipt_sync_cursor_idx" ON "receipt" USING btree ("rowVersion", "id");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "invoice_sync_cursor_idx" ON "sales_invoice" USING btree ("rowVersion", "id");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "return_sync_cursor_idx" ON "sales_return" USING btree ("rowVersion", "id");

-- Reserve official numbers atomically across concurrent sync requests. Start
-- after existing numeric numbers so deployed documents keep their references.
CREATE SEQUENCE "sales_invoice_official_no_seq";
SELECT setval('sales_invoice_official_no_seq',
    COALESCE((SELECT MAX("officialNo"::bigint) + 1 FROM "sales_invoice"
              WHERE "officialNo" ~ '^[0-9]+$'), 1), false);
CREATE SEQUENCE "receipt_official_no_seq";
SELECT setval('receipt_official_no_seq',
    COALESCE((SELECT MAX("officialNo"::bigint) + 1 FROM "receipt"
              WHERE "officialNo" ~ '^[0-9]+$'), 1), false);
CREATE SEQUENCE "sales_return_official_no_seq";
SELECT setval('sales_return_official_no_seq',
    COALESCE((SELECT MAX("officialNo"::bigint) + 1 FROM "sales_return"
              WHERE "officialNo" ~ '^[0-9]+$'), 1), false);
CREATE SEQUENCE "free_sample_official_no_seq";
SELECT setval('free_sample_official_no_seq',
    COALESCE((SELECT MAX("officialNo"::bigint) + 1 FROM "free_sample"
              WHERE "officialNo" ~ '^[0-9]+$'), 1), false);

--
-- MIGRATION VERSION FOR motaz_app
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('motaz_app', '20261011151030753-sync-cursor-indexes', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261011151030753-sync-cursor-indexes', "timestamp" = now();

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
