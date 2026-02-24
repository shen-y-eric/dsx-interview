# DSX Interview Project

This repository contains solutions for six clinical-programming interview tasks.

## Project Structure

- `question_1/descriptive_stats/`: R package implementing descriptive statistics utilities with tests.
- `question_2_sdtm/`: SDTM DS domain creation workflow.
- `question_3_adam/`: ADSL derivation using `admiral` and `pharmaversesdtm`.
- `question_4_tlg/`: AE summary table, listings, and visualization scripts.
- `question_5_api/`: FastAPI app for AE filtering and subject risk scoring.
- `question_6_genai/`: LLM-assisted clinical data query agent over ADAE data.

## Quick Start

### Python projects

For API and GenAI tasks:

```bash
cd question_5_api
pip install -r requirements.txt
```

```bash
cd ../question_6_genai
pip install -r requirements.txt
```

### Data prerequisites

Some tasks expect `adae.csv` generated from R scripts in this repo:

```bash
cd question_5_api
Rscript export_adae.R
```

## Run Highlights

- API (Question 5):

```bash
cd question_5_api
uvicorn main:app --reload
```

- GenAI assistant demo (Question 6):

```bash
cd question_6_genai
python test_agent.py
```
