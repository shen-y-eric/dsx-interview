"""
Question 5 — Clinical Trial Data API (FastAPI)

Serves clinical trial adverse event data with three endpoints:
  GET  /                          → Welcome message
  POST /ae-query                  → Dynamic cohort filtering
  GET  /subject-risk/{subject_id} → Patient safety risk score

Run with:  uvicorn main:app --reload
"""

from pathlib import Path
from typing import Optional

import pandas as pd
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# ---------------------------------------------------------------------------
# 1. Load data
# ---------------------------------------------------------------------------
DATA_PATH = Path(__file__).parent / "adae.csv"

if not DATA_PATH.exists():
    raise FileNotFoundError(
        f"adae.csv not found at {DATA_PATH}. "
        "Run `Rscript export_adae.R` first to export the data."
    )

df = pd.read_csv(DATA_PATH, low_memory=False)

# ---------------------------------------------------------------------------
# 2. FastAPI app
# ---------------------------------------------------------------------------
app = FastAPI(
    title="Clinical Trial Data API",
    description="REST API for querying adverse event data and calculating patient risk scores.",
    version="1.0.0",
)


# ---------------------------------------------------------------------------
# 3. GET / — Welcome message
# ---------------------------------------------------------------------------
@app.get("/")
def root():
    """Return a JSON welcome message."""
    return {"message": "Clinical Trial Data API is running"}


# ---------------------------------------------------------------------------
# 4. POST /ae-query — Dynamic filtering
# ---------------------------------------------------------------------------
class AEQueryRequest(BaseModel):
    """Request body for the /ae-query endpoint.

    Both fields are optional. If a field is missing or null, that filter
    is ignored (all records are returned for that dimension).
    """

    severity: Optional[list[str]] = None
    treatment_arm: Optional[str] = None


@app.post("/ae-query")
def ae_query(request: AEQueryRequest):
    """Filter adverse events by severity and/or treatment arm.

    Returns the count of matching records and a list of unique subject IDs.
    """
    filtered = df.copy()

    # Filter by severity (AESEV) if provided
    if request.severity:
        filtered = filtered[filtered["AESEV"].isin(request.severity)]

    # Filter by treatment arm (ACTARM) if provided
    if request.treatment_arm:
        filtered = filtered[filtered["ACTARM"] == request.treatment_arm]

    unique_subjects = sorted(filtered["USUBJID"].dropna().unique().tolist())

    return {
        "count": len(filtered),
        "subjects": unique_subjects,
    }


# ---------------------------------------------------------------------------
# 5. GET /subject-risk/{subject_id} — Safety risk score
# ---------------------------------------------------------------------------
SEVERITY_WEIGHTS = {
    "MILD": 1,
    "MODERATE": 3,
    "SEVERE": 5,
}

RISK_CATEGORIES = [
    (5, "Low"),       # score < 5
    (15, "Medium"),   # 5 <= score < 15
]


def _risk_category(score: int) -> str:
    """Assign a risk category based on the total score."""
    for threshold, label in RISK_CATEGORIES:
        if score < threshold:
            return label
    return "High"  # score >= 15


@app.get("/subject-risk/{subject_id}")
def subject_risk(subject_id: str):
    """Calculate a safety risk score for a specific patient.

    Scoring: MILD = 1pt, MODERATE = 3pts, SEVERE = 5pts.
    Categories: Low (<5), Medium (5–14), High (>=15).
    """
    subject_aes = df[df["USUBJID"] == subject_id]

    if subject_aes.empty:
        raise HTTPException(
            status_code=404,
            detail=f"Subject '{subject_id}' not found in dataset.",
        )

    risk_score = int(
        subject_aes["AESEV"]
        .map(SEVERITY_WEIGHTS)
        .fillna(0)
        .sum()
    )

    return {
        "subject_id": subject_id,
        "risk_score": risk_score,
        "risk_category": _risk_category(risk_score),
    }
