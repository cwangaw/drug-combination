SET search_path TO drug_combo, public;

CREATE OR REPLACE VIEW vw_observation_long AS
SELECT
    o.observation_id AS test_id,
    d.drug_id,
    d.drug_key,
    d.drug_name,
    od.dose_level,
    o.cell_viability
FROM observations o
JOIN observation_doses od
    ON o.observation_id = od.observation_id
JOIN drugs d
    ON od.drug_id = d.drug_id
ORDER BY o.observation_id, d.drug_id;

CREATE OR REPLACE VIEW vw_observation_wide AS
SELECT
    o.observation_id AS test_id,
    MAX(CASE WHEN d.drug_key = 'vincristine' THEN od.dose_level END) AS vincristine,
    MAX(CASE WHEN d.drug_key = 'mitoxantrone' THEN od.dose_level END) AS mitoxantrone,
    MAX(CASE WHEN d.drug_key = 'etoposide' THEN od.dose_level END) AS etoposide,
    MAX(CASE WHEN d.drug_key = 'daunorubicin' THEN od.dose_level END) AS daunorubicin,
    o.cell_viability
FROM observations o
JOIN observation_doses od
    ON o.observation_id = od.observation_id
JOIN drugs d
    ON od.drug_id = d.drug_id
GROUP BY o.observation_id, o.cell_viability
ORDER BY o.observation_id;

CREATE OR REPLACE VIEW vw_drug_level_summary AS
SELECT
    d.drug_key,
    d.drug_name,
    od.dose_level AS level,
    ROUND(AVG(o.cell_viability)::numeric, 6) AS mean_cell_viability,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY o.cell_viability)::numeric, 6) AS median_cell_viability,
    ROUND(MIN(o.cell_viability)::numeric, 6) AS min_cell_viability,
    ROUND(MAX(o.cell_viability)::numeric, 6) AS max_cell_viability,
    COUNT(*)::integer AS n_observations
FROM observation_doses od
JOIN observations o
    ON od.observation_id = o.observation_id
JOIN drugs d
    ON od.drug_id = d.drug_id
GROUP BY d.drug_key, d.drug_name, od.dose_level
ORDER BY d.drug_key, od.dose_level;

CREATE OR REPLACE VIEW vw_best_drug_levels AS
WITH ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY drug_key
            ORDER BY mean_cell_viability ASC, level DESC
        ) AS best_level_rank
    FROM vw_drug_level_summary
)
SELECT
    drug_key,
    drug_name,
    level,
    mean_cell_viability,
    median_cell_viability,
    min_cell_viability,
    max_cell_viability,
    n_observations,
    best_level_rank
FROM ranked
WHERE best_level_rank = 1
ORDER BY mean_cell_viability ASC, drug_name;

CREATE OR REPLACE VIEW vw_pair_heatmap_summary AS
WITH pair_rows AS (
    SELECT
        d1.drug_key AS drug_a_key,
        d1.drug_name AS drug_a_name,
        d2.drug_key AS drug_b_key,
        d2.drug_name AS drug_b_name,
        od1.dose_level AS drug_a_level,
        od2.dose_level AS drug_b_level,
        o.cell_viability
    FROM observations o
    JOIN observation_doses od1
        ON o.observation_id = od1.observation_id
    JOIN drugs d1
        ON od1.drug_id = d1.drug_id
    JOIN observation_doses od2
        ON o.observation_id = od2.observation_id
    JOIN drugs d2
        ON od2.drug_id = d2.drug_id
    WHERE d1.drug_id < d2.drug_id
)
SELECT
    LOWER(drug_a_key || ' + ' || drug_b_key) AS pair_key,
    drug_a_name || ' + ' || drug_b_name AS pair_name,
    drug_a_key,
    drug_a_name,
    drug_b_key,
    drug_b_name,
    drug_a_level,
    drug_b_level,
    ROUND(AVG(cell_viability)::numeric, 6) AS mean_cell_viability,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cell_viability)::numeric, 6) AS median_cell_viability,
    ROUND(MIN(cell_viability)::numeric, 6) AS min_cell_viability,
    ROUND(MAX(cell_viability)::numeric, 6) AS max_cell_viability,
    COUNT(*)::integer AS n_observations
