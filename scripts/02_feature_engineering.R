# Feature Engineering Script for Surgical Cognitive Data
# Purpose: Transform raw sensor data into machine learning features
# Input: data/processed/surgical_data.csv
# Output: data/processed/features_data.csv

# 1. Load Libraries ----
library(tidyverse)
library(zoo)

cat("Feature Engineering Script Started\n")
cat("==================================\n\n")

# 2. Load Data ----
cat("Loading surgical data...\n")

# Read the simulated surgical data
input_file <- "data/processed/surgical_data.csv"

if (!file.exists(input_file)) {
  stop("Error: ", input_file, " not found. Please run 01_simulate_data.R first.")
}

surgical_data <- read_csv(input_file, show_col_types = FALSE)

cat("✓ Data loaded successfully\n")
cat("  - Rows:", nrow(surgical_data), "\n")
cat("  - Columns:", ncol(surgical_data), "\n")
cat("  - Surgeons:", length(unique(surgical_data$surgeon_id)), "\n")
cat("  - Time range:", min(surgical_data$timestamp), "to", max(surgical_data$timestamp), "seconds\n\n")

# Display basic data structure
cat("Data structure:\n")
str(surgical_data)
cat("\n")

# 3. Engineer Rolling Window Features ----
cat("Creating rolling window features...\n")

features_data <- surgical_data %>%
  group_by(surgeon_id) %>%
  arrange(surgeon_id, timestamp) %>%  # Ensure proper ordering
  mutate(
    # 30-second rolling mean of pupil diameter (tonic level)
    tonic_pupil_level_30s = zoo::rollmean(
      pupil_diameter_mm, 
      k = 30, 
      fill = NA, 
      align = "right"
    ),
    
    # 15-second rolling standard deviation of grip force (variability)
    grip_force_variability_15s = zoo::rollapply(
      grip_force_newtons,
      width = 15,
      FUN = sd,
      fill = NA,
      align = "right"
    ),
    
    # 10-second rolling mean of tremor (trend)
    tremor_trend_10s = zoo::rollmean(
      instrument_tremor_hz,
      k = 10,
      fill = NA,
      align = "right"
    ),
    
    # (Advanced Feature) Phasic pupil change from a 5s baseline
    phasic_pupil_change_5s = pupil_diameter_mm - lag(zoo::rollmean(
      pupil_diameter_mm,
      k = 5,
      fill = NA,
      align = "right"
    ), n=1)
  ) %>%
  # Fill NA values at the beginning with first valid values for each surgeon
  fill(
    tonic_pupil_level_30s,
    grip_force_variability_15s,
    tremor_trend_10s,
    phasic_pupil_change_5s,
    .direction = "downup"
  ) %>%
  ungroup()

cat("✓ Rolling window features created:\n")
cat("  - tonic_pupil_level_30s: 30-second rolling mean of pupil diameter\n")
cat("  - grip_force_variability_15s: 15-second rolling SD of grip force\n")
cat("  - tremor_trend_10s: 10-second rolling mean of tremor\n")
cat("  - phasic_pupil_change_5s: pupil change from 5-second baseline (event-driven)\n\n")

# 4. Engineer Lag Features ----
cat("Creating lag features...\n")

features_data <- features_data %>%
  group_by(surgeon_id) %>%
  mutate(
    # 5-second lag of pupil diameter
    pupil_diameter_lag_5s = lag(pupil_diameter_mm, n = 5)
  ) %>%
  ungroup()

cat("✓ Lag features created:\n")
cat("  - pupil_diameter_lag_5s: pupil diameter from 5 seconds ago\n\n")

# Check for any remaining NA values
na_summary <- features_data %>%
  summarise(across(everything(), ~ sum(is.na(.))))

cat("NA values per column after feature engineering:\n")
print(na_summary)
cat("\n")

# 5. Save the Final Feature Dataset ----
cat("Cleaning and saving feature dataset...\n")

# Remove any rows that still contain NA values
initial_rows <- nrow(features_data)
features_data <- features_data %>%
  drop_na()

final_rows <- nrow(features_data)
removed_rows <- initial_rows - final_rows

cat("✓ Data cleaning completed:\n")
cat("  - Initial rows:", initial_rows, "\n")
cat("  - Rows removed (with NAs):", removed_rows, "\n")
cat("  - Final rows:", final_rows, "\n\n")

# Ensure output directory exists
output_dir <- "data/processed"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  cat("Created directory:", output_dir, "\n")
}

# Save the feature dataset
output_file <- file.path(output_dir, "features_data.csv")
write_csv(features_data, output_file)

cat("✓ Feature dataset saved successfully!\n")
cat("  - File path:", output_file, "\n")
cat("  - Dimensions:", nrow(features_data), "rows ×", ncol(features_data), "columns\n")
cat("  - File size:", round(file.size(output_file) / 1024^2, 2), "MB\n\n")

# Display feature summary by cognitive state
cat("Feature summary by cognitive state:\n")
feature_summary <- features_data %>%
  group_by(cognitive_state) %>%
  summarise(
    n_observations = n(),
    # Original sensors
    mean_pupil = round(mean(pupil_diameter_mm, na.rm = TRUE), 2),
    mean_grip = round(mean(grip_force_newtons, na.rm = TRUE), 2),
    mean_tremor = round(mean(instrument_tremor_hz, na.rm = TRUE), 2),
    # Engineered features
    mean_tonic_pupil = round(mean(tonic_pupil_level_30s, na.rm = TRUE), 2),
    mean_grip_variability = round(mean(grip_force_variability_15s, na.rm = TRUE), 3),
    mean_tremor_trend = round(mean(tremor_trend_10s, na.rm = TRUE), 2),
    mean_phasic_pupil = round(mean(phasic_pupil_change_5s, na.rm = TRUE), 3),
    mean_pupil_lag = round(mean(pupil_diameter_lag_5s, na.rm = TRUE), 2),
    .groups = "drop"
  )

print(feature_summary)

# Display first few rows as preview
cat("\nFeature dataset preview (first 10 rows):\n")
print(head(features_data, 10))

# Display column names for reference
cat("\nFinal feature columns:\n")
cat(paste(names(features_data), collapse = ", "), "\n")

cat("\n--- Feature Engineering Complete ---\n")