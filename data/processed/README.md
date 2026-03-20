# Processed data

This directory contains **derived CSVs** generated from `data/raw/drug_viability_data.csv` plus the
**reported model-performance table** already encoded in `database/schema/00_full_setup.sql`.

Regenerate everything with Python 3 (plus `pandas` and `numpy`) installed:

```bash
python src/data_processing/generate_processed_data.py
```

The generator writes three groups of outputs:

## `modeling/`
Model-ready tables for the statistical-learning workflow.

- `clean.csv` - raw dataset with cleaned column names (`experiment_id`, `cell_viability`)
- `raw_doses.csv` - 14-feature quadratic/interaction matrix built on raw dose levels
- `feature_scaled.csv` - the same 14-feature matrix after column-wise min-max scaling
- `standardized.csv` - the same 14-feature matrix after column-wise z-score standardization

Feature columns match the original R scripts:

- base terms: `V`, `M`, `E`, `D`
- quadratic / interaction terms: `VV`, `VM`, `MM`, `VE`, `ME`, `EE`, `VD`, `MD`, `ED`, `DD`

where:
- `V` = Vincristine
- `M` = Mitoxantrone
- `E` = Etoposide
- `D` = Daunorubicin

## `sql/`
CSV exports aligned with the PostgreSQL schema.

- `drugs.csv`
- `observations.csv`
- `observation_doses.csv`
- `model_performance_reported.csv`

`model_performance_reported.csv` is **not re-fit from scratch** by the generator. It is seeded from the
reported metrics already used in the SQL / Tableau layer so the repo stays consistent.

## `dashboard/`
Pre-aggregated tables that mirror the Tableau-facing SQL views.

- `dashboard_kpis.csv`
- `model_performance.csv`
- `top_combinations.csv`
- `drug_level_summary.csv`
- `best_drug_levels.csv`
- `pair_heatmap_summary.csv`
- `vincristine_mitoxantrone_heatmap.csv`

These files are optional for the core R analysis, but they make the SQL and Tableau layers more portable
and easier to inspect on GitHub.
