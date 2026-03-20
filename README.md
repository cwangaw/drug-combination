# Statistical Analysis of Anticancer Drug Combinations

This repository packages a course project as a portfolio-ready analytics case study. The project analyzes how combinations of **Vincristine**, **Mitoxantrone**, **Etoposide**, and **Daunorubicin** affect leukemia cell viability using statistical learning in **R**, then extends the workflow into a **PostgreSQL** database layer and a **Tableau** dashboard.

## Why this repo exists

The original project folder contained good technical work but was not organized for GitHub: duplicated scripts, hidden workspace files, mixed-in class materials, and little support for downstream BI tooling. This version reframes the project as an **end-to-end analytics workflow**:

- **R** for feature engineering, model comparison, and resampling
- **Python** for reproducible processed-data generation
- **PostgreSQL** for normalized storage and dashboard-facing views
- **Tableau** for interactive visualization and reporting

## Project highlights

- Built models on **256 dosage combinations** of four anticancer drugs with **14 engineered features** (4 main-effect dose terms + 10 quadratic / interaction terms).
- Compared **Quadratic Regression, Ridge Regression, Lasso Regression, MLP, and Random Forest** under both **feature scaling** and **studentized-residual normalization**.
- Used **8-fold cross-validation**, test-set **MSE**, and repeated random holdout evaluation to compare quality and stability.
- Found that **Lasso** and **Random Forest** were the strongest-performing models, with test MSE around **0.00325-0.00330** versus **0.02725** for quadratic regression.
- Identified **Vincristine-based combinations**, especially **Vincristine + Mitoxantrone (VM)**, as the most promising candidates for reducing leukemia cell viability.
- Added a **processed-data layer** under `data/processed/` so the SQL and Tableau parts can be rebuilt from version-controlled CSVs instead of hardcoded SQL inserts.
- Added a **PostgreSQL schema + analytical views** and a **Tableau dashboard** for portfolio-facing presentation.

## Tech stack

- **R**: statistical modeling, feature engineering, cross-validation, resampling
- **Python**: processed-data generation (`pandas`, `numpy`)
- **PostgreSQL**: relational schema design, CSV-based loading, analytical views
- **Tableau**: dashboarding and visual analytics
- **Git/GitHub**: portfolio packaging and version control

## Repository structure

```text
drug-combination/
├── README.md
├── .gitignore
├── data/
│   ├── README.md
│   ├── raw/
│   │   └── drug_viability_data.csv
│   └── processed/
│       ├── README.md
│       ├── modeling/
│       ├── sql/
│       └── dashboard/
├── database/
│   ├── README.md
│   ├── schema/
│   │   ├── 00_full_setup.sql
│   │   ├── 00_schema.sql
│   │   ├── 01_load_from_csv_psql.sql
│   │   ├── 01_load_from_csv_pgadmin_template.sql
│   │   └── 02_views.sql
│   ├── queries/
│   │   └── validation_queries.sql
│   └── erd.md
├── docs/
│   ├── portfolio_summary.md
│   └── script_map.md
├── reports/
│   ├── final_report.pdf
│   └── progress_report.pdf
├── results/
│   └── design_pdfs/
├── slides/
│   ├── project_presentation.pptx
│   ├── design_16_results.pptx
│   └── design_32_results.pptx
├── src/
│   ├── setup_packages.R
│   ├── data_processing/
│   │   └── generate_processed_data.py
│   ├── modeling/
│   └── design/
└── tableau/
    ├── README.md
    ├── dashboard.png
    ├── dashboard.pdf
    └── workbook/
        └── README.md
```

## Dashboard preview

![Anticancer Drug Combination Dashboard](tableau/dashboard.png)

## Quick start

### 1. Generate processed data

The SQL and Tableau layers now load from version-controlled CSVs under `data/processed/`.

```bash
python src/data_processing/generate_processed_data.py
```

This creates:
- `data/processed/modeling/` — model-ready derived tables
- `data/processed/sql/` — PostgreSQL load files
- `data/processed/dashboard/` — dashboard-facing summary tables

### 2. Run the R analysis

1. Open an R session in the repository root.
2. Install dependencies:
   ```r
   source("src/setup_packages.R")
   ```
3. Run a core modeling script, for example:
   ```r
   source("src/modeling/feature_scaling_models.R")
   ```

### 3. Build the PostgreSQL layer

#### Recommended: one-step `psql` setup

Run this **from the repository root** so the CSV paths resolve correctly:

```bash
psql -d drug_combo -f database/schema/00_full_setup.sql
```

