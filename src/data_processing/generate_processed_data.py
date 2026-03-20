#!/usr/bin/env python3
"""Generate processed datasets for the anticancer drug combination project.

This script reads the raw viability dataset, constructs model-ready feature
matrices, creates CSVs aligned with the PostgreSQL schema, and exports the
dashboard-facing summary tables used in the Tableau / SQL layer.

Run from anywhere:
    python src/data_processing/generate_processed_data.py
"""

from __future__ import annotations

from itertools import combinations
from pathlib import Path
from typing import Iterable

import numpy as np
import pandas as pd


DRUGS = pd.DataFrame(
    [
        {"drug_id": 1, "drug_key": "vincristine", "drug_name": "Vincristine", "max_tested_dose": 50.0},
        {"drug_id": 2, "drug_key": "mitoxantrone", "drug_name": "Mitoxantrone", "max_tested_dose": 40.0},
        {"drug_id": 3, "drug_key": "etoposide", "drug_name": "Etoposide", "max_tested_dose": 100.0},
        {"drug_id": 4, "drug_key": "daunorubicin", "drug_name": "Daunorubicin", "max_tested_dose": 75.0},
    ]
)

REPORTED_MODEL_PERFORMANCE = pd.DataFrame(
    [
        ("Quadratic Regression", "Feature scaling", 0.027247, 5),
        ("Ridge Regression", "Feature scaling", 0.004062, 3),
        ("Lasso Regression", "Feature scaling", 0.003252, 1),
        ("MLP", "Feature scaling", 0.004596, 4),
        ("Random Forest", "Feature scaling", 0.003298, 2),
        ("Quadratic Regression", "Studentized residual", 0.027247, 5),
        ("Ridge Regression", "Studentized residual", 0.003640, 3),
        ("Lasso Regression", "Studentized residual", 0.003251, 1),
        ("MLP", "Studentized residual", 0.005396, 4),
        ("Random Forest", "Studentized residual", 0.003471, 2),
    ],
    columns=["model", "normalization", "test_mse", "rank_within_normalization"],
)

DOSE_COLUMNS = ["vincristine", "mitoxantrone", "etoposide", "daunorubicin"]


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def read_raw_data(root: Path) -> pd.DataFrame:
    raw_path = root / "data" / "raw" / "drug_viability_data.csv"
    if not raw_path.exists():
        raise FileNotFoundError(f"Missing raw data file: {raw_path}")
    df = pd.read_csv(raw_path)
    return df.rename(columns={"test#": "experiment_id", "cell viability": "cell_viability"})


def ensure_dirs(paths: Iterable[Path]) -> None:
    for path in paths:
        path.mkdir(parents=True, exist_ok=True)


def build_feature_matrix(base_df: pd.DataFrame) -> pd.DataFrame:
    x = base_df.copy()
    matrix = pd.DataFrame(index=x.index)
    matrix["V"] = x["vincristine"]
    matrix["M"] = x["mitoxantrone"]
    matrix["E"] = x["etoposide"]
    matrix["D"] = x["daunorubicin"]
    # Match the original R loop ordering in the modeling scripts.
    matrix["VV"] = x["vincristine"] * x["vincristine"]
    matrix["VM"] = x["mitoxantrone"] * x["vincristine"]
    matrix["MM"] = x["mitoxantrone"] * x["mitoxantrone"]
    matrix["VE"] = x["etoposide"] * x["vincristine"]
    matrix["ME"] = x["etoposide"] * x["mitoxantrone"]
    matrix["EE"] = x["etoposide"] * x["etoposide"]
    matrix["VD"] = x["daunorubicin"] * x["vincristine"]
    matrix["MD"] = x["daunorubicin"] * x["mitoxantrone"]
    matrix["ED"] = x["daunorubicin"] * x["etoposide"]
    matrix["DD"] = x["daunorubicin"] * x["daunorubicin"]
    return matrix


def standardize_columns(df: pd.DataFrame) -> pd.DataFrame:
    # Use sample standard deviation (ddof=1) to mirror R's default scale().
    means = df.mean(axis=0)
    stds = df.std(axis=0, ddof=1).replace(0, np.nan)
    standardized = (df - means) / stds
    return standardized.fillna(0.0)


def feature_frames(df: pd.DataFrame) -> dict[str, pd.DataFrame]:
    clean = df[["experiment_id", *DOSE_COLUMNS, "cell_viability"]].copy()

    raw_doses = df[DOSE_COLUMNS].copy()
    scaled_doses = (raw_doses - raw_doses.min()) / (raw_doses.max() - raw_doses.min())
    standardized_doses = standardize_columns(raw_doses)

    frames = {}
    for name, doses in {
        "raw_doses": raw_doses,
        "feature_scaled": scaled_doses,
        "standardized": standardized_doses,
    }.items():
        matrix = build_feature_matrix(doses)
        frames[name] = pd.concat(
            [df[["experiment_id"]].reset_index(drop=True), matrix.reset_index(drop=True), df[["cell_viability"]].reset_index(drop=True)],
            axis=1,
        )

    return {"clean": clean, **frames}


