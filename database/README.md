# PostgreSQL layer

This folder contains the PostgreSQL schema and view layer that turns the original CSV-based project into a database-backed analytics workflow.

## Files

- `schema/00_full_setup.sql` — recommended one-step `psql` setup
- `schema/00_schema.sql` — creates the `drug_combo` schema, base tables, and indexes
- `schema/01_load_from_csv_psql.sql` — loads `data/processed/sql/*.csv` with `\copy`
- `schema/01_load_from_csv_pgadmin_template.sql` — pgAdmin / Query Tool template using server-side `COPY`
- `schema/02_views.sql` — creates the dashboard-facing analytical views
- `queries/validation_queries.sql` — sanity checks for row counts, KPI outputs, and Tableau-facing views
- `erd.md` — compact entity relationship diagram

## Recommended setup (`psql`)

Generate the processed CSVs first if needed:

```bash
python src/data_processing/generate_processed_data.py
```

Then, **from the repository root**, run:

```bash
psql -d drug_combo -f database/schema/00_full_setup.sql
```

That wrapper script runs:
1. `00_schema.sql`
2. `01_load_from_csv_psql.sql`
3. `02_views.sql`

The repository-root working directory matters because the `\copy` commands read from:
- `data/processed/sql/drugs.csv`
- `data/processed/sql/observations.csv`
- `data/processed/sql/observation_doses.csv`
- `data/processed/sql/model_performance_reported.csv`

## pgAdmin / Query Tool alternative

If you prefer pgAdmin, run these scripts in order:

1. `schema/00_schema.sql`
2. `schema/01_load_from_csv_pgadmin_template.sql`
3. `schema/02_views.sql`

For step 2, replace `__REPO_ROOT__` with the absolute path to your cloned repository. Use forward slashes even on Windows. This option relies on PostgreSQL server-side `COPY`, so it only works if the PostgreSQL server process can read those files.

## Base tables

- `drug_combo.drugs` — drug dimension table
- `drug_combo.observations` — experiment-level cell viability outcomes
- `drug_combo.observation_doses` — normalized bridge table storing dose levels by experiment and drug
- `drug_combo.model_performance` — reported model-comparison metrics used in the dashboard

## Main views for BI / Tableau

- `drug_combo.vw_dashboard_kpis`
- `drug_combo.vw_model_performance`
- `drug_combo.vw_top_combinations`
- `drug_combo.vw_vincristine_mitoxantrone_heatmap`
- `drug_combo.vw_best_drug_levels`

## Validation

After loading the schema, run:

```bash
psql -d drug_combo -f database/queries/validation_queries.sql
```

Or paste the individual queries into pgAdmin's Query Tool.

The validation script checks expected row counts and previews the main dashboard-facing views.
