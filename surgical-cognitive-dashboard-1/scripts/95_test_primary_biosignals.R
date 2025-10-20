#!/usr/bin/env Rscript
# Minimal test to debug Primary Biosignals sparklines

library(dplyr)
library(readr)
library(gt)
library(gtExtras)

cat("🔍 Minimal test for Primary Biosignals sparklines...\n")

# Load demo data
data <- read_csv('inst/demo/demo_data_10min.csv', show_col_types = FALSE)
snapshot_idx <- round(nrow(data) * 0.5)
trend_start <- max(1, snapshot_idx - 99)
trend_end <- snapshot_idx

# Create the exact same data as the export script
features_now <- tibble(
  Feature = c(
    "Pupil Diameter",
    "Phasic Pupil (TEPR)",
    "Blink Rate",
    "Grip Force",
    "Grip CV%",
    "Time-on-Task",
    "Normal Prob",
    "High Load Prob",
    "Lapse Prob"
  ),
  Value = c(
    data$pupil_mm[snapshot_idx],
    0.25,  # Phasic Pupil (TEPR) - realistic value around baseline
    18.5,  # Blink Rate - realistic value around baseline  
    3.2,   # Grip Force - realistic value around baseline
    data$grip_cv_pct[snapshot_idx],
    data$time_min[snapshot_idx],
    # Derive probabilities from state
    ifelse(data$cognitive_state[snapshot_idx] == "Normal", 65, 30),
    ifelse(data$cognitive_state[snapshot_idx] == "High Load", 60, 25),
    ifelse(data$cognitive_state[snapshot_idx] == "Attentional Lapse", 55, 15)
  ),
  Unit = c("mm", "mm", "bpm", "N", "%", "min", "%", "%", "%"),
  group = c(
    "Primary Biosignals",
    "Primary Biosignals", 
    "Primary Biosignals",
    "Primary Biosignals",
    "Derived Metrics",
    "Derived Metrics",
    "Model Predictions",
    "Model Predictions",
    "Model Predictions"
  ),
  # Add trend data as lists
  Trend = list(
    data$pupil_mm[trend_start:trend_end],
    # Generate realistic TEPR trend (around 0.15 baseline with some variation)
    pmax(0, 0.15 + rnorm(length(trend_start:trend_end), 0, 0.05)),
    # Generate realistic Blink Rate trend (around 17 baseline with some variation)
    pmax(5, 17 + rnorm(length(trend_start:trend_end), 0, 3)),
    # Generate realistic Grip Force trend (around 3.0 baseline with some variation)
    pmax(1, 3.0 + rnorm(length(trend_start:trend_end), 0, 1)),
    data$grip_cv_pct[trend_start:trend_end],
    numeric(0),  # No trend for time-on-task
    numeric(0),  # No trend for probabilities
    numeric(0),
    numeric(0)
  )
)

cat("📊 Features data:\n")
print(features_now)

# Load reference ranges
refs <- read_csv('data/reference_ranges.csv', show_col_types = FALSE)

# Source the app's GT table utility function
source("R/gt_table_utils.R")

cat("\n📊 Building GT table with build_features_gt...\n")

# Build the GT table using the app's function
g <- build_features_gt(features_now, refs, personal = NULL)

cat("✅ GT table built successfully\n")

# Save test table
dir.create("case_study/tables", showWarnings = FALSE, recursive = TRUE)
gt::gtsave(g, "case_study/tables/test_primary_biosignals.html")

cat("✅ Test table saved to: case_study/tables/test_primary_biosignals.html\n")

# Also try to save as PNG
if (requireNamespace("webshot2", quietly = TRUE)) {
  tryCatch({
    gt::gtsave(g, "case_study/tables/test_primary_biosignals.png")
    cat("✅ Test PNG saved to: case_study/tables/test_primary_biosignals.png\n")
  }, error = function(e) {
    cat("⚠️ PNG save failed:", e$message, "\n")
  })
}

cat("🎉 Minimal test complete!\n")
