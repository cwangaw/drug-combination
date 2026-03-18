# Data

`raw/drug_viability_data.csv` is the primary dataset used throughout the project.

## Columns

- `test#`: experiment index
- `vincristine`
- `mitoxantrone`
- `etoposide`
- `daunorubicin`
- `cell viability`

The modeling scripts engineer 10 additional quadratic/interaction terms from the four drug dosage columns.
