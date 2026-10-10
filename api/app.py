
from pathlib import Path

import joblib
import pandas as pd

from fastapi import FastAPI
from pydantic import BaseModel, Field


# ======================================================================
# APPLICATION SETUP
# ======================================================================

BASE_DIR = Path(__file__).resolve().parent.parent

MODEL_PATH = (
    BASE_DIR
    / "models"
    / "tuned_random_forest_churn_pipeline.joblib"
)


# Load the complete trained pipeline:
# preprocessing + tuned Random Forest
model = joblib.load(MODEL_PATH)


app = FastAPI(
    title="Meridian Customer Churn Prediction API",
    description=(
        "API for predicting future 180-day customer churn "
        "probability for Meridian Retail Group."
    ),
    version="1.0.0"
)


# ======================================================================
# INPUT SCHEMA
# ======================================================================

class CustomerInput(BaseModel):

    membership_tier: str
    preferred_channel: str
    state: str
    referral_source: str
    marketing_opt_in: str

    recency_days: float = Field(
        ge=0,
        description="Days since the most recent completed order."
    )

    frequency: float = Field(
        ge=0,
        description="Number of completed orders."
    )

    monetary_total: float = Field(
        ge=0,
        description="Total historical completed-order value."
    )

    monetary_average: float = Field(
        ge=0,
        description="Average historical completed-order value."
    )

    support_ticket_count: float = Field(
        ge=0,
        description="Number of support tickets."
    )

    satisfaction_average: float | None = Field(
        default=None,
        ge=1,
        le=5,
        description="Average recorded satisfaction score."
    )

    resolution_time_average: float | None = Field(
        default=None,
        ge=0,
        description="Average ticket resolution time in hours."
    )

    tenure_days: float = Field(
        ge=0,
        description="Customer tenure in days at prediction date."
    )


# ======================================================================
# HEALTH CHECK ENDPOINT
# ======================================================================

@app.get("/")
def root():

    return {
        "message": "Meridian Customer Churn Prediction API",
        "status": "running",
        "model": "Tuned Random Forest"
    }


# ======================================================================
# PREDICTION ENDPOINT
# ======================================================================

@app.post("/predict")
def predict_churn(customer: CustomerInput):

    # Convert validated request data into a dataframe.
    input_data = pd.DataFrame(
        [customer.model_dump()]
    )

    # Generate probability of class 1:
    # future 180-day churn.
    churn_probability = float(
        model.predict_proba(input_data)[0, 1]
    )

    # Use the established 0.50 classification threshold.
    predicted_churn = int(
        churn_probability >= 0.50
    )

    predicted_status = (
        "Predicted Churn"
        if predicted_churn == 1
        else "Predicted Active"
    )

    return {
        "churn_probability": round(
            churn_probability,
            4
        ),
        "predicted_churn": predicted_churn,
        "predicted_status": predicted_status,
        "classification_threshold": 0.50
    }
