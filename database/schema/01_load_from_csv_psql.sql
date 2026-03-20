-- psql-only CSV loader for the drug-combination PostgreSQL layer.
-- Run from the repository root so the relative CSV paths resolve correctly:
--   psql -d drug_combo -f database/schema/01_load_from_csv_psql.sql
-- or use the wrapper:
--   psql -d drug_combo -f database/schema/00_full_setup.sql

SET search_path TO drug_combo, public;

TRUNCATE TABLE observation_doses, model_performance, observations, drugs RESTART IDENTITY CASCADE;

\copy drug_combo.drugs (drug_id, drug_key, drug_name, max_tested_dose) FROM 'data/processed/sql/drugs.csv' WITH (FORMAT csv, HEADER true)
\copy drug_combo.observations (observation_id, cell_viability) FROM 'data/processed/sql/observations.csv' WITH (FORMAT csv, HEADER true)
\copy drug_combo.observation_doses (observation_id, drug_id, dose_level) FROM 'data/processed/sql/observation_doses.csv' WITH (FORMAT csv, HEADER true)
\copy drug_combo.model_performance (model_name, normalization, test_mse, rank_within_normalization) FROM 'data/processed/sql/model_performance_reported.csv' WITH (FORMAT csv, HEADER true)
