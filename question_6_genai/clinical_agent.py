"""
Question 6 — GenAI Clinical Data Assistant

A ClinicalTrialDataAgent that translates natural language questions about
adverse events into structured pandas queries using an LLM (OpenAI via
LangChain).

Flow: User Question → LLM parses intent → Structured JSON → Pandas filter → Results

Requires OPENAI_API_KEY environment variable to be set.
"""

import json
import re
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv

load_dotenv(Path(__file__).parent / ".env")

# ---------------------------------------------------------------------------
# 1. Schema definition — describes the AE dataset to the LLM
# ---------------------------------------------------------------------------
SCHEMA_DESCRIPTION = """
The adverse events dataset (adae) contains one row per adverse event per subject.
Key columns for querying:

- AESEV: Severity of the adverse event.
  Values: "MILD", "MODERATE", "SEVERE"
  Use when the user asks about severity, intensity, or seriousness level.

- AETERM: The reported term for the adverse event (e.g., "HEADACHE", "NAUSEA",
  "DIARRHOEA", "APPLICATION SITE ERYTHEMA").
  Use when the user asks about a specific condition, symptom, or event name.

- AESOC: Primary System Organ Class — the body system category.
  Values include: "CARDIAC DISORDERS", "SKIN AND SUBCUTANEOUS TISSUE DISORDERS",
  "GASTROINTESTINAL DISORDERS", "NERVOUS SYSTEM DISORDERS",
  "GENERAL DISORDERS AND ADMINISTRATION SITE CONDITIONS", etc.
  Use when the user asks about a body system, organ class, or broad category.

- AEREL: Relationship to study drug.
  Values: "RELATED", "NOT RELATED", "POSSIBLY RELATED", "PROBABLY RELATED"
  Use when the user asks about causality, drug relationship, or relatedness.

- ACTARM: Actual treatment arm.
  Values: "Placebo", "Xanomeline Low Dose", "Xanomeline High Dose"
  Use when the user asks about treatment group or drug arm.

- USUBJID: Unique Subject Identifier (used for counting subjects, not filtering).
"""

SYSTEM_PROMPT = f"""You are a clinical data query assistant. Given a user's natural language
question about adverse events, you must identify:
1. target_column: which column in the dataset to filter on
2. filter_value: what value to filter for

{SCHEMA_DESCRIPTION}

IMPORTANT RULES:
- For AESEV, always use uppercase values: "MILD", "MODERATE", "SEVERE"
- For AETERM, use uppercase (e.g., "HEADACHE", "NAUSEA")
- For AESOC, use uppercase and the full standard name (e.g., "CARDIAC DISORDERS")
- For AEREL, always use uppercase
- For ACTARM, use exact values: "Placebo", "Xanomeline Low Dose", "Xanomeline High Dose"
- filter_value should be a single string to match against the column
- Use partial/substring matching for AETERM and AESOC when the user is vague

Respond ONLY with a JSON object in this exact format (no other text):
{{"target_column": "<column_name>", "filter_value": "<value>"}}
"""


# ---------------------------------------------------------------------------
# 2. LLM query parsing
# ---------------------------------------------------------------------------
def _parse_with_llm(question: str) -> dict:
    """Use OpenAI via LangChain to parse a natural language question."""
    from langchain_openai import ChatOpenAI
    from langchain_core.messages import HumanMessage, SystemMessage

    llm = ChatOpenAI(model="gpt-5-mini", temperature=0)
    response = llm.invoke([
        SystemMessage(content=SYSTEM_PROMPT),
        HumanMessage(content=question),
    ])

    # Extract JSON from the response
    text = response.content.strip()
    # Handle cases where LLM wraps JSON in markdown code blocks
    if "```" in text:
        match = re.search(r"```(?:json)?\s*(.*?)```", text, re.DOTALL)
        if match:
            text = match.group(1).strip()

    try:
        return json.loads(text)
    except json.JSONDecodeError as exc:
        raise ValueError(
            f"LLM returned unparseable response: {text!r}"
        ) from exc


# ---------------------------------------------------------------------------
# 3. ClinicalTrialDataAgent
# ---------------------------------------------------------------------------
class ClinicalTrialDataAgent:
    """Agent that translates natural language questions into pandas queries.

    Args:
        data_path: Path to the adae.csv file.
        use_llm: If True, uses OpenAI via LangChain. If False, uses mock parser.
                 Defaults to auto-detect based on OPENAI_API_KEY.
    """

    def __init__(self, data_path: str | Path = None):
        if data_path is None:
            data_path = Path(__file__).parent / "adae.csv"

        self.df = pd.read_csv(data_path, low_memory=False)
        print(f"ClinicalTrialDataAgent initialized — mode: LLM (OpenAI)")
        print(f"  Dataset: {len(self.df)} rows, {self.df['USUBJID'].nunique()} subjects")

    def parse_question(self, question: str) -> dict:
        """Parse a natural language question into a structured query.

        Returns:
            dict with 'target_column' and 'filter_value' keys.
        """
        return _parse_with_llm(question)

    def execute_query(self, parsed: dict) -> dict:
        """Apply the parsed filter to the DataFrame.

        Args:
            parsed: dict with 'target_column' and 'filter_value'.

        Returns:
            dict with 'count' (unique subjects) and 'subjects' (list of IDs).
        """
        col = parsed["target_column"]
        val = parsed["filter_value"]

        if col not in self.df.columns:
            return {
                "count": 0,
                "subjects": [],
                "error": f"Column '{col}' not found in dataset.",
            }

        # Use case-insensitive substring matching for AETERM and AESOC
        # to handle partial matches (e.g., "HEADACHE" in "HEADACHE AGGRAVATED")
        if col in ("AETERM", "AESOC"):
            mask = self.df[col].str.contains(val, case=False, na=False)
        else:
            mask = self.df[col] == val

        filtered = self.df[mask]
        subjects = sorted(filtered["USUBJID"].dropna().unique().tolist())

        return {
            "count": len(subjects),
            "subjects": subjects,
        }

    def ask(self, question: str) -> dict:
        """End-to-end: parse a question and execute the query.

        Returns:
            dict with 'question', 'parsed_query', 'count', and 'subjects'.
        """
        parsed = self.parse_question(question)
        result = self.execute_query(parsed)

        response = {
            "question": question,
            "parsed_query": parsed,
            "count": result["count"],
            "subjects": result["subjects"],
        }

        if "error" in result:
            response["error"] = result["error"]

        return response