FROM pair_rows
GROUP BY
    drug_a_key,
    drug_a_name,
    drug_b_key,
    drug_b_name,
    drug_a_level,
    drug_b_level
ORDER BY pair_name, drug_a_level, drug_b_level;

CREATE OR REPLACE VIEW vw_vincristine_mitoxantrone_heatmap AS
SELECT
    drug_a_level AS vincristine,
    drug_b_level AS mitoxantrone,
    mean_cell_viability,
    median_cell_viability,
    min_cell_viability,
    max_cell_viability,
    n_observations
FROM vw_pair_heatmap_summary
WHERE pair_key = 'vincristine + mitoxantrone'
ORDER BY vincristine, mitoxantrone;

CREATE OR REPLACE VIEW vw_model_performance AS
WITH baseline AS (
    SELECT
        normalization,
        MAX(CASE WHEN model_name = 'Quadratic Regression' THEN test_mse END) AS baseline_quadratic_mse
    FROM model_performance
    GROUP BY normalization
)
SELECT
    mp.model_name AS model,
    mp.normalization,
    mp.test_mse,
    b.baseline_quadratic_mse,
    ROUND(
        100 * (b.baseline_quadratic_mse - mp.test_mse) / NULLIF(b.baseline_quadratic_mse, 0),
        3
    ) AS mse_reduction_vs_quadratic_pct,
    mp.rank_within_normalization
FROM model_performance mp
JOIN baseline b
    ON mp.normalization = b.normalization
ORDER BY mp.normalization, mp.rank_within_normalization;

CREATE OR REPLACE VIEW vw_top_combinations AS
SELECT
    w.test_id AS experiment_id,
    w.vincristine,
    w.mitoxantrone,
    w.etoposide,
    w.daunorubicin,
    w.cell_viability,
    ROUND(100 * w.cell_viability, 2) AS cell_viability_pct,
    CONCAT(
        'V=', w.vincristine::text,
        ' | M=', w.mitoxantrone::text,
        ' | E=', w.etoposide::text,
        ' | D=', w.daunorubicin::text
    ) AS combo_label,
    ROW_NUMBER() OVER (ORDER BY w.cell_viability ASC, w.test_id ASC) AS viability_rank,
    ROUND(1 - w.cell_viability, 6) AS efficacy_score,
    CASE
        WHEN w.vincristine > 0 AND w.mitoxantrone > 0 THEN 'Includes Vincristine + Mitoxantrone'
        WHEN w.vincristine > 0 THEN 'Vincristine-based combination'
        WHEN w.mitoxantrone > 0 THEN 'Mitoxantrone-based combination'
        ELSE 'Non-VM combination'
    END AS recommended_reason
FROM vw_observation_wide w
ORDER BY viability_rank;

CREATE OR REPLACE VIEW vw_dashboard_kpis AS
WITH best_model AS (
    SELECT
        model,
        normalization,
        test_mse
    FROM vw_model_performance
    ORDER BY test_mse ASC, model ASC
    LIMIT 1
),
best_combo AS (
    SELECT
        experiment_id,
        cell_viability
    FROM vw_top_combinations
    ORDER BY cell_viability ASC, experiment_id ASC
    LIMIT 1
)
SELECT
    (SELECT COUNT(*) FROM observations) AS n_combinations,
    (SELECT COUNT(*) FROM drugs) AS n_drugs,
    (SELECT ROUND(MIN(cell_viability)::numeric, 4) FROM observations) AS best_cell_viability,
    (SELECT ROUND(AVG(cell_viability)::numeric, 4) FROM observations) AS avg_cell_viability,
    (SELECT experiment_id FROM best_combo) AS best_experiment_id,
    (SELECT model || ' (' || normalization || ')' FROM best_model) AS best_model,
    (SELECT ROUND(test_mse::numeric, 6) FROM best_model) AS best_test_mse;