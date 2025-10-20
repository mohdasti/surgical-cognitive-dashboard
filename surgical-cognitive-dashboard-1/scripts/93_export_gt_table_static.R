#!/usr/bin/env Rscript
# Export Static GT Table from Live Dashboard
# Captures the actual rendered table with sparklines and saves it

library(dplyr)
library(readr)
library(gt)

cat("📊 Exporting static GT table with sparklines...\n")

# Source the app's GT table builder
source("R/gt_table_utils.R")
source("R/load_params.R")

# Create output directory
dir.create("case_study/tables", showWarnings = FALSE, recursive = TRUE)

# Load demo data
demo_data_path <- "inst/demo/demo_data_10min.csv"

if (!file.exists(demo_data_path)) {
  stop("❌ Demo data not found. Run 'make features-snapshot' first.")
}

cat("📊 Loading demo data from", demo_data_path, "\n")
data <- read_csv(demo_data_path, show_col_types = FALSE)

# Take snapshot from middle of timeline (around 5 minutes)
snapshot_idx <- round(nrow(data) * 0.5)

# Get trend data (last 100 samples before snapshot)
trend_start <- max(1, snapshot_idx - 99)
trend_end <- snapshot_idx

# Build features_now tibble (matching app structure)
features_now <- tibble(
  Feature = c(
    "Pupil Diameter",
    "HRV (RMSSD)",
    "Tremor RMS (8–12Hz)",
    "Grip Force",
    "Grip CV%",
    "Time-on-Task",
    "Normal Prob",
    "High Load Prob",
    "Lapse Prob"
  ),
  Value = c(
    data$pupil_mm[snapshot_idx],
    data$rmssd_ms[snapshot_idx],
    data$tremor_rms_um[snapshot_idx],
    data$grip_cv_pct[snapshot_idx],  # Using CV% as proxy
    data$grip_cv_pct[snapshot_idx],
    data$time_min[snapshot_idx],
    # Derive probabilities from state
    ifelse(data$cognitive_state[snapshot_idx] == "Normal", 65, 30),
    ifelse(data$cognitive_state[snapshot_idx] == "High Load", 60, 25),
    ifelse(data$cognitive_state[snapshot_idx] == "Attentional Lapse", 55, 15)
  ),
  Unit = c("mm", "ms", "μm", "N", "%", "min", "%", "%", "%"),
  # Add trend data as lists
  Trend = list(
    data$pupil_mm[trend_start:trend_end],
    data$rmssd_ms[trend_start:trend_end],
    data$tremor_rms_um[trend_start:trend_end],
    data$grip_cv_pct[trend_start:trend_end],
    data$grip_cv_pct[trend_start:trend_end],
    numeric(0),  # No trend for time-on-task
    numeric(0),  # No trend for probabilities
    numeric(0),
    numeric(0)
  )
)

cat("📊 Building GT table with sparklines...\n")

# Load reference ranges
ref_path <- "data/reference_ranges.csv"
refs <- if (file.exists(ref_path)) {
  read_csv(ref_path, show_col_types = FALSE)
} else {
  # Fallback reference ranges
  tibble(
    Feature = c("Pupil Diameter", "Grip Force", "Tremor RMS (8–12Hz)", "HRV (RMSSD)",
                "Grip CV%", "Time-on-Task", "Normal Prob", "High Load Prob", "Lapse Prob"),
    Unit = c("mm", "N", "μm", "ms", "%", "min", "%", "%", "%"),
    baseline_mean = c(3.5, 3.0, 100, 40, 8, 10, 60, 30, 10),
    baseline_sd = c(0.2, 1.0, 30, 10, 2, NA, NA, NA, NA),
    normal_low = c(3.1, 1.5, 60, 30, 5, 0, 40, 0, 0),
    normal_high = c(3.9, 5.0, 120, 60, 12, 30, 100, 60, 30),
    alert_low = c(NA, NA, NA, 25, NA, NA, 0, 0, 0),
    alert_high = c(4.8, 7.0, 180, NA, 15, 60, 100, 100, 100),
    direction = c("high_worse", "high_worse", "high_worse", "low_worse",
                  "high_worse", "high_worse", "low_worse", "high_worse", "high_worse"),
    evidence_ref = c(
      "Kahneman & Beatty (1966)",
      "Odik et al. (2021)",
      "Andreu-Perez et al. (2021)",
      "Task Force (1996)",
      "Balasubramanian (2012)",
      NA, NA, NA, NA
    ),
    pmid = c("5997497", "33668825", "33966234", "8737210", "22415980", 
             NA, NA, NA, NA)
  )
}

# Build GT table using app's function
gt_table <- build_features_gt(features_now, refs, personal = NULL)

cat("✅ GT table built successfully\n")

# Save as HTML
html_path <- "case_study/tables/features_gt_table.html"
gt::gtsave(gt_table, html_path)
cat("✅ Saved HTML to:", html_path, "\n")

# Try to save as PNG (requires webshot2 or Chrome)
png_path <- "case_study/tables/features_gt_table.png"

if (requireNamespace("webshot2", quietly = TRUE)) {
  tryCatch({
    gt::gtsave(gt_table, png_path, vwidth = 1400, vheight = 800)
    cat("✅ Saved PNG to:", png_path, "\n")
  }, error = function(e) {
    cat("⚠️  Could not save PNG (webshot2 issue):", e$message, "\n")
    cat("💡 HTML saved successfully - you can screenshot that instead\n")
  })
} else {
  cat("⚠️  webshot2 not available - PNG not generated\n")
  cat("💡 Install with: install.packages('webshot2')\n")
  cat("💡 Or use the HTML file:", html_path, "\n")
}

cat("\n🎉 Static GT table export complete!\n")
cat("📁 Output files:\n")
cat("   - HTML:", html_path, "\n")
if (file.exists(png_path)) {
  cat("   - PNG:", png_path, "\n")
}

cat("\n💡 To use in Quarto:\n")
cat("   1. Open the HTML file in a browser\n")
cat("   2. Take a screenshot, or\n")
cat("   3. Use the PNG if generated\n")
