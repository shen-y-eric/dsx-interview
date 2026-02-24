"""
Test script for the ClinicalTrialDataAgent.

Runs 3 example queries and prints the results, demonstrating the full
Prompt → Parse → Execute flow.

Usage:
  python3 test_agent.py
"""

from clinical_agent import ClinicalTrialDataAgent


def main():
    agent = ClinicalTrialDataAgent()

    # -------------------------------------------------------------------------
    # Example queries
    # -------------------------------------------------------------------------
    questions = [
        "Give me the subjects who had adverse events of moderate severity",
        "Which patients experienced cardiac disorders?",
        "Show me all subjects with headache",
    ]

    for i, question in enumerate(questions, 1):
        print(f"\n{'='*70}")
        print(f"Query {i}: {question}")
        print("=" * 70)

        result = agent.ask(question)

        print(f"  Parsed → column: {result['parsed_query']['target_column']}, "
              f"value: {result['parsed_query']['filter_value']}")
        print(f"  Matching subjects: {result['count']}")

        # Show first 5 subject IDs
        if result["subjects"]:
            preview = result["subjects"][:5]
            suffix = f" ... and {result['count'] - 5} more" if result["count"] > 5 else ""
            print(f"  Subject IDs: {preview}{suffix}")
        else:
            print("  No matching subjects found.")

    print(f"\n{'='*70}")
    print("All queries completed.")


if __name__ == "__main__":
    main()
