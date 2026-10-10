# Meridian Retail Group — Customer Churn Data Science Capstone

## Project title
**Reducing Customer Churn at Meridian Retail Group: An End-to-End Data Science Investigation**

## 1. Project overview

This capstone investigates customer churn for a multi-channel retail/e-commerce business operating through its website, mobile app and physical stores.

The project covers the complete data-science workflow:

**Business understanding → data acquisition → Excel → SQL → Python → data cleaning → EDA → visualization → feature engineering → machine learning → model interpretation → current-customer scoring → FastAPI deployment.**

The analytical source of truth for EDA and machine learning is the validated **Phase 6 cleaned dataset**.

---

## 2. Business problem

Meridian wants to:

- quantify the extent of customer churn;
- understand behavioural and customer-experience patterns associated with churn;
- identify variables useful for predicting future churn;
- prioritize currently active customers for retention action;
- quantify customer value associated with churn risk; and
- demonstrate a deployable churn-prediction API.

The objective is not simply to maximize accuracy. Retention decisions must consider the business consequences of false positives and false negatives.

### Locked current-churn definition

For the **2026-07-01** snapshot:

- **Active:** at least one `Completed` order from **2026-01-02 through 2026-07-01**.
- **Churned:** no `Completed` order in that 180-day window, including customers with no completed-order history.

The machine-learning target is different: **future 180-day churn**, defined from historical prediction dates using only information available on or before each prediction date.

---

## 3. Dataset

Five supplied CSV datasets are included in `data/raw/`.

| Dataset | Raw rows | Final cleaned rows | Columns |
|---|---:|---:|---:|
| customers.csv | 6,090 | 6,090 | 14 |
| products.csv | 220 | 220 | 9 |
| orders.csv | 28,297 | 28,252 | 9 |
| order_items.csv | 73,505 | 73,405 | 5 |
| support_tickets.csv | 5,200 | 5,200 | 8 |

The final cleaned files are in `data/processed/`.

---

## 4. Final project structure

```text
Meridian_Retail_Capstone/
│
├── data/
│   ├── raw/
│   └── processed/
│
├── excel/
│   └── Meridian_Retail_Excel_Workbook_COMPLETED.xlsx
│
├── sql/
│   ├── schema.sql
│   ├── staging_schema.sql
│   ├── student_sql_tasks.sql
│   ├── phase4_sql_audit_and_cleaning.sql
│   ├── phase4_final_audit.sql
│   ├── phase4_schema.sql
│   ├── student_sql_tasks_completed.sql
│   └── meridian_retail_clean.db
│
├── notebooks/
│   ├── 01_data_acquisition.ipynb
│   ├── 02_data_cleaning.ipynb
│   ├── 03_eda_visualization.ipynb
│   ├── 04_feature_engineering.ipynb
│   ├── 05_modeling.ipynb
│   ├── 06_model_interpretation.ipynb
│   ├── supporting/
│   │   └── 05_python_data_processing_support.ipynb
│
├── models/
│   ├── tuned_random_forest_churn_pipeline.joblib
│   ├── model_metadata.json
│   ├── model_evaluation_results.csv
│   └── hyperparameter_tuning_results.md
│
├── api/
│   ├── app.py
│   ├── api_demo_example.json
│   └── requirements.txt
│
├── visualizations/
│   ├── matplotlib/
│   └── plotly/
│
├── reports/
│   ├── Meridian_Retail_Final_Technical_Report.docx
│   └── Meridian_Retail_Final_Presentation.pptx
│
├── docs/
│   └── Business_Understanding.docx
│
├── requirements.txt
├── .gitignore
├── .gitattributes
└── README.md
```


---

## 5. Installation

Recommended: Python 3.10+.

```bash
pip install -r requirements.txt
```

For the API only:

```bash
pip install -r api/requirements.txt
```

The project uses Pandas, NumPy, Matplotlib, Seaborn, Plotly, SciPy, scikit-learn, OpenPyXL, Joblib, FastAPI, Pydantic and Uvicorn.

---

## 6. Running the analysis

The notebooks should be understood as a staged workflow.

1. `01_data_acquisition.ipynb`
2. `02_data_cleaning.ipynb`
3. `03_eda_visualization.ipynb`
4. `04_feature_engineering.ipynb`
5. `05_modeling.ipynb`
6. `06_model_interpretation.ipynb`

