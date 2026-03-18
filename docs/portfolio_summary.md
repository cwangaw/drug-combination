# Portfolio Summary

## One-line summary
Modeled leukemia cell viability across 256 four-drug dosage combinations using R-based statistical learning, showing that Lasso and Random Forest substantially outperformed quadratic regression and highlighting Vincristine + Mitoxantrone as a leading candidate combination.

## Resume-ready bullets

- Modeled leukemia cell viability across **256 dosage combinations** of four anticancer drugs using **Lasso, Random Forest, Ridge, MLP, and quadratic regression** on **14 engineered dosage-interaction features**.
- Tuned and compared models with **8-fold cross-validation**, **mean squared error (MSE)**, and repeated holdout evaluation to assess generalization and stability.
- Identified **Vincristine-based combinations**, especially **Vincristine + Mitoxantrone**, as the strongest candidates for lowering cell viability; top Lasso/Random Forest models achieved **test MSE ≈ 0.0033** versus **0.0272** for quadratic regression (about **88% lower**).

## GitHub description suggestion
R-based machine learning case study on anticancer drug combinations: feature engineering, cross-validation, model comparison, and design-of-experiments evaluation.
