source("scripts/00_setup.R")

need <- c(
  "data/processed/xgb_loso_models.rds",
  "data/processed/lapse_iso.rds",
  "data/diagnostics/calibration.rds",
  "data/diagnostics/loso_eval.rds",
  "data/diagnostics/model_artifacts.rds"
)

exists_map <- file.exists(need)
if (!all(exists_map)) {
  message("🔧 Preflight: missing artifacts → building tiny demo set...")
  if (!file.exists("data/processed/sim_stream.csv.gz")) {
    source("scripts/01_simulate_data.R")
  }
  source("scripts/02_feature_engineering.R")
  source("scripts/03_train_model.R")
  source("scripts/03b_lapse_detector.R")
  source("scripts/04_eval_LOSO.R")
  source("scripts/05_diagnostics_export.R")
}

post_map <- file.exists(need)
if (!all(post_map)) {
  miss <- need[!post_map]
  stop(paste0("❌ Preflight failed. Still missing:\n  - ", paste(miss, collapse="\n  - "),
              "\nCheck paths and rerun."))
}

cat("✅ Preflight OK. Artifacts present:\n")
for (p in need) cat("  •", p, "\n")


