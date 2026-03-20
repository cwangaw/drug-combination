-- Validation queries for the drug-combination PostgreSQL schema.
-- These queries are designed to work in pgAdmin or psql.

-- -------------------------------------------------------------------
-- 1) Base-table row counts
-- -------------------------------------------------------------------
SELECT 'drugs' AS object_name, COUNT(*) AS actual_count, 4 AS expected_count,
       CASE WHEN COUNT(*) = 4 THEN 'PASS' ELSE 'FAIL' END AS status
FROM drug_combo.drugs
UNION ALL
SELECT 'observations', COUNT(*), 256,
       CASE WHEN COUNT(*) = 256 THEN 'PASS' ELSE 'FAIL' END
FROM drug_combo.observations
UNION ALL
SELECT 'observation_doses', COUNT(*), 1024,
       CASE WHEN COUNT(*) = 1024 THEN 'PASS' ELSE 'FAIL' END
FROM drug_combo.observation_doses
UNION ALL
SELECT 'model_performance', COUNT(*), 10,
       CASE WHEN COUNT(*) = 10 THEN 'PASS' ELSE 'FAIL' END
FROM drug_combo.model_performance
ORDER BY object_name;

-- -------------------------------------------------------------------
-- 2) View row counts
-- -------------------------------------------------------------------
SELECT 'vw_observation_long' AS object_name, COUNT(*) AS actual_count, 1024 AS expected_count,
       CASE WHEN COUNT(*) = 1024 THEN 'PASS' ELSE 'FAIL' END AS status
FROM drug_combo.vw_observation_long
UNION ALL
SELECT 'vw_observation_wide', COUNT(*), 256,
       CASE WHEN COUNT(*) = 256 THEN 'PASS' ELSE 'FAIL' END
FROM drug_combo.vw_observation_wide
UNION ALL
SELECT 'vw_drug_level_summary', COUNT(*), 16,
       CASE WHEN COUNT(*) = 16 THEN 'PASS' ELSE 'FAIL' END
FROM drug_combo.vw_drug_level_summary
UNION ALL
SELECT 'vw_best_drug_levels', COUNT(*), 4,
       CASE WHEN COUNT(*) = 4 THEN 'PASS' ELSE 'FAIL' END
FROM drug_combo.vw_best_drug_levels
UNION ALL
SELECT 'vw_vincristine_mitoxantrone_heatmap', COUNT(*), 16,
       CASE WHEN COUNT(*) = 16 THEN 'PASS' ELSE 'FAIL' END
FROM drug_combo.vw_vincristine_mitoxantrone_heatmap
UNION ALL
SELECT 'vw_model_performance', COUNT(*), 10,
       CASE WHEN COUNT(*) = 10 THEN 'PASS' ELSE 'FAIL' END
FROM drug_combo.vw_model_performance
UNION ALL
SELECT 'vw_top_combinations', COUNT(*), 256,
       CASE WHEN COUNT(*) = 256 THEN 'PASS' ELSE 'FAIL' END
FROM drug_combo.vw_top_combinations
UNION ALL
SELECT 'vw_dashboard_kpis', COUNT(*), 1,
       CASE WHEN COUNT(*) = 1 THEN 'PASS' ELSE 'FAIL' END
FROM drug_combo.vw_dashboard_kpis
ORDER BY object_name;

-- -------------------------------------------------------------------
-- 3) KPI preview
-- Expected highlights:
--   best_model = Lasso Regression (Studentized residual)
--   best_test_mse = 0.003251
--   best_cell_viability = 0.4200
-- -------------------------------------------------------------------
SELECT *
FROM drug_combo.vw_dashboard_kpis;

-- -------------------------------------------------------------------
-- 4) Top combinations preview
-- Expected best combination:
--   V=50 | M=10 | E=100 | D=75 with cell_viability = 0.4200
-- -------------------------------------------------------------------
SELECT
    viability_rank,
    experiment_id,
    combo_label,
    cell_viability,
    recommended_reason
FROM drug_combo.vw_top_combinations
WHERE viability_rank <= 10
ORDER BY viability_rank;

-- -------------------------------------------------------------------
-- 5) Model performance preview
-- -------------------------------------------------------------------
SELECT
    normalization,
    model,
    test_mse,
    mse_reduction_vs_quadratic_pct,
    rank_within_normalization
FROM drug_combo.vw_model_performance
ORDER BY normalization, rank_within_normalization;

-- -------------------------------------------------------------------
-- 6) Heatmap preview
-- -------------------------------------------------------------------
SELECT
    vincristine,
    mitoxantrone,
    mean_cell_viability
FROM drug_combo.vw_vincristine_mitoxantrone_heatmap
ORDER BY vincristine, mitoxantrone;

-- -------------------------------------------------------------------
-- 7) Best dose level by drug preview
-- Expected best levels:
--   Vincristine 50.00
--   Etoposide 100.00
--   Daunorubicin 75.00
--   Mitoxantrone 40.00
-- -------------------------------------------------------------------
SELECT
    drug_name,
    level,
    mean_cell_viability,
    median_cell_viability,
    min_cell_viability,
    max_cell_viability,
    n_observations
FROM drug_combo.vw_best_drug_levels
ORDER BY mean_cell_viability ASC, drug_name;
