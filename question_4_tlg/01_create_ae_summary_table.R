# =============================================================================
# Question 4, Part 1 — AE Summary Table (FDA Table 10 Style)
# =============================================================================
# Creates a treatment-emergent adverse events summary table using {gtsummary}.
#   Rows:    System Organ Class (AESOC) and AE Term (AETERM)
#   Columns: Treatment groups (ACTARM) + Overall
#   Cells:   n (%) with subject-level denominators from ADSL
#   Sorted by descending frequency
# Output:   ae_summary_table.html
# =============================================================================

library(dplyr, warn.conflicts = FALSE)
library(gtsummary)
library(gt)

# -----------------------------------------------------------------------------
# 1. Load and filter data
# -----------------------------------------------------------------------------
adsl <- pharmaverseadam::adsl %>%
  filter(SAFFL == "Y")

adae <- pharmaverseadam::adae %>%
  filter(TRTEMFL == "Y", SAFFL == "Y")

# Use ACTARM (actual treatment arm) as the column variable
# Ensure consistent factor ordering across table
arm_levels <- sort(unique(adsl$ACTARM))
adsl <- adsl %>% mutate(ACTARM = factor(ACTARM, levels = arm_levels))
adae <- adae %>% mutate(ACTARM = factor(ACTARM, levels = arm_levels))

# -----------------------------------------------------------------------------
# 2. Build hierarchical AE summary table
# -----------------------------------------------------------------------------
# Pre-sort ADAE by descending SOC frequency, then by descending AETERM
# frequency within each SOC — this ensures the table rows reflect the
# most common events first.
soc_order <- adae %>%
  group_by(AESOC) %>%
  summarise(soc_n = n_distinct(USUBJID), .groups = "drop") %>%
  arrange(desc(soc_n)) %>%
  pull(AESOC)

term_order <- adae %>%
  group_by(AETERM) %>%
  summarise(term_n = n_distinct(USUBJID), .groups = "drop") %>%
  arrange(desc(term_n)) %>%
  pull(AETERM)

adae <- adae %>%
  mutate(
    AESOC = factor(AESOC, levels = soc_order),
    AETERM = factor(AETERM, levels = term_order)
  )

# tbl_hierarchical counts unique subjects (via id = USUBJID) per SOC/AETERM,
# with denominator from adsl so percentages reflect the safety population.
tbl <- adae %>%
  tbl_hierarchical(
    variables = c(AESOC, AETERM),
    by = ACTARM,
    id = USUBJID,
    denominator = adsl,
    overall_row = TRUE,
    statistic = everything() ~ "{n} ({p}%)",
label = list(
      "..ard_hierarchical_overall.." ~ "Treatment-Emergent AEs",
      AESOC = "System Organ Class",
      AETERM = "AE Term"
    )
  ) %>%
  add_overall(last = TRUE) %>%
  bold_labels() %>%
  modify_header(label ~ "**Primary System Organ Class Reported Term for the Adverse Event**")

# -----------------------------------------------------------------------------
# 3. Save as HTML
# -----------------------------------------------------------------------------
tbl %>%
  as_gt() %>%
  gt::gtsave(filename = "ae_summary_table.html",
             path = "question_4_tlg/output_files")

cat("AE summary table saved to question_4_tlg/output_files/ae_summary_table.html\n")
