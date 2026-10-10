# Hyperparameter Tuning Results — Random Forest

## Search configuration

- Method: `RandomizedSearchCV`
- Training data: chronological training period only
- Cross-validation: `TimeSeriesSplit(n_splits=3)`
- Iterations: 10
- Scoring metric: ROC-AUC
- Random state: 42
- Test set: untouched during tuning
- Class weighting tested: `None` and `balanced`

## Search space

- `n_estimators`: `randint(150, 401)`
- `max_depth`: `[None, 10, 15, 20, 25, 30]`
- `min_samples_split`: `randint(2, 11)`
- `min_samples_leaf`: `randint(1, 6)`
- `max_features`: `["sqrt", "log2"]`
- `class_weight`: `[None, "balanced"]`

## Best configuration

| Parameter | Best value |
|---|---|
| `class_weight` | `None` |
| `max_depth` | `20` |
| `max_features` | `log2` |
| `min_samples_leaf` | `1` |
| `min_samples_split` | `4` |
| `n_estimators` | `378` |

**Best mean cross-validation ROC-AUC:** `0.6963`

## Interpretation

The tuned Random Forest was retained as the final model because its held-out
test performance improved over the untuned Random Forest in F1, recall,
ROC-AUC and PR-AUC, while retaining a strong overall predictive profile.

This artifact records the tuning evidence from the executed final notebook;
it does not claim that the sampled search found a global optimum.
