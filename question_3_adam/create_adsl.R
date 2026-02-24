# =============================================================================
# Question 3 — Create ADaM ADSL Dataset Using admiral
# =============================================================================
# Creates a Subject-Level Analysis Dataset (ADSL) from SDTM domains using
# the admiral package (pharmaverse). Derives six custom variables:
#   AGEGR9 / AGEGR9N  — Age group category and numeric code
#   TRTSDTM / TRTSTMF — Treatment start datetime with time imputation flag
#   ITTFL              — Intent-to-Treat population flag
#   ABNSBPFL           — Abnormal systolic blood pressure flag
#   LSTALVDT           — Last known alive date
#   CARPOPFL           — Cardiac disorder AE population flag
# =============================================================================

library(dplyr, warn.conflicts = FALSE)
library(stringr)
library(admiral)
library(pharmaversesdtm)

# -----------------------------------------------------------------------------
# 1. Load source SDTM domains
# -----------------------------------------------------------------------------
dm <- pharmaversesdtm::dm
vs <- pharmaversesdtm::vs
ex <- pharmaversesdtm::ex
ds <- pharmaversesdtm::ds
ae <- pharmaversesdtm::ae

# -----------------------------------------------------------------------------
# 2. Start ADSL from DM — bring in standard demographic variables
# -----------------------------------------------------------------------------
adsl <- dm %>%
  select(
    STUDYID, USUBJID, SUBJID, SITEID,
    AGE, AGEU, SEX, RACE, ETHNIC,
    ARM, ARMCD, ACTARM, ACTARMCD,
    RFSTDTC, RFENDTC, DTHDTC, DTHFL
  )

# -----------------------------------------------------------------------------
# 3. Derive AGEGR9 and AGEGR9N — age group categories
# -----------------------------------------------------------------------------
# "<18" = 1, "18 - 50" = 2, ">50" = 3
agegr9_definition <- exprs(
  ~condition,          ~AGEGR9,   ~AGEGR9N,
  AGE < 18,              "<18",          1,
  AGE >= 18 & AGE <= 50, "18 - 50",     2,
  AGE > 50,              ">50",         3
)

adsl <- adsl %>%
  derive_vars_cat(definition = agegr9_definition)

# -----------------------------------------------------------------------------
# 4. Derive TRTSDTM and TRTSTMF — first exposure datetime
# -----------------------------------------------------------------------------
# First, convert EX start datetimes with time imputation
ex_ext <- ex %>%
  derive_vars_dtm(
    dtc = EXSTDTC,
    new_vars_prefix = "EXST",
    highest_imputation = "h",
    time_imputation = "first"
  )

# Merge the earliest valid dose record per subject
adsl <- adsl %>%
  derive_vars_merged(
    dataset_add = ex_ext,
    filter_add = !is.na(EXSTDTM) &
      (EXDOSE > 0 | (EXDOSE == 0 & str_detect(EXTRT, regex("PLACEBO", ignore_case = TRUE)))),
    new_vars = exprs(TRTSDTM = EXSTDTM, TRTSTMF = EXSTTMF),
    order = exprs(EXSTDTM, EXSEQ),
    mode = "first",
    by_vars = exprs(STUDYID, USUBJID)
  )

# Also derive TRTSDT (date portion) for use in LSTALVDT comparison
adsl <- adsl %>%
  mutate(TRTSDT = as.Date(TRTSDTM))

# -----------------------------------------------------------------------------
# 5. Derive treatment end date (TRTEDT) — needed for LSTALVDT
# -----------------------------------------------------------------------------
ex_end <- ex %>%
  derive_vars_dtm(
    dtc = EXENDTC,
    new_vars_prefix = "EXEN",
    highest_imputation = "h",
    time_imputation = "last"
  )

adsl <- adsl %>%
  derive_vars_merged(
    dataset_add = ex_end,
    filter_add = !is.na(EXENDTM) &
      (EXDOSE > 0 | (EXDOSE == 0 & str_detect(EXTRT, regex("PLACEBO", ignore_case = TRUE)))),
    new_vars = exprs(TRTEDTM = EXENDTM),
    order = exprs(EXENDTM, EXSEQ),
    mode = "last",
    by_vars = exprs(STUDYID, USUBJID)
  ) %>%
  mutate(TRTEDT = as.Date(TRTEDTM))

# -----------------------------------------------------------------------------
# 6. Derive ITTFL — Intent-to-Treat flag
# -----------------------------------------------------------------------------
# "Y" if the subject was assigned a treatment arm, "N" otherwise
adsl <- adsl %>%
  mutate(ITTFL = if_else(!is.na(ARM) & ARM != "", "Y", "N"))

# -----------------------------------------------------------------------------
# 7. Derive ABNSBPFL — abnormal systolic blood pressure flag
# -----------------------------------------------------------------------------
# "Y" if any systolic BP reading in mmHg is <100 or >=140, "N" otherwise
adsl <- adsl %>%
  derive_var_merged_exist_flag(
    dataset_add = vs,
    by_vars = exprs(STUDYID, USUBJID),
    new_var = ABNSBPFL,
    condition = VSTESTCD == "SYSBP" & VSSTRESU == "mmHg" &
      !is.na(VSSTRESN) & (VSSTRESN < 100 | VSSTRESN >= 140),
    false_value = "N",
    missing_value = "N"
  )

