# Data

`raw/drug_viability_data.csv` is the primary dataset used throughout the project.

## Columns

- `test#`: experiment index
- `vincristine`
- `mitoxantrone`
- `etoposide`
- `daunorubicin`
- `cell viability`

The modeling scripts engineer 10 additional quadratic / interaction terms from the four drug dosage columns.

## Processed data

Run (with Python 3, `pandas`, and `numpy` available):

```bash
python src/data_processing/generate_processed_data.py
```

to create derived CSVs under `data/processed/` for three downstream uses:

- `data/processed/modeling/` — model-ready feature tables
- `data/processed/sql/` — PostgreSQL load files
- `data/processed/dashboard/` — dashboard-facing summary tables
