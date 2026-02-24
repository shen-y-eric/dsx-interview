# =============================================================================
# Question 4, Part 2 — AE Visualizations
# =============================================================================
# Plot 1: AE severity distribution by treatment (stacked bar chart)
# Plot 2: Top 10 most frequent AEs with 95% Wilson CI for incidence rates
# Output: ae_severity_by_treatment.png, ae_top10_with_ci.png
# =============================================================================

library(dplyr, warn.conflicts = FALSE)
library(ggplot2)
library(tidyr)

# -----------------------------------------------------------------------------
# 1. Load and filter data
# -----------------------------------------------------------------------------
adsl <- pharmaverseadam::adsl %>%
  filter(SAFFL == "Y")

adae <- pharmaverseadam::adae %>%
  filter(TRTEMFL == "Y", SAFFL == "Y")

# Ensure severity is an ordered factor
adae <- adae %>%
  mutate(AESEV = factor(AESEV, levels = c("MILD", "MODERATE", "SEVERE")))

# =============================================================================
# Plot 1: AE Severity Distribution by Treatment
# =============================================================================
# Count AEs per severity per arm
sev_counts <- adae %>%
  count(ACTARM, AESEV, name = "n_aes")

p1 <- ggplot(sev_counts, aes(x = ACTARM, y = n_aes, fill = AESEV)) +
  geom_bar(stat = "identity", position = "stack", width = 0.7) +
  labs(
    title = "AE Severity Distribution by Treatment",
    x = "Treatment Arm",
    y = "Count of AEs",
    fill = "Severity"
  ) +
  theme_bw(base_size = 12) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(face = "bold", size = 13),
    legend.position = "right"
  )

ggsave("question_4_tlg/ae_severity_by_treatment.png", p1,
       width = 9, height = 6, dpi = 300)

cat("Plot 1 saved: question_4_tlg/ae_severity_by_treatment.png\n")

# =============================================================================
# Plot 2: Top 10 Most Frequent AEs with 95% CI
# =============================================================================
# Compute subject-level incidence per AE term across all arms
n_total <- n_distinct(adsl$USUBJID)

ae_incidence <- adae %>%
  group_by(AETERM) %>%
  summarise(n_subj = n_distinct(USUBJID), .groups = "drop") %>%
  slice_max(order_by = n_subj, n = 10) %>%
  mutate(
    incidence = n_subj / n_total
  )

# Clopper-Pearson 95% CI
ae_incidence <- ae_incidence %>%
  rowwise() %>%
  mutate(
    ci_lower = binom.test(n_subj, n_total)$conf.int[1],
    ci_upper = binom.test(n_subj, n_total)$conf.int[2]
  ) %>%
  ungroup() %>%
  mutate(AETERM = reorder(AETERM, incidence))

p2 <- ggplot(ae_incidence, aes(x = incidence, y = AETERM)) +
  geom_point(size = 3) +
  geom_errorbarh(
    aes(xmin = ci_lower, xmax = ci_upper),
    height = 0.25, linewidth = 0.7
  ) +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1),
                     expand = expansion(mult = c(0, 0.05))) +
  labs(
    title = "Top 10 Most Frequent Adverse Events",
    subtitle = paste0("n = ", n_total,
                      " subjects; 95% Clopper-Pearson CIs"),
    x = "Percentage of Patients",
    y = NULL
  ) +
  theme_bw(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 13),
    panel.grid.major.y = element_line(linetype = "dotted", color = "grey80")
  )

ggsave("question_4_tlg/output_files/ae_top10_with_ci.png", p2,
       width = 9, height = 6, dpi = 300)

cat("Plot 2 saved: question_4_tlg/ae_top10_with_ci.png\n")