# -----------------------------------------------------------------------------
# 8. Derive LSTALVDT — last known alive date
# -----------------------------------------------------------------------------
# Maximum complete date across: VS dates, AE start dates, DS dates, treatment
# end date.  Only complete date-parts qualify (highest_imputation = "n" means
# no imputation — partial dates like "2014-07" are excluded).  VS records must
# also have a valid result (VSSTRESN or VSSTRESC present).
# To avoid duplicate-event warnings in `derive_vars_extreme_event()`, collapse
# each SDTM source to one record per subject per complete date before combining.
vs_alive <- vs %>%
  mutate(VSDT = convert_dtc_to_dt(VSDTC, highest_imputation = "n")) %>%
  filter(!is.na(VSDT) & (!is.na(VSSTRESN) | !is.na(VSSTRESC))) %>%
  group_by(STUDYID, USUBJID, VSDT) %>%
  summarise(VSSEQ = suppressWarnings(min(VSSEQ, na.rm = TRUE)), .groups = "drop")

ae_alive <- ae %>%
  mutate(AESTDT = convert_dtc_to_dt(AESTDTC, highest_imputation = "n")) %>%
  filter(!is.na(AESTDT)) %>%
  group_by(STUDYID, USUBJID, AESTDT) %>%
  summarise(AESEQ = suppressWarnings(min(AESEQ, na.rm = TRUE)), .groups = "drop")

ds_alive <- ds %>%
  mutate(DSSTDT = convert_dtc_to_dt(DSSTDTC, highest_imputation = "n")) %>%
  filter(!is.na(DSSTDT)) %>%
  group_by(STUDYID, USUBJID, DSSTDT) %>%
  summarise(DSSEQ = suppressWarnings(min(DSSEQ, na.rm = TRUE)), .groups = "drop")

adsl <- adsl %>%
  derive_vars_extreme_event(
    by_vars = exprs(STUDYID, USUBJID),
    events = list(
      # Source 1: Vital signs dates (require a valid result)
      event(
        dataset_name = "vs_alive",
        condition = !is.na(VSDT),
        order = exprs(VSDT, VSSEQ),
        set_values_to = exprs(
          LSTALVDT = VSDT
        )
      ),
      # Source 2: Adverse event start dates
      event(
        dataset_name = "ae_alive",
        condition = !is.na(AESTDT),
        order = exprs(AESTDT, AESEQ),
        set_values_to = exprs(
          LSTALVDT = AESTDT
        )
      ),
      # Source 3: Disposition dates
      event(
        dataset_name = "ds_alive",
        condition = !is.na(DSSTDT),
        order = exprs(DSSTDT, DSSEQ),
        set_values_to = exprs(
          LSTALVDT = DSSTDT
        )
      ),
      # Source 4: Treatment end date (already derived in ADSL)
      event(
        dataset_name = "adsl",
        condition = !is.na(TRTEDT),
        set_values_to = exprs(
          LSTALVDT = TRTEDT
        )
      )
    ),
    source_datasets = list(vs_alive = vs_alive, ae_alive = ae_alive, ds_alive = ds_alive, adsl = adsl),
    tmp_event_nr_var = event_nr,
    order = exprs(LSTALVDT, event_nr),
    mode = "last",
    new_vars = exprs(LSTALVDT)
  )

# -----------------------------------------------------------------------------
# 9. Derive CARPOPFL — cardiac disorder AE population flag
# -----------------------------------------------------------------------------
# "Y" if the subject has any AE in SOC "CARDIAC DISORDERS", NA otherwise
adsl <- adsl %>%
  derive_var_merged_exist_flag(
    dataset_add = ae,
    by_vars = exprs(STUDYID, USUBJID),
    new_var = CARPOPFL,
    condition = toupper(AESOC) == "CARDIAC DISORDERS",
    false_value = NA_character_,
    missing_value = NA_character_
  )

# -----------------------------------------------------------------------------
# 10. Final variable selection and display
# -----------------------------------------------------------------------------
adsl <- adsl %>%
  select(
    # Standard ADSL variables from DM
    STUDYID, USUBJID, SUBJID, SITEID,
    AGE, AGEU, SEX, RACE, ETHNIC,
    ARM, ARMCD, ACTARM, ACTARMCD,
    DTHFL,
    # Derived variables
    AGEGR9, AGEGR9N,
    TRTSDTM, TRTSTMF, TRTSDT,
    TRTEDTM, TRTEDT,
    ITTFL,
    ABNSBPFL,
    LSTALVDT,
    CARPOPFL
  )

# Print summary
cat("ADSL dataset created:", nrow(adsl), "subjects\n\n")

cat("AGEGR9 distribution:\n")
print(table(adsl$AGEGR9, useNA = "ifany"))

cat("\nITTFL distribution:\n")
print(table(adsl$ITTFL, useNA = "ifany"))

cat("\nABNSBPFL distribution:\n")
print(table(adsl$ABNSBPFL, useNA = "ifany"))

cat("\nCARPOPFL distribution:\n")
print(table(adsl$CARPOPFL, useNA = "ifany"))

cat("\nLSTALVDT range:\n")
print(summary(adsl$LSTALVDT))

cat("\nFirst 10 rows of key derived variables:\n")
adsl %>%
  select(USUBJID, AGEGR9, AGEGR9N, TRTSDTM, TRTSTMF, ITTFL,
         ABNSBPFL, LSTALVDT, CARPOPFL) %>%
  head(10) %>%
  print()