def sql_frames(df: pd.DataFrame) -> dict[str, pd.DataFrame]:
    observations = df[["experiment_id", "cell_viability"]].rename(columns={"experiment_id": "observation_id"}).copy()

    dose_rows: list[dict[str, float | int]] = []
    for _, row in df.iterrows():
        obs_id = int(row["experiment_id"])
        for _, drug in DRUGS.iterrows():
            dose_rows.append(
                {
                    "observation_id": obs_id,
                    "drug_id": int(drug["drug_id"]),
                    "dose_level": float(row[drug["drug_key"]]),
                }
            )
    observation_doses = pd.DataFrame(dose_rows)

    return {
        "drugs": DRUGS.copy(),
        "observations": observations,
        "observation_doses": observation_doses,
        "model_performance_reported": REPORTED_MODEL_PERFORMANCE.rename(columns={"model": "model_name"}).copy(),
    }


def dashboard_frames(df: pd.DataFrame) -> dict[str, pd.DataFrame]:
    observations = df[["experiment_id", "cell_viability"]].rename(columns={"experiment_id": "observation_id"}).copy()

    # Drug-level summary and best levels.
    long_rows = []
    for _, row in df.iterrows():
        for _, drug in DRUGS.iterrows():
            long_rows.append(
                {
                    "experiment_id": int(row["experiment_id"]),
                    "drug_id": int(drug["drug_id"]),
                    "drug_key": drug["drug_key"],
                    "drug_name": drug["drug_name"],
                    "level": float(row[drug["drug_key"]]),
                    "cell_viability": float(row["cell_viability"]),
                }
            )
    long_df = pd.DataFrame(long_rows)

    drug_level_summary = (
        long_df.groupby(["drug_key", "drug_name", "level"], as_index=False)
        .agg(
            mean_cell_viability=("cell_viability", "mean"),
            median_cell_viability=("cell_viability", "median"),
            min_cell_viability=("cell_viability", "min"),
            max_cell_viability=("cell_viability", "max"),
            n_observations=("cell_viability", "size"),
        )
        .sort_values(["drug_key", "level"])
        .reset_index(drop=True)
    )
    for col in ["mean_cell_viability", "median_cell_viability", "min_cell_viability", "max_cell_viability"]:
        drug_level_summary[col] = drug_level_summary[col].round(6)

    best_drug_levels = (
        drug_level_summary.sort_values(["drug_key", "mean_cell_viability", "level"], ascending=[True, True, False])
        .assign(best_level_rank=lambda x: x.groupby("drug_key").cumcount() + 1)
        .query("best_level_rank == 1")
        .sort_values(["mean_cell_viability", "drug_name"])
        .reset_index(drop=True)
    )

    # Pair heatmap summary.
    pair_frames = []
    drug_info = DRUGS.set_index("drug_key").to_dict("index")
    for a, b in combinations(DOSE_COLUMNS, 2):
        grp = (
            df.groupby([a, b], as_index=False)
            .agg(
                mean_cell_viability=("cell_viability", "mean"),
                median_cell_viability=("cell_viability", "median"),
                min_cell_viability=("cell_viability", "min"),
                max_cell_viability=("cell_viability", "max"),
                n_observations=("cell_viability", "size"),
            )
            .rename(columns={a: "drug_a_level", b: "drug_b_level"})
        )
        grp["pair_key"] = f"{a} + {b}"
        grp["pair_name"] = f"{drug_info[a]['drug_name']} + {drug_info[b]['drug_name']}"
        grp["drug_a_key"] = a
        grp["drug_a_name"] = drug_info[a]["drug_name"]
        grp["drug_b_key"] = b
        grp["drug_b_name"] = drug_info[b]["drug_name"]
        for col in ["mean_cell_viability", "median_cell_viability", "min_cell_viability", "max_cell_viability"]:
            grp[col] = grp[col].round(6)
        pair_frames.append(
            grp[
                [
                    "pair_key",
                    "pair_name",
                    "drug_a_key",
                    "drug_a_name",
                    "drug_b_key",
                    "drug_b_name",
                    "drug_a_level",
                    "drug_b_level",
                    "mean_cell_viability",
                    "median_cell_viability",
                    "min_cell_viability",
                    "max_cell_viability",
                    "n_observations",
                ]
            ]
        )
    pair_heatmap_summary = pd.concat(pair_frames, ignore_index=True).sort_values(
        ["pair_name", "drug_a_level", "drug_b_level"]
    )
    vincristine_mitoxantrone_heatmap = (
        pair_heatmap_summary.query("pair_key == 'vincristine + mitoxantrone'")
        .rename(columns={"drug_a_level": "vincristine", "drug_b_level": "mitoxantrone"})
        [
            [
                "vincristine",
                "mitoxantrone",
                "mean_cell_viability",
                "median_cell_viability",
                "min_cell_viability",
                "max_cell_viability",
                "n_observations",
            ]
        ]
        .reset_index(drop=True)
    )

    # Model performance and top combinations mirror the SQL views.
    baseline = REPORTED_MODEL_PERFORMANCE.loc[
        REPORTED_MODEL_PERFORMANCE["model"] == "Quadratic Regression",
        ["normalization", "test_mse"],
    ].rename(columns={"test_mse": "baseline_quadratic_mse"})
    model_performance = (
        REPORTED_MODEL_PERFORMANCE.merge(baseline, on="normalization", how="left")
        .assign(
            mse_reduction_vs_quadratic_pct=lambda x: (
                100 * (x["baseline_quadratic_mse"] - x["test_mse"]) / x["baseline_quadratic_mse"]
            ).round(3)
        )
        .sort_values(["normalization", "rank_within_normalization"])
        .reset_index(drop=True)
    )

    top_combinations = df.copy()
    top_combinations["cell_viability_pct"] = (100 * top_combinations["cell_viability"]).round(2)
    top_combinations["combo_label"] = (
        "V="
        + top_combinations["vincristine"].astype(str)
        + " | M="
        + top_combinations["mitoxantrone"].astype(str)
        + " | E="
        + top_combinations["etoposide"].astype(str)
        + " | D="
        + top_combinations["daunorubicin"].astype(str)
    )
    top_combinations = top_combinations.sort_values(["cell_viability", "experiment_id"]).reset_index(drop=True)
    top_combinations["viability_rank"] = np.arange(1, len(top_combinations) + 1)
    top_combinations["efficacy_score"] = (1 - top_combinations["cell_viability"]).round(6)

    def combo_reason(row: pd.Series) -> str:
        if row["vincristine"] > 0 and row["mitoxantrone"] > 0:
            return "Includes Vincristine + Mitoxantrone"
        if row["vincristine"] > 0:
            return "Vincristine-based combination"
        if row["mitoxantrone"] > 0:
            return "Mitoxantrone-based combination"
        return "Non-VM combination"

    top_combinations["recommended_reason"] = top_combinations.apply(combo_reason, axis=1)

    best_model = model_performance.sort_values(["test_mse", "model"]).iloc[0]
    best_combo = top_combinations.sort_values(["cell_viability", "experiment_id"]).iloc[0]
    dashboard_kpis = pd.DataFrame(
        [
            {
                "n_combinations": int(len(observations)),
                "n_drugs": int(len(DRUGS)),
                "best_cell_viability": round(float(observations["cell_viability"].min()), 4),
                "avg_cell_viability": round(float(observations["cell_viability"].mean()), 4),
                "best_experiment_id": int(best_combo["experiment_id"]),
                "best_model": f"{best_model['model']} ({best_model['normalization']})",
                "best_test_mse": round(float(best_model["test_mse"]), 6),
            }
        ]
    )

    return {
        "drug_level_summary": drug_level_summary,
        "best_drug_levels": best_drug_levels,
        "pair_heatmap_summary": pair_heatmap_summary.reset_index(drop=True),
        "vincristine_mitoxantrone_heatmap": vincristine_mitoxantrone_heatmap,
        "model_performance": model_performance,
        "top_combinations": top_combinations,
        "dashboard_kpis": dashboard_kpis,
    }


def write_csv(df: pd.DataFrame, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=False)


def main() -> None:
    root = repo_root()
    processed_root = root / "data" / "processed"
    modeling_dir = processed_root / "modeling"
    sql_dir = processed_root / "sql"
    dashboard_dir = processed_root / "dashboard"
    ensure_dirs([modeling_dir, sql_dir, dashboard_dir])

    raw_df = read_raw_data(root)

    for name, frame in feature_frames(raw_df).items():
        write_csv(frame, modeling_dir / f"{name}.csv")

    for name, frame in sql_frames(raw_df).items():
        write_csv(frame, sql_dir / f"{name}.csv")

    for name, frame in dashboard_frames(raw_df).items():
        write_csv(frame, dashboard_dir / f"{name}.csv")

    print("Processed data generated in:")
    print(f"  {processed_root}")


if __name__ == "__main__":
    main()
