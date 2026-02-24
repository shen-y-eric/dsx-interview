# Question 6 — GenAI Clinical Data Assistant

An LLM-powered agent that translates plain English questions about adverse
events into structured pandas queries.

## Setup

### 1. Export the data (requires R with pharmaverseadam)

```bash
Rscript ../question_5_api/export_adae.R
cp ../question_5_api/adae.csv .
```

### 2. Install Python dependencies

```bash
pip install -r requirements.txt
```

### 3. (Optional) Set OpenAI API key for live LLM mode

```bash
export OPENAI_API_KEY="sk-..."
```

If no key is set, the agent falls back to a rule-based mock parser.

## Run

```bash
python test_agent.py
```

This runs three example queries and prints the parsed query + results for each.

## Usage in Python

```python
from clinical_agent import ClinicalTrialDataAgent

agent = ClinicalTrialDataAgent()
result = agent.ask("Show me subjects with severe adverse events")
print(result)
```

## Architecture

```
User Question → LLM/Mock parses intent → {"target_column", "filter_value"} → Pandas filter → Results
```

- **LLM mode**: Uses GPT-4o-mini via LangChain for natural language parsing
- **Mock mode**: Rule-based keyword matching (no API key required)
- **Execution**: Pure pandas filtering, returns unique subject count + IDs