The original project was developed in Google Colab. The source notebooks therefore retain the documented project-path convention used during the capstone. The final repository also contains the actual data, model, reports and exported visualizations.

The supporting Phase 5 Python notebook is retained under `notebooks/supporting/`.

---

## 7. SQL

The `sql/` directory contains the schema, staging schema, required student SQL tasks, cleaning/audit scripts and the final clean SQLite database.

The required SQL work covers:

- joins and filtering;
- aggregation and grouping;
- subqueries;
- `CASE` logic;
- customer spend analysis;
- churn labelling;
- safe update/delete logic;
- foreign-key/schema design; and
- index/performance reasoning.

The project documents the difference between Phase 4 SQL counts and Phase 6 analytical counts rather than silently reconciling them. Phase 6 is the EDA/ML source of truth.

---

## 8. Excel

The completed workbook is:

`excel/Meridian_Retail_Excel_Workbook_COMPLETED.xlsx`

It contains formula-based cleaning, state standardization, descriptive statistics, PivotTable/PivotChart work and a data-quality log.

---

## 9. Key EDA findings

At the 2026-07-01 snapshot:

- **6,090** customers were analysed.
- **4,072** were classified as churned.
- **2,018** were active.
- Overall churn rate: **66.86%**.

Median RFM differences:

| Measure | Active | Churned |
|---|---:|---:|
| Recency | 87 days | 454 days |
| Frequency | 5 | 4 |
| Monetary total | $6,981.66 | $5,426.34 |

Recency showed the strongest univariate separation, with a Mann–Whitney effect size of **r = 0.8301**.

Historical completed-order value associated with customers classified as churned was approximately **$23.61M**, or **61.17%** of total historical value. This is **historical customer value, not confirmed future revenue loss**.

---

## 10. Machine learning

### Target

Historical prediction dates run from **2021-07-01 through 2026-01-01**. For each prediction date, the model uses only information available on or before that date and predicts whether the customer will have no completed order in the following 180 days.

### Time-based evaluation

- Training: 2021-07 through 2024-12
- Validation: 2025-01 through 2025-06
- Test: 2025-07 through 2026-01

A time-based split was used to preserve chronology and reduce future-information leakage.

### Final model

**Tuned Random Forest Classifier**

Best configuration:

```text
class_weight = None
max_depth = 20
max_features = log2
min_samples_leaf = 1
min_samples_split = 4
n_estimators = 378
```

Tuning used `RandomizedSearchCV`, 10 sampled configurations and 3-fold `TimeSeriesSplit`, optimizing ROC-AUC.

Best mean cross-validation ROC-AUC: **0.6963**.

### Final test performance

| Metric | Tuned Random Forest |
|---|---:|
| Accuracy | 0.6863 |
| Balanced Accuracy | 0.5863 |
| Precision | 0.7225 |
| Recall | 0.8703 |
| F1 | 0.7895 |
| ROC-AUC | 0.6515 |
| PR-AUC | 0.7737 |

Confusion matrix:

```text
[[3624, 8362],
 [3243, 21767]]
```

Recall is important because a false negative represents a customer who churns but is missed for potential retention intervention. False positives also matter because they can consume campaign budget.

The tested validation thresholds produced the highest F1 at **0.50**, so 0.50 was retained for the final scoring workflow. A production threshold should ultimately be selected using campaign capacity and the relative costs of false positives and false negatives.

---

## 11. Model interpretation

Permutation importance on the validation period identified the strongest predictive contributions as:

1. `tenure_days`
2. `state`
3. `referral_source`
4. `frequency`
5. `monetary_total`
6. `membership_tier`
7. `preferred_channel`
8. `marketing_opt_in`
9. `monetary_average`
10. `recency_days`

These are **predictive associations, not causal effects**.

The model also included a neural-network comparison using scikit-learn MLP. The MLP validation results were weaker than the selected Random Forest on the principal discrimination metrics.

---

## 12. Current customer scoring

The final model scores **2,018 currently active customers** as of 2026-07-01.

Risk segments:

- **Very High:** probability >= 0.80
- **High:** 0.60–<0.80
- **Moderate:** 0.40–<0.60
- **Lower:** <0.40

The scoring file is:

`data/processed/current_customer_churn_scores_2026-07-01.csv`

`expected_value_at_risk` is calculated as:

```text
churn probability × historical monetary value
```

It is a scenario-based prioritization measure, not a guaranteed future revenue loss.

---

## 13. Deployment / API

The FastAPI application is:

