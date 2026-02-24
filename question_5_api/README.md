# Question 5 — Clinical Trial Data API

A FastAPI application that serves clinical trial adverse event data with
dynamic filtering and patient risk scoring.

## Setup

### 1. Export the data (requires R with pharmaverseadam)

```bash
Rscript export_adae.R
```

This creates `adae.csv` from `pharmaverseadam::adae`.

### 2. Install Python dependencies

```bash
pip install -r requirements.txt
```

### 3. Run the API

```bash
cd question_5_api
uvicorn main:app --reload
```

The API will be available at `http://127.0.0.1:8000`.
Interactive docs at `http://127.0.0.1:8000/docs`.

## Endpoints

### GET /

Returns a welcome message.

```json
{"message": "Clinical Trial Data API is running"}
```

### POST /ae-query

Filter adverse events by severity and/or treatment arm. Both filters are
optional — omit or set to null to skip a filter.

```bash
curl -X POST http://127.0.0.1:8000/ae-query \
  -H "Content-Type: application/json" \
  -d '{"severity": ["MILD", "MODERATE"], "treatment_arm": "Placebo"}'
```

Response:
```json
{
  "count": 42,
  "subjects": ["01-701-1015", "01-701-1023", ...]
}
```

### GET /subject-risk/{subject_id}

Calculate a safety risk score for a specific patient.

```bash
curl http://127.0.0.1:8000/subject-risk/01-701-1015
```

Response:
```json
{
  "subject_id": "01-701-1015",
  "risk_score": 8,
  "risk_category": "Medium"
}
```

Scoring: MILD = 1pt, MODERATE = 3pts, SEVERE = 5pts.
Categories: Low (<5), Medium (5–14), High (>=15).
Returns 404 if subject not found.
