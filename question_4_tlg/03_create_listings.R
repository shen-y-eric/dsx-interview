# =============================================================================
# Question 4, Part 3 — AE Listings using {gtsummary}
# =============================================================================
# Creates a detailed listing of all treatment-emergent adverse events with:
#   Subject ID, Treatment, AE Term, Severity, Relationship, Start/End dates
# Filtered for treatment-emergent events, sorted by subject and event date.
# Uses gtsummary::tbl_listing() for regulatory-style patient data listings.
# Output: ae_listings.html
# =============================================================================

library(dplyr, warn.conflicts = FALSE)
library(gtsummary)

# -----------------------------------------------------------------------------
# 1. Load and filter data
# -----------------------------------------------------------------------------
adae <- pharmaverseadam::adae %>%
  filter(TRTEMFL == "Y")

# -----------------------------------------------------------------------------
# 2. Prepare listing data
# -----------------------------------------------------------------------------
listing_data <- adae %>%
  select(
    USUBJID,
    ACTARM,
    AETERM,
    AESEV,
    AEREL,
    ASTDT,
    AENDT
  ) %>%
  arrange(USUBJID, ASTDT, AETERM)
# -----------------------------------------------------------------------------
# 3. Create listing using gt
# -----------------------------------------------------------------------------
tbl <- listing_data %>%
  gt::gt() %>%
  gt::cols_label(
    USUBJID = "Unique Subject ID",
    ACTARM  = "Description of Actual Arm",
    AETERM  = "Reported Term for the Adverse Event",
    AESEV   = "Severity/Intensity",
    AEREL   = "Casuality",
    ASTDT   = "Start Date/Time of Adverse Event",
    AENDT   = "End Date/Time of Adverse Event"
  ) %>%
  gt::tab_header(
    title = gt::md("**Listing of Treatment-Emergent Adverse Events by Subject Excluding Screen Failure Patients**")
  )

# -----------------------------------------------------------------------------
# 4. Save as HTML
# -----------------------------------------------------------------------------
tbl %>%
  gt::gtsave(filename = "ae_listings.html",
             path = "question_4_tlg/output_files")

cat("AE listing saved to question_4_tlg/ae_listings.html\n")
