# Statistical Analysis of Anticancer Drug Combinations

This repository packages a course project as a reproducible data-science case study. The project analyzes how combinations of **Vincristine**, **Mitoxantrone**, **Etoposide**, and **Daunorubicin** affect leukemia cell viability using statistical learning in **R**.

## Why this repo exists

The original project folder contained useful work, but it was not GitHub-ready: duplicated scripts, hidden R workspace files, course materials mixed with source code, and filenames that did not clearly communicate purpose. This version reorganizes the project into a portfolio-friendly structure that is easier for recruiters, hiring managers, and collaborators to understand.

## Project highlights

- Built models on **256 dosage combinations** of four anticancer drugs with **14 engineered features** (4 dosage terms + 10 interaction/quadratic terms).
- Compared **quadratic regression, ridge regression, lasso regression, multilayer perceptron, and random forest** under both **feature scaling** and **studentized-residual normalization**.
- Used **8-fold cross-validation**, test-set **MSE**, and repeated random holdout evaluation to compare model quality and stability.
- Found that **Lasso** and **Random Forest** were the strongest-performing models, with feature-scaling test MSE around **0.00325-0.00330** versus **0.02725** for quadratic regression.
- Identified **Vincristine-based combinations**, especially **Vincristine + Mitoxantrone (VM)**, as the most promising combinations for reducing leukemia cell viability, while also surfacing a caution that excessive Mitoxantrone may reduce efficacy.

## Repository structure

```text
anticancer-drug-combination-analysis/
├── README.md
├── .gitignore
├── data/
│   ├── README.md
│   └── raw/
│       └── drug_viability_data.csv
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
└── src/
    ├── setup_packages.R
    ├── modeling/
    └── design/
```

## Quick start

1. Open an R session in the repository root.
2. Install dependencies:
   ```r
   source("src/setup_packages.R")
   ```
3. Run a core analysis script, for example:
   ```r
   source("src/modeling/feature_scaling_models.R")
   ```

## Suggested entry points

- `src/modeling/feature_scaling_models.R` — main comparison under feature scaling.
- `src/modeling/studentized_residual_models.R` — main comparison under studentized residual normalization.
- `src/modeling/stability_resampling.R` — repeated holdout experiment used to assess model stability.
- `src/design/search/` — scripts used to construct 16-point and 32-point candidate designs.
- `src/design/evaluation/` — scripts that evaluate design candidates against the full dataset or held-out combinations.
