-- One-step psql setup for the drug-combination PostgreSQL layer.
-- Run from the repository root so the CSV paths resolve correctly:
--   psql -d drug_combo -f database/schema/00_full_setup.sql
--
-- If data/processed/sql/*.csv does not exist yet, generate it first:
--   python src/data_processing/generate_processed_data.py

\echo [1/3] Creating schema, base tables, and indexes...
\ir 00_schema.sql

\echo [2/3] Loading CSV exports from data/processed/sql/ ...
\ir 01_load_from_csv_psql.sql

\echo [3/3] Creating analytical views ...
\ir 02_views.sql

\echo Setup complete.
\echo Optional validation: psql -d drug_combo -f database/queries/validation_queries.sql
