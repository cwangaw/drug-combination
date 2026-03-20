# PostgreSQL layer

This folder contains the PostgreSQL schema and view layer used to turn the original CSV-based project into a database-backed analytics workflow.

## Files

- `schema/00_full_setup.sql` — creates the `drug_combo` schema, base tables, inserts the project data, and defines the dashboard-facing views
- `queries/validation_queries.sql` — sanity checks for row counts, KPI outputs, and Tableau-facing views
- `erd.md` — compact entity relationship diagram

## Setup

Create a PostgreSQL database, then run:

```bash
psql -d drug_combo -f database/schema/00_full_setup.sql
```

The script creates a **schema** named `drug_combo` inside your chosen database. A clean setup is to use:

- database name: `drug_combo`
- schema name: `drug_combo`

That lets Tableau connect to the `drug_combo` database and query objects such as `drug_combo.vw_top_combinations`.

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

Or copy the individual queries into pgAdmin's Query Tool.

The validation script checks expected row counts and previews the main dashboard-facing views.
