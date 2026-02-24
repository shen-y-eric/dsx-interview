# ==============================================================================
# 02_create_ds_domain.R
#
# Create the SDTM DS (Disposition) domain from raw clinical trial data using
# the {sdtm.oak} package.
#
# Input:   pharmaverseraw::ds_raw  (raw EDC disposition data)
# Output:  DS domain with variables: STUDYID, DOMAIN, USUBJID, DSSEQ, DSTERM,
#          DSDECOD, DSCAT, VISITNUM, VISIT, DSDTC, DSSTDTC, DSSTDY
# ==============================================================================

library(sdtm.oak)
library(pharmaverseraw)
library(pharmaversesdtm)
library(dplyr)

# ── 1. Load raw data and reference datasets ──────────────────────────────────

ds_raw <- pharmaverseraw::ds_raw
dm     <- pharmaversesdtm::dm

# ── 2. Study controlled terminology ──────────────────────────────────────────
# Load the full Controlled Terminology (CT) dataset. 
# Taken from https://github.com/pharmaverse/examples/blob/main/metadata/sdtm_ct.csv

study_ct <- read.csv("question_2_sdtm/metadata/sdtm_ct.csv")

# ── 3. Generate oak ID variables ─────────────────────────────────────────────
# Adds oak_id (row number), raw_source, and patient_number to the raw data.
# These three columns serve as the linking key for all sdtm.oak mapping calls.

ds_raw <- ds_raw %>%
  generate_oak_id_vars(
    pat_var = "PATNUM",
    raw_src = "ds_raw"
  )

# ── 4. Map topic variable: DSTERM ────────────────────────────────────────────
# DSTERM is the reported disposition term.
# Per aCRF: map from IT.DSTERM; override with OTHERSP when populated.
# In the raw data, IT.DSTERM is already NA when OTHERSP is filled in,
# so we map IT.DSTERM first, then coalesce with OTHERSP in step 6.

ds <- assign_no_ct(
  raw_dat = ds_raw,
  raw_var = "IT.DSTERM",
  tgt_var = "DSTERM",
  id_vars = oak_id_vars()
)

# ── 5. Map qualifier variables ───────────────────────────────────────────────

# DSDECOD: standardised disposition term via controlled terminology (C66727).
# IT.DSDECOD contains title-cased values that map to uppercase CDISC terms.
ds <- ds %>%
  assign_ct(
    raw_dat = ds_raw,
    raw_var = "IT.DSDECOD",
    tgt_var = "DSDECOD",
    ct_spec = study_ct,
    ct_clst = "C66727",
    id_vars = oak_id_vars()
  )

# DSDTC: disposition collection date/time (combine date + time columns).
# DSDTCOL is MM-DD-YYYY; DSTMCOL is HH:MM (or NA for date-only records).
ds <- ds %>%
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = c("DSDTCOL", "DSTMCOL"),
    tgt_var = "DSDTC",
    raw_fmt = c("m-d-y", "H:M"),
    id_vars = oak_id_vars()
  )

# DSSTDTC: disposition status start date (single date column, MM-DD-YYYY).
ds <- ds %>%
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = "IT.DSSTDAT",
    tgt_var = "DSSTDTC",
    raw_fmt = c("m-d-y"),
    id_vars = oak_id_vars()
  )

# ── 6. Key-join raw columns needed for derivations ──────────────────────────
# Instead of referencing ds_raw by position (fragile if row order changes),
# we join the columns we need on oak_id_vars — the authoritative row key.

raw_derivation_cols <- ds_raw %>%
  dplyr::select(
    oak_id, raw_source, patient_number,
    OTHERSP, IT.DSDECOD, INSTANCE, STUDY, PATNUM
  )

ds <- ds %>%
  dplyr::left_join(raw_derivation_cols, by = oak_id_vars())

# ── 7. Derive STUDYID and USUBJID from authoritative sources ────────────────
# Source STUDYID from the raw data's STUDY column (already key-joined above).
# Derive USUBJID by joining with DM — the authoritative subject-level domain.
# This ensures DS USUBJIDs exactly match DM for downstream joins (e.g. study day).

dm_ids <- dm %>%
  dplyr::transmute(
    # Extract PATNUM portion from USUBJID to use as join key.
    # DM USUBJID format: "01-701-1015" → PATNUM = "701-1015"
    PATNUM_DM = sub("^[^-]+-", "", USUBJID),
    STUDYID,
    USUBJID
  )

