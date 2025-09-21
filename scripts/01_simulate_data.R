# Surgical Cognitive Data Simulation Script
# Purpose: Generate realistic second-by-second time-series data for 3-hour surgery
# Output: surgical_data.csv with cognitive states and sensor measurements

# 1. Load Libraries ----
library(tidyverse)
library(tibble)
library(zoo)

# 2. Define Simulation Parameters ----
duration_hours <- 3
seconds_per_hour <- 3600
total_seconds <- duration_hours * seconds_per_hour  # 10,800 seconds
n_surgeons <- 3
set.seed(123)  # For reproducibility

# Print simulation parameters
cat("Simulation Parameters:\n")
cat("Duration:", duration_hours, "hours\n")
cat("Total seconds:", total_seconds, "\n")
cat("Number of surgeons:", n_surgeons, "\n\n")

# 3. Create the Base Data Frame (tibble) ----
cat("Creating base data frame...\n")

# Create expanded grid for all surgeon-timestamp combinations
surgery_data <- tibble(
  surgeon_id = rep(1:n_surgeons, each = total_seconds),
  timestamp = rep(1:total_seconds, times = n_surgeons)
)

cat("Base data frame created with", nrow(surgery_data), "rows\n\n")

# 4. Simulate the Ground Truth Cognitive States ----
cat("Simulating cognitive states...\n")

# Define phase boundaries
phase1_end <- 900    # First 15 minutes
phase2_end <- 6300   # Next 1.5 hours (5400 seconds)
phase3_end <- 10800  # Remaining time

# Define attentional lapse windows (15-second periods during fatigue phase)
lapse_windows <- list(
  c(7000, 7015),
  c(8500, 8515),
  c(10000, 10015)
)

# Create cognitive state based on timestamp
surgery_data <- surgery_data %>%
  mutate(
    cognitive_state = case_when(
      # Check for attentional lapses first (within fatigued phase)
      timestamp >= 7000 & timestamp <= 7015 ~ "Attentional Lapse",
      timestamp >= 8500 & timestamp <= 8515 ~ "Attentional Lapse",
      timestamp >= 10000 & timestamp <= 10015 ~ "Attentional Lapse",
      # Then check for main phases
      timestamp <= phase1_end ~ "Optimal",
      timestamp <= phase2_end ~ "High Load",
      timestamp <= phase3_end ~ "Fatigued",
      TRUE ~ "Unknown"  # Fallback (shouldn't occur)
    )
  )

# Print cognitive state summary
cat("Cognitive state distribution:\n")
print(table(surgery_data$cognitive_state))
cat("\n")

# 5. Simulate Sensor Data Based on Cognitive State ----
cat("Simulating sensor data...\n")

# Generate sensor data based on cognitive state
surgery_data <- surgery_data %>%
  mutate(
    # Pupil diameter (mm)
    pupil_diameter_mm = case_when(
      cognitive_state == "Optimal" ~ rnorm(n(), mean = 3.5, sd = 0.2),
      cognitive_state == "High Load" ~ rnorm(n(), mean = 4.5, sd = 0.5),
      cognitive_state == "Fatigued" ~ rnorm(n(), mean = 3.0, sd = 0.3),
      cognitive_state == "Attentional Lapse" ~ rnorm(n(), mean = 2.8, sd = 0.2),
      TRUE ~ NA_real_
    ),
    
    # Grip force (Newtons)
    grip_force_newtons = case_when(
      cognitive_state == "Optimal" ~ rnorm(n(), mean = 15, sd = 0.5),
      cognitive_state == "High Load" ~ rnorm(n(), mean = 15, sd = 1.0),
      cognitive_state == "Fatigued" ~ rnorm(n(), mean = 13, sd = 2.0),
      cognitive_state == "Attentional Lapse" ~ rnorm(n(), mean = 13, sd = 4.0),
      TRUE ~ NA_real_
    ),
    
    # Instrument tremor (Hz)
    instrument_tremor_hz = case_when(
      cognitive_state == "Optimal" ~ rnorm(n(), mean = 1.0, sd = 0.2),
      cognitive_state == "High Load" ~ rnorm(n(), mean = 1.2, sd = 0.3),
      cognitive_state == "Fatigued" ~ rnorm(n(), mean = 2.0, sd = 0.6),
      cognitive_state == "Attentional Lapse" ~ rnorm(n(), mean = 2.2, sd = 0.8),
      TRUE ~ NA_real_
    )
  ) %>%
  # Ensure all sensor values are positive
  mutate(
    pupil_diameter_mm = pmax(pupil_diameter_mm, 1.0),  # Minimum 1mm
    grip_force_newtons = pmax(grip_force_newtons, 1.0),  # Minimum 1N
    instrument_tremor_hz = pmax(instrument_tremor_hz, 0.1)  # Minimum 0.1Hz
  )

# Print summary statistics for sensor data
# (Optional) Add temporal smoothing for more realistic signals ----
cat("Applying temporal smoothing...\n")

surgery_data <- surgery_data %>%
  group_by(surgeon_id) %>%
  mutate(
    # Apply a simple moving average to smooth the signals
    pupil_diameter_mm = zoo::rollmean(pupil_diameter_mm, k = 5, fill = NA, align = "right"),
    grip_force_newtons = zoo::rollmean(grip_force_newtons, k = 5, fill = NA, align = "right"),
    instrument_tremor_hz = zoo::rollmean(instrument_tremor_hz, k = 5, fill = NA, align = "right")
  ) %>%
  # The rolling mean introduces NAs at the start, let's fill them with the first valid value
  fill(pupil_diameter_mm, grip_force_newtons, instrument_tremor_hz, .direction = "up") %>%
  ungroup()

cat("Smoothing complete.\n\n")

# Print summary statistics for sensor data (after smoothing)
cat("Sensor data summary by cognitive state (after smoothing):\n")
surgery_data %>%
  group_by(cognitive_state) %>%
  summarise(
    n_observations = n(),
    mean_pupil = round(mean(pupil_diameter_mm), 2),
    mean_grip = round(mean(grip_force_newtons), 2),
    mean_tremor = round(mean(instrument_tremor_hz), 2),
    .groups = "drop"
  ) %>%
  print()

cat("\n")

# 6. Save the Final Dataset ----
cat("Saving dataset...\n")

# Ensure the output directory exists
output_dir <- "data/processed"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
  cat("Created directory:", output_dir, "\n")
}

# Save the dataset
output_file <- file.path(output_dir, "surgical_data.csv")
write_csv(surgery_data, output_file)

# Confirmation message
cat("✓ Dataset successfully saved to:", output_file, "\n")
cat("✓ Total observations:", nrow(surgery_data), "\n")
cat("✓ Columns:", ncol(surgery_data), "\n")
cat("✓ File size:", round(file.size(output_file) / 1024^2, 2), "MB\n")

# Display first few rows as preview
cat("\nDataset preview (first 10 rows):\n")
print(head(surgery_data, 10))

cat("\n--- Simulation Complete ---\n")