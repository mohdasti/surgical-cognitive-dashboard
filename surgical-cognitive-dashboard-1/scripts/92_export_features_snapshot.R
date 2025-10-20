#!/usr/bin/env Rscript
# Export Features Snapshot with Trends for Case Study GT Table
# Generates demo_features_snapshot.csv with trend data for Quarto integration

library(dplyr)
library(readr)

cat("📊 Generating features snapshot with trends for case study...\n")

# Create output directory
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)

# Check if we have real data
demo_data_path <- "inst/demo/demo_data_10min.csv"
has_real_data <- file.exists(demo_data_path)

if (has_real_data) {
  cat("📊 Using real demo data from", demo_data_path, "\n")
  data <- read_csv(demo_data_path, show_col_types = FALSE)
  
  # Take a snapshot from the middle of the timeline (around 5 minutes)
  snapshot_idx <- round(nrow(data) * 0.5)
  
  # Get last 100 samples for trend (about 20 seconds at 5Hz)
  trend_start <- max(1, snapshot_idx - 99)
  trend_end <- snapshot_idx
  
  # Extract trend data for each feature
  pupil_trend <- data$pupil_mm[trend_start:trend_end]
  hrv_trend <- data$rmssd_ms[trend_start:trend_end]
  tremor_trend <- data$tremor_rms_um[trend_start:trend_end]
  grip_trend <- data$grip_cv_pct[trend_start:trend_end]
  
  # Current values (at snapshot)
  pupil_current <- data$pupil_mm[snapshot_idx]
  hrv_current <- data$rmssd_ms[snapshot_idx]
  tremor_current <- data$tremor_rms_um[snapshot_idx]
  grip_current <- data$grip_cv_pct[snapshot_idx]
  
  # State probabilities (if available)
  if ("cognitive_state" %in% names(data)) {
    state <- data$cognitive_state[snapshot_idx]
    prob_normal <- ifelse(state == "Normal", 0.65, 0.30)
    prob_highload <- ifelse(state == "High Load", 0.60, 0.25)
    prob_lapse <- ifelse(state == "Attentional Lapse", 0.55, 0.15)
  } else {
    prob_normal <- 43.5
    prob_highload <- 40.5
    prob_lapse <- 16.0
  }
  
  time_on_task <- data$time_min[snapshot_idx]
  
} else {
  cat("📊 Generating synthetic demo data\n")
  set.seed(42)
  
  # Generate synthetic trends (100 samples)
  n_trend <- 100
  
  pupil_trend <- 3.5 + 0.2 * sin(seq(0, 2*pi, length.out = n_trend)) + rnorm(n_trend, 0, 0.05)
  hrv_trend <- 45 + 10 * sin(seq(0, 2*pi, length.out = n_trend)) + rnorm(n_trend, 0, 2)
  tremor_trend <- 78 + 15 * sin(seq(0, 2*pi, length.out = n_trend)) + rnorm(n_trend, 0, 5)
  grip_trend <- 9.0 + 2 * sin(seq(0, 2*pi, length.out = n_trend)) + rnorm(n_trend, 0, 0.5)
  
  # Current values (last point in trend)
  pupil_current <- tail(pupil_trend, 1)
  hrv_current <- tail(hrv_trend, 1)
  tremor_current <- tail(tremor_trend, 1)
  grip_current <- tail(grip_trend, 1)
  
  # State probabilities
  prob_normal <- 43.5
  prob_highload <- 40.5
  prob_lapse <- 16.0
  time_on_task <- 10.0
}

# Create snapshot dataframe with trend data
snapshot <- tibble(
  Feature = c(
    "Pupil Diameter",
    "Grip Force", 
    "Tremor RMS (8–12Hz)",
    "HRV (RMSSD)",
    "Grip CV%",
    "Time-on-Task",
    "Normal Prob",
    "High Load Prob",
    "Lapse Prob"
  ),
  Value = c(
    pupil_current,
    grip_current,  # Using grip CV% as a proxy for force
    tremor_current,
    hrv_current,
    grip_current,
    time_on_task,
    prob_normal,
    prob_highload,
    prob_lapse
  ),
  Unit = c("mm", "N", "μm", "ms", "%", "min", "%", "%", "%"),
  # Store trends as JSON arrays (will be parsed in Quarto)
  Trend = c(
    paste(round(pupil_trend, 3), collapse = ","),
    paste(round(grip_trend, 2), collapse = ","),
    paste(round(tremor_trend, 1), collapse = ","),
    paste(round(hrv_trend, 1), collapse = ","),
    paste(round(grip_trend, 2), collapse = ","),
    "",  # No trend for time-on-task
    "",  # No trend for probabilities
    "",
    ""
  )
)

# Save snapshot
output_path <- "data/processed/demo_features_snapshot.csv"
write_csv(snapshot, output_path)

cat("✅ Saved features snapshot to:", output_path, "\n")
cat("📊 Snapshot includes:\n")
cat("   - 9 features with current values\n")
cat("   - Trend data (100 samples) for biosignals\n")
cat("   - Ready for GT table with sparklines\n")

# Also create a version with explicit trend columns for easier parsing
snapshot_expanded <- snapshot %>%
  mutate(
    Trend_List = lapply(Trend, function(t) {
      if (nchar(t) > 0) {
        as.numeric(strsplit(t, ",")[[1]])
      } else {
        numeric(0)
      }
    })
  )

# Save as RDS for easier R loading
saveRDS(snapshot_expanded, "data/processed/demo_features_snapshot.rds")
cat("✅ Also saved as RDS with parsed trends\n")

cat("🎉 Features snapshot generation complete!\n")