This wrapper script does three things in order:
1. creates the `drug_combo` schema and base tables
2. loads CSVs from `data/processed/sql/` with `\copy`
3. creates the analytical views used in Tableau

Then validate the load:

```bash
psql -d drug_combo -f database/queries/validation_queries.sql
```

#### Alternative: pgAdmin / Query Tool

If you prefer pgAdmin, run these scripts in order:

1. `database/schema/00_schema.sql`
2. `database/schema/01_load_from_csv_pgadmin_template.sql`
3. `database/schema/02_views.sql`

For step 2, replace `__REPO_ROOT__` with the absolute path to your cloned repo. This uses server-side `COPY`, so it works only if the PostgreSQL server process can read those CSV files. If that is inconvenient, use the `psql` path above instead.

### 4. Open or rebuild the Tableau dashboard

Connect Tableau to the PostgreSQL database and use the prepared views in the `drug_combo` schema:

- `vw_dashboard_kpis`
- `vw_model_performance`
- `vw_top_combinations`
- `vw_vincristine_mitoxantrone_heatmap`
- `vw_best_drug_levels`

Static dashboard assets live in:
- `tableau/dashboard.png`
- `tableau/dashboard.pdf`

See `tableau/README.md` for workbook placement notes and the worksheet-by-worksheet build guidance.

## Suggested entry points

### Modeling
- `src/modeling/feature_scaling_models.R` — main comparison under feature scaling
- `src/modeling/studentized_residual_models.R` — main comparison under studentized residual normalization
- `src/modeling/stability_resampling.R` — repeated holdout experiment used to assess model stability

### Experimental design
- `src/design/search/` — scripts used to construct 16-point and 32-point candidate designs
- `src/design/evaluation/` — scripts that evaluate design candidates against the full dataset or held-out combinations

### Processed-data / SQL / BI layer
- `src/data_processing/generate_processed_data.py` — regenerates all derived CSVs under `data/processed/`
- `database/schema/00_full_setup.sql` — one-step `psql` setup using CSV-backed loads
- `database/schema/00_schema.sql` — schema + tables + indexes only
- `database/schema/01_load_from_csv_psql.sql` — `psql` loader using `\copy`
- `database/schema/01_load_from_csv_pgadmin_template.sql` — pgAdmin-friendly `COPY` template
- `database/schema/02_views.sql` — analytical view definitions
- `database/queries/validation_queries.sql` — sanity checks for tables and views
- `database/erd.md` — compact schema diagram

## Main analytical views for Tableau

The PostgreSQL layer exposes pre-aggregated views for dashboarding:

- `drug_combo.vw_dashboard_kpis` — KPI summary used for the dashboard cards
- `drug_combo.vw_model_performance` — model-level performance comparison
- `drug_combo.vw_top_combinations` — ranking of the lowest-viability combinations
- `drug_combo.vw_vincristine_mitoxantrone_heatmap` — VM pair dose-response grid
- `drug_combo.vw_best_drug_levels` — best-performing dose level summary by drug

## Key findings

- **Lasso Regression** and **Random Forest** consistently outperformed quadratic regression and the other baselines.
- **Vincristine-based combinations** were the strongest overall candidates for lowering leukemia cell viability.
- **Vincristine + Mitoxantrone** emerged as a particularly strong pair in both model-guided interpretation and dashboard-level exploratory analysis.
- The processed-data + SQL + Tableau extension makes the project easier to inspect, rebuild, and present as a complete analytics workflow rather than a scripts-only class project.

## Asset checklist for GitHub

To keep the SQL and Tableau parts visible on GitHub, keep these files in place:

- `tableau/dashboard.png` — screenshot / export used in this README preview
- `tableau/dashboard.pdf` — one-page PDF export of the dashboard
- `tableau/workbook/anticancer_drug_combination_dashboard.twbx` — optional packaged Tableau workbook
- `data/processed/sql/*.csv` — CSV-backed SQL load files
- `database/README.md` — SQL setup notes and object guide
- `database/queries/validation_queries.sql` — sanity checks for tables and views
- `database/erd.md` — schema diagram

If you update the dashboard, re-export `dashboard.png` and `dashboard.pdf` and overwrite the existing files.

## Portfolio framing

This repository is intended to demonstrate the ability to:
- reorganize an academic project into a professional GitHub repository
- perform statistical modeling and model comparison
- generate reproducible processed datasets for downstream tooling
- design a relational SQL layer for analytics and BI
- build a Tableau dashboard that communicates model and treatment-combination insights clearly
