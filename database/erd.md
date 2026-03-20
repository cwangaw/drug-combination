# Entity relationship diagram

```mermaid
erDiagram
    DRUGS ||--o{ OBSERVATION_DOSES : appears_in
    OBSERVATIONS ||--o{ OBSERVATION_DOSES : contains
    MODEL_PERFORMANCE {
        text model_name PK
        text normalization PK
        numeric test_mse
        smallint rank_within_normalization
    }
    DRUGS {
        smallint drug_id PK
        text drug_key
        text drug_name
        numeric max_tested_dose
    }
    OBSERVATIONS {
        int observation_id PK
        numeric cell_viability
    }
    OBSERVATION_DOSES {
        int observation_id FK
        smallint drug_id FK
        numeric dose_level
    }
```

## Notes

- `observations` stores the experiment-level outcome.
- `observation_doses` normalizes the four dose columns into a long bridge table.
- `drugs` supplies the metadata needed for pivots, summaries, and Tableau filters.
- `model_performance` stores the reported benchmark metrics used in the model-comparison chart.
- The Tableau views in `00_full_setup.sql` sit on top of this compact schema and avoid doing heavy reshaping inside Tableau.