ds <- ds %>%
  dplyr::left_join(dm_ids, by = c("PATNUM" = "PATNUM_DM"))

# Fallback: if any subjects don't match DM (shouldn't happen), construct IDs
ds <- ds %>%
  dplyr::mutate(
    STUDYID = dplyr::coalesce(STUDYID, STUDY),
    USUBJID = dplyr::coalesce(USUBJID, paste0("01-", patient_number))
  )

# ── 8. Derive remaining SDTM variables ──────────────────────────────────────

ds <- ds %>%
  dplyr::mutate(
    DOMAIN = "DS",

    # -- OTHERSP override (aCRF General Notes) ---------------------------------
    # When OTHERSP is populated, it overrides both DSTERM and DSDECOD.
    # The aCRF explicitly states: if OTHERSP is not null, map OTHERSP to both
    # DSTERM and DSDECOD. IT.DSTERM and IT.DSDECOD are already NA for these
    # records in the raw data, so coalesce fills in the OTHERSP value.
    DSTERM  = toupper(dplyr::coalesce(DSTERM, OTHERSP)),
    DSDECOD = toupper(dplyr::coalesce(DSDECOD, OTHERSP)),

    # -- DSCAT (aCRF programming notes: three-way derivation) ------------------
    # "PROTOCOL MILESTONE" when the coded term indicates a milestone
    # "OTHER EVENT"        when the other-specify field is populated
    # "DISPOSITION EVENT"  for all standard disposition records
    DSCAT = dplyr::case_when(
      toupper(IT.DSDECOD) == "RANDOMIZED" ~ "PROTOCOL MILESTONE",
      !is.na(OTHERSP)                     ~ "OTHER EVENT",
      TRUE                                ~ "DISPOSITION EVENT"
    ),

    # -- Visit variable --------------------------------------------------------
    # Map VISIT from INSTANCE (title-case → uppercase)
    VISIT = toupper(INSTANCE)
  )

# ── 9. Derive VISITNUM from study visit metadata ────────────────────────────
# VISITNUM is study-specific. We derive the mapping from the SV (Subject Visits)
# domain, which contains the authoritative VISIT ↔ VISITNUM relationship.
# Guard against duplicates: assert 1:1 VISIT → VISITNUM, then join safely.

sv <- pharmaversesdtm::sv
visit_lu <- sv %>%
  dplyr::select(VISIT, VISITNUM) %>%
  dplyr::distinct()

# Verify the lookup is 1:1 (one VISITNUM per VISIT)
dup_visits <- visit_lu %>%
  dplyr::group_by(VISIT) %>%
  dplyr::filter(dplyr::n() > 1L)

if (nrow(dup_visits) > 0L) {
  warning(
    "SV domain has multiple VISITNUMs for the same VISIT; ",
    "keeping the smallest VISITNUM per VISIT.",
    call. = FALSE
  )
  visit_lu <- visit_lu %>%
    dplyr::group_by(VISIT) %>%
    dplyr::slice_min(VISITNUM, n = 1L, with_ties = FALSE) %>%
    dplyr::ungroup()
}

ds <- ds %>%
  dplyr::left_join(visit_lu, by = "VISIT")

# ── 10. Derive sequence number (DSSEQ) ──────────────────────────────────────
# Sequential integer within each subject, ordered by date then original row
# order (oak_id) as a deterministic tiebreaker.

ds <- ds %>%
  derive_seq(
    tgt_var  = "DSSEQ",
    rec_vars = c("USUBJID", "DSSTDTC", "DSTERM", "oak_id")
  )

# ── 11. Derive study day (DSSTDY) ───────────────────────────────────────────
# Study day = DSSTDTC - RFSTDTC (reference start date from DM domain).
# Follows SDTM day calculation rules (no day 0).

ds <- ds %>%
  derive_study_day(
    sdtm_in       = .,
    dm_domain     = dm,
    tgdt          = "DSSTDTC",
    refdt         = "RFSTDTC",
    study_day_var = "DSSTDY"
  )

# ── 12. Select final SDTM variables in standard order ────────────────────────

ds <- ds %>%
  dplyr::select(
    STUDYID, DOMAIN, USUBJID, DSSEQ, DSTERM, DSDECOD,
    DSCAT, VISITNUM, VISIT, DSDTC, DSSTDTC, DSSTDY
  )

# ── View result ──────────────────────────────────────────────────────────────

cat("DS domain created successfully.\n")
cat("Dimensions:", nrow(ds), "rows x", ncol(ds), "columns\n")
print(head(ds, 10))
