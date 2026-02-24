# Export ADAE data from pharmaverseadam to CSV for use in the Python API
# Run this once: Rscript question_5_api/export_adae.R

library(pharmaverseadam)
write.csv(pharmaverseadam::adae, "question_5_api/adae.csv", row.names = FALSE)
cat("Exported", nrow(pharmaverseadam::adae), "rows to question_5_api/adae.csv\n")