`api/app.py`

Start it from the repository root:

```bash
uvicorn api.app:app --reload
```

The API provides:

- `GET /` — health/status response
- `POST /predict` — churn probability and classification

Example:

```bash
curl -X POST "http://127.0.0.1:8000/predict" \
  -H "Content-Type: application/json" \
  -d @api/api_demo_example.json
```

The recorded demonstration was validated with HTTP 200. Invalid inputs such as negative recency and satisfaction scores above 5 were rejected with HTTP 422.

The saved model is a complete preprocessing + Random Forest pipeline, so the API does not require a separately reconstructed preprocessing stage.

---

## 14. Reports and presentation

- `reports/Meridian_Retail_Final_Technical_Report.docx`
- `reports/Meridian_Retail_Final_Presentation.pptx`

The presentation follows the required business-focused order: problem → objectives → data → quality → EDA → visualization → ML → model comparison → final performance → model insights → recommendations → limitations → deployment → conclusion.

---

## 15. Standalone model evidence

The `models/` folder contains:

- `model_evaluation_results.csv` — validation/test model metrics that were actually recorded in the executed notebook.
- `hyperparameter_tuning_results.md` — RandomizedSearchCV configuration, search space, best parameters and CV score.
- `model_metadata.json` — final model configuration and selected test evidence.
- `tuned_random_forest_churn_pipeline.joblib` — saved final model pipeline.

---

## 16. Visualization outputs

The final executed notebook contained 24 presentation-ready charts:

- **22 static PNG** visualizations in `visualizations/matplotlib/`
- **2 interactive Plotly HTML** visualizations in `visualizations/plotly/`

The exported visuals preserve the charts from the executed Phase 7–9 notebook rather than creating new analyses.

---

## 17. Important limitations

- The dataset is synthetic and should be treated as a capstone demonstration.
- Historical versions of some customer-master attributes are not available.
- Some phone/name combinations suggest possible entity-resolution issues.
- Missing support satisfaction/resolution values were not treated as zero.
- Plausible outliers were retained rather than automatically deleted.
- Feature importance does not establish causation.
- Test ROC-AUC of 0.6515 indicates useful but imperfect ranking ability.
- The final test confusion matrix contains many false positives, so real campaign costs must be considered.
- Newer signup cohorts have had less exposure time.

---

## 18. GitHub note: model file size

The final `.joblib` model is approximately **373 MB**. GitHub does not accept an ordinary individual file of this size in a normal Git repository.

The repository therefore includes `.gitattributes` configured for **Git LFS** for `models/*.joblib`.

Before pushing the repository to GitHub, install/configure Git LFS and track the model file:

```bash
git lfs install
git lfs track "models/*.joblib"
git add .gitattributes
```

Then commit and push the project normally.

If Git LFS is not available, do **not** replace the final model with a different model merely to make the file smaller. The submitted model should remain the validated tuned Random Forest.

---

## 19. Capstone deliverable checklist

| Required deliverable | Final location |
|---|---|
| Business/Technical Report | `reports/Meridian_Retail_Final_Technical_Report.docx` |
| Excel workbook | `excel/Meridian_Retail_Excel_Workbook_COMPLETED.xlsx` |
| SQL scripts | `sql/` |
| Python notebooks/scripts | `notebooks/` |
| Cleaned datasets | `data/processed/` |
| EDA & visualization outputs | `visualizations/` + `03_eda_visualization.ipynb` |
| Final ML model | `models/tuned_random_forest_churn_pipeline.joblib` |
| Model evaluation results | `models/model_evaluation_results.csv` |
| Hyperparameter tuning results | `models/hyperparameter_tuning_results.md` |
| API/deployment code | `api/` |
| README | `README.md` |
| Final presentation | `reports/Meridian_Retail_Final_Presentation.pptx` |

---

## 20. Academic integrity / viva

The project is intended to be understood and defended by the student team. Be prepared to explain:

- why the 180-day churn definition was used;
- why current churn and future ML churn are different;
- why a time-based split was used;
- how target leakage was prevented;
- why recall, F1, ROC-AUC and PR-AUC were used;
- why the tuned Random Forest was selected;
- what false positives and false negatives mean for Meridian;
- why feature importance is not causal;
- why legitimate outliers were retained;
- why Phase 4 and Phase 6 row counts differ;
- why historical value at risk is not the same as guaranteed future revenue loss; and
- how the FastAPI endpoint uses the saved model.
