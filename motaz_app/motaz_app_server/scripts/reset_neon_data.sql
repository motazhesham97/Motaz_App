-- Reset Fastika production data while preserving the Serverpod migration state.
-- Run this only against the intended Neon production branch.
--
-- This removes application data, auth users/sessions, logs, sync state, and
-- other runtime rows from every public table except serverpod_migrations.
-- Keeping serverpod_migrations prevents Serverpod from trying to replay old
-- migrations against an already-created schema.

DO $$
DECLARE
  table_list text;
BEGIN
  SELECT string_agg(format('%I.%I', schemaname, tablename), ', ')
    INTO table_list
  FROM pg_tables
  WHERE schemaname = 'public'
    AND tablename <> 'serverpod_migrations';

  IF table_list IS NULL THEN
    RAISE NOTICE 'No public tables found to truncate.';
  ELSE
    EXECUTE 'TRUNCATE TABLE ' || table_list || ' RESTART IDENTITY CASCADE';
    RAISE NOTICE 'Truncated tables: %', table_list;
  END IF;
END $$;
