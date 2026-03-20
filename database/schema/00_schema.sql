DROP SCHEMA IF EXISTS drug_combo CASCADE;
CREATE SCHEMA drug_combo;
SET search_path TO drug_combo, public;

CREATE TABLE drugs (
    drug_id SMALLINT PRIMARY KEY,
    drug_key TEXT NOT NULL UNIQUE,
    drug_name TEXT NOT NULL UNIQUE,
    max_tested_dose NUMERIC(10,3) NOT NULL CHECK (max_tested_dose >= 0)
);

CREATE TABLE observations (
    observation_id INTEGER PRIMARY KEY,
    cell_viability NUMERIC(10,4) NOT NULL CHECK (cell_viability >= 0)
);

CREATE TABLE observation_doses (
    observation_id INTEGER NOT NULL REFERENCES observations(observation_id) ON DELETE CASCADE,
    drug_id SMALLINT NOT NULL REFERENCES drugs(drug_id),
    dose_level NUMERIC(10,3) NOT NULL CHECK (dose_level >= 0),
    PRIMARY KEY (observation_id, drug_id)
);

CREATE TABLE model_performance (
    model_name TEXT NOT NULL,
    normalization TEXT NOT NULL,
    test_mse NUMERIC(10,6) NOT NULL CHECK (test_mse >= 0),
    rank_within_normalization SMALLINT NOT NULL CHECK (rank_within_normalization >= 1),
    PRIMARY KEY (model_name, normalization)
);

CREATE INDEX idx_observation_doses_drug_level
    ON observation_doses (drug_id, dose_level);

CREATE INDEX idx_model_performance_norm_rank
    ON model_performance (normalization, rank_within_normalization);

SET search_path TO drug_combo, public;
