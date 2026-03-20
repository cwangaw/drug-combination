# Tableau assets

This folder contains the static dashboard exports used on GitHub and the location for the Tableau workbook export.

## Files in this folder

- `dashboard.png` - README preview image
- `dashboard.pdf` - one-page PDF export of the final dashboard
- `workbook/anticancer_drug_combination_dashboard.twbx` - the Tableau workbook file


## PostgreSQL connection notes

Build the dashboard from the PostgreSQL views in the `drug_combo` schema:

- `vw_dashboard_kpis`
- `vw_model_performance`
- `vw_top_combinations`
- `vw_vincristine_mitoxantrone_heatmap`
- `vw_best_drug_levels`