-- pgAdmin / Query Tool template using server-side COPY.
-- Replace __REPO_ROOT__ with the absolute path to your cloned repository.
-- Use forward slashes even on Windows, for example:
--   C:/Users/your_name/path/to/drug-combination
--
-- This works only if the PostgreSQL server process can read the files.
-- If permissions or file visibility are a problem, use the psql-based loader instead:
--   psql -d drug_combo -f database/schema/00_full_setup.sql

SET search_path TO drug_combo, public;

TRUNCATE TABLE observation_doses, model_performance, observations, drugs RESTART IDENTITY CASCADE;

COPY drug_combo.drugs (drug_id, drug_key, drug_name, max_tested_dose)
FROM '__REPO_ROOT__/data/processed/sql/drugs.csv'
WITH (FORMAT csv, HEADER true);

COPY drug_combo.observations (observation_id, cell_viability)
FROM '__REPO_ROOT__/data/processed/sql/observations.csv'
WITH (FORMAT csv, HEADER true);

COPY drug_combo.observation_doses (observation_id, drug_id, dose_level)
FROM '__REPO_ROOT__/data/processed/sql/observation_doses.csv'
WITH (FORMAT csv, HEADER true);

COPY drug_combo.model_performance (model_name, normalization, test_mse, rank_within_normalization)
FROM '__REPO_ROOT__/data/processed/sql/model_performance_reported.csv'
WITH (FORMAT csv, HEADER true);
