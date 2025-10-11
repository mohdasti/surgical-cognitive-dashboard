#' Enhanced Biosignal Simulation with Realistic Dynamics
#' 
#' Simulates multi-modal biosignals (pupil, grip, tremor, HRV, blinks) with
#' literature-validated parameters and realistic time-on-task effects.
#'
#' Features:
#' - Tonic pupil drift with fatigue (Wu 2019, Beatty 1982)
#' - Phasic TEPR spikes under cognitive load (Kahneman & Beatty 1966)
#' - Slow hippus oscillations (0.05-0.3 Hz)
#' - Grip force with stress spikes and CV increase (Johansson & Westling 1984)
#' - Nonlinear tremor growth (Elble & Koller 1990, Riviere et al. 1997)
#' - HRV modulation with load episodes (De Louche et al. 2024)
#' - Realistic class imbalance (lapses rare)
#'
#' @export

# Setup
source("scripts/00_setup.R")
source("R/load_params.R")
source("R/hrv_utils.R")
source("R/tremor_utils.R")
source("R/grip_utils.R")
source("R/blink_utils.R")

# Load parameters
params <- load_params("config/parameters.yml")

cat("=== Enhanced Biosignal Simulation ===\n")
cat(sprintf("Duration: %ds (%.1f min)\n", params$simulation$duration_s, 
            params$simulation$duration_s / 60))
cat(sprintf("Sampling: %d Hz\n", params$simulation$sampling_hz))
cat(sprintf("Surgeons: %d\n", params$simulation$num_surgeons))
cat(sprintf("Lapse rate: %.3f\n", params$simulation$lapse_rate))
cat(sprintf("High load rate: %.3f\n\n", params$simulation$high_load_rate))

#' Generate Per-Surgeon Parameters
#'
#' Creates individual baselines with realistic inter-subject variability
generate_surgeon_params <- function(surgeon_id, params) {
  list(
    surgeon_id = surgeon_id,
    
    # Pupil parameters
    pupil_baseline_mm = rnorm(1, params$pupil$baseline_mm_mean, 
                              params$pupil$baseline_mm_sd),
    pupil_reactivity = runif(1, 0.7, 1.3),  # Individual TEPR magnitude scaling
    
    # Grip parameters  
    grip_baseline_N = rnorm(1, params$grip$baseline_N_mean, 
                           params$grip$baseline_N_sd),
    grip_cv_fresh = runif(1, params$grip$cv_fresh_pct * 0.8, 
                         params$grip$cv_fresh_pct * 1.2),
    
    # Tremor parameters
    tremor_baseline_um = rnorm(1, params$tremor$rms_um_mean, 
                              params$tremor$rms_um_sd),
    tremor_band_hz = params$tremor$band_hz,
    
    # HRV parameters
    hrv_sdnn_baseline = rnorm(1, params$hrv$sdnn_ms_baseline, 10),
    hrv_rmssd_baseline = rnorm(1, params$hrv$rmssd_ms_baseline, 8),
    
    # Blink parameters
    blink_rate_baseline = runif(1, 12, 18)
  )
}

#' Simulate Cognitive State Sequence
#'
#' Generates state labels with realistic transitions and durations
simulate_states <- function(n_samples, params) {
  states <- rep("Normal", n_samples)
  
  # High Load episodes (15% of time, 30-300s duration)
  n_high_load <- floor(n_samples * params$simulation$high_load_rate)
  for (i in seq_len(n_high_load)) {
    start <- sample(1:(n_samples - 300), 1)
    duration <- sample(30:300, 1)
    end <- min(n_samples, start + duration)
    states[start:end] <- "High Load"
  }
  
  # Attentional Lapses (0.2% of time, 3-15s duration, RARE)
  n_lapses <- max(1, floor(n_samples * params$simulation$lapse_rate))
  for (i in seq_len(n_lapses)) {
    start <- sample(1:(n_samples - 15), 1)
    duration <- sample(3:15, 1)
    end <- min(n_samples, start + duration)
    # Only mark as lapse if not already high load (lapse is worse)
    states[start:end] <- "Attentional Lapse"
  }
  
  return(factor(states, levels = c("Normal", "High Load", "Attentional Lapse")))
}

#' Simulate Pupil Diameter with Realistic Dynamics
#'
#' Includes tonic drift, phasic TEPR, and slow hippus oscillations
simulate_pupil <- function(n, time_s, state, surgeon_params, params) {
  
  # Tonic baseline with fatigue drift
  fatigue_min <- time_s / 60
  fatigue_drop <- params$pupil$fatigue_baseline_drop_mm_per_hr * (fatigue_min / 60)
  tonic <- surgeon_params$pupil_baseline_mm - fatigue_drop
  
  # Phasic TEPR spikes on high load/lapse transitions
  phasic <- numeric(n)
  state_numeric <- as.numeric(state)
  transitions <- which(diff(c(1, state_numeric)) != 0)
  
  for (trans_idx in transitions) {
    if (state[trans_idx] %in% c("High Load", "Attentional Lapse")) {
      # TEPR: 0.3-0.5mm dilation with 300-3000ms latency
      latency_samples <- round(runif(1, 0.3, 3) * params$simulation$sampling_hz)
      tepr_magnitude <- runif(1, params$pupil$tepr_delta_mm_low, 
                             params$pupil$tepr_delta_mm_high) * 
                       surgeon_params$pupil_reactivity
      
      # Exponential decay over ~2s
      decay_samples <- round(2 * params$simulation$sampling_hz)
      start_idx <- trans_idx + latency_samples
      end_idx <- min(n, start_idx + decay_samples)
      
      if (start_idx <= n) {
        decay_curve <- seq(tepr_magnitude, 0, length.out = end_idx - start_idx + 1)
        phasic[start_idx:end_idx] <- phasic[start_idx:end_idx] + decay_curve
      }
    }
  }
  
  # Slow hippus oscillations (0.05-0.3 Hz)
  hippus_freqs <- runif(2, params$pupil$hippus_power_band_hz[1], 
                        params$pupil$hippus_power_band_hz[2])
  hippus <- 0.05 * sin(2 * pi * hippus_freqs[1] * time_s) +
            0.03 * sin(2 * pi * hippus_freqs[2] * time_s)
  
  # High-frequency noise
  noise <- rnorm(n, 0, 0.05)
  
  # Combine components
  pupil <- tonic + phasic + hippus + noise
  
  # Physiological bounds
  pupil <- pmax(2.0, pmin(8.0, pupil))
  
  return(pupil)
}

#' Simulate Grip Force with Stress Spikes and Fatigue
simulate_grip <- function(n, time_s, state, surgeon_params, params) {
  
  # Baseline force varies by state
  baseline <- case_when(
    state == "Normal" ~ surgeon_params$grip_baseline_N,
    state == "High Load" ~ surgeon_params$grip_baseline_N * 1.15,
    state == "Attentional Lapse" ~ surgeon_params$grip_baseline_N * 0.8
  )
  
  # CV increases with fatigue
  fatigue_min <- time_s / 60
  cv_current <- grip_cv_fatigue_model(fatigue_min, 
                                      surgeon_params$grip_cv_fresh,
                                      params$grip$cv_fatigued_pct)
  sd_force <- baseline * (cv_current / 100)
  
  # Base signal with noise
  grip <- baseline + rnorm(n, 0, sd_force)
  
  # Add stress spikes (5-20s duration, +1-2N magnitude)
  n_spikes <- floor(n * 0.02)  # 2% of time
  for (i in seq_len(n_spikes)) {
    start <- sample(1:n, 1)
    duration_s <- runif(1, params$grip$stress_spike_duration_s_min,
                        params$grip$stress_spike_duration_s_max)
    duration_samples <- round(duration_s * params$simulation$sampling_hz)
    end <- min(n, start + duration_samples)
    
    spike_magnitude <- runif(1, params$grip$stress_spike_N_min, 
                            params$grip$stress_spike_N_max)
    grip[start:end] <- grip[start:end] + spike_magnitude
  }
  
  # Physiological bounds
  grip <- pmax(0.5, pmin(15, grip))
  
  return(grip)
}

#' Simulate Tremor with Nonlinear Fatigue Growth
simulate_tremor <- function(n, time_s, state, surgeon_params, params) {
  
  # Nonlinear fatigue growth
  fatigue_min <- time_s / 60
  expected_rms <- tremor_fatigue_model(
    fatigue_min,
    surgeon_params$tremor_baseline_um,
    params$tremor$growth_pct_first_30min,
    params$tremor$growth_pct_per_hr_after
  )
  
  # State modulation (stress increases tremor)
  state_multiplier <- case_when(
    state == "Normal" ~ 1.0,
    state == "High Load" ~ 1.15,
    state == "Attentional Lapse" ~ 1.25
  )
  
  tremor_rms <- expected_rms * state_multiplier
  
  # Add variability
  tremor_rms <- tremor_rms + rnorm(n, 0, surgeon_params$tremor_baseline_um * 0.15)
  
  # Physiological bounds
  tremor_rms <- pmax(20, pmin(300, tremor_rms))
  
  return(tremor_rms)
}

#' Simulate HRV with Load-Dependent Modulation
#'
#' Generates RR intervals with SDNN/RMSSD decrease during cognitive load
simulate_hrv <- function(n_samples, time_s, state, surgeon_params, params) {
  
  # Base heart rate (~60 BPM = 1000ms RR)
  baseline_rr <- 1000
  
  # State-dependent modulation
  # High load/lapse: decrease HRV by 20-40%
  hrv_drop <- case_when(
    state == "Normal" ~ 0,
    state == "High Load" ~ runif(n_samples, 
                                  params$hrv$load_sdnn_drop_pct / 100,
                                  params$hrv$load_sdnn_drop_pct_max / 100),
    state == "Attentional Lapse" ~ runif(n_samples,
                                         params$hrv$load_rmssd_drop_pct / 100,
                                         params$hrv$load_rmssd_drop_pct_max / 100)
  )
  
  # Current RMSSD (baseline * (1 - drop))
  current_rmssd <- surgeon_params$hrv_rmssd_baseline * (1 - hrv_drop)
  
  # Generate RR intervals
  # Approximate RR from RMSSD using autocorrelation model
  rr_intervals <- numeric(n_samples)
  rr_intervals[1] <- baseline_rr
  
  for (i in 2:n_samples) {
    # AR(1) model for RR intervals
    innovation <- rnorm(1, 0, current_rmssd[i] / sqrt(2))
    rr_intervals[i] <- baseline_rr + 0.7 * (rr_intervals[i-1] - baseline_rr) + innovation
  }
  
  # Physiological bounds
  rr_intervals <- pmax(400, pmin(2000, rr_intervals))
  
  # Compute actual HRV metrics for 5-minute windows
  window_size <- params$hrv$window_s * params$simulation$sampling_hz
  n_windows <- floor(n_samples / window_size)
  
  hrv_features <- tibble(
    window_idx = integer(),
    hrv_sdnn = numeric(),
    hrv_rmssd = numeric()
  )
  
  for (w in seq_len(n_windows)) {
    start_idx <- (w - 1) * window_size + 1
    end_idx <- min(n_samples, w * window_size)
    window_rr <- rr_intervals[start_idx:end_idx]
    
    hrv <- compute_hrv(window_rr, window_s = params$hrv$window_s)
    
    hrv_features <- bind_rows(hrv_features, tibble(
      window_idx = w,
      hrv_sdnn = hrv$SDNN,
      hrv_rmssd = hrv$RMSSD
    ))
  }
  
  return(list(
    rr_intervals = rr_intervals,
    hrv_features = hrv_features
  ))
}

#' Simulate Blink Events with Fatigue Modulation
simulate_blinks_enhanced <- function(duration_s, state, surgeon_params, params) {
  
  # Convert state to fatigue segments
  # Find continuous high-load or lapse segments
  state_numeric <- as.numeric(state)
  transitions <- c(0, which(diff(state_numeric) != 0), length(state))
  
  fatigue_segments <- list()
  for (i in seq_len(length(transitions) - 1)) {
    start_idx <- transitions[i] + 1
    end_idx <- transitions[i + 1]
    segment_state <- state[start_idx]
    
    if (segment_state %in% c("High Load", "Attentional Lapse")) {
      # Convert indices to seconds
      start_s <- (start_idx - 1) / params$simulation$sampling_hz
      end_s <- end_idx / params$simulation$sampling_hz
      
      # Rate multiplier: hyperfocus (low rate) for high load,
      # increased rate for lapse
      rate_mult <- ifelse(segment_state == "High Load", 0.6, 1.3)
      
      fatigue_segments[[length(fatigue_segments) + 1]] <- list(
        start_s = start_s,
        end_s = end_s,
        rate_multiplier = rate_mult
      )
    }
  }
  
  # Simulate blinks
  blinks <- simulate_blinks(
    duration_s = duration_s,
    baseline_rate_per_min = surgeon_params$blink_rate_baseline,
    fatigue_segments = if (length(fatigue_segments) > 0) fatigue_segments else NULL
  )
  
  return(blinks)
}

#' Main Simulation Function
simulate_surgeon_case <- function(surgeon_params, params) {
  
  cat(sprintf("Simulating surgeon: %s\n", surgeon_params$surgeon_id))
  
  # Time vector
  duration_s <- params$simulation$duration_s
  fs <- params$simulation$sampling_hz
  n_samples <- duration_s * fs
  time_s <- seq(0, duration_s - 1/fs, by = 1/fs)
  
  # Generate state sequence
  cognitive_state <- simulate_states(n_samples, params)
  
  # Simulate biosignals
  pupil_diameter <- simulate_pupil(n_samples, time_s, cognitive_state, 
                                   surgeon_params, params)
  
  grip_force <- simulate_grip(n_samples, time_s, cognitive_state, 
                              surgeon_params, params)
  
  tremor_rms <- simulate_tremor(n_samples, time_s, cognitive_state, 
                                surgeon_params, params)
  
  hrv_data <- simulate_hrv(n_samples, time_s, cognitive_state, 
                          surgeon_params, params)
  
  # Blinks (separate timeline, merged later)
  blinks <- simulate_blinks_enhanced(duration_s, cognitive_state, 
                                    surgeon_params, params)
  
  # Create main data frame
  df <- tibble(
    surgeon_id = surgeon_params$surgeon_id,
    timestamp = time_s,
    cognitive_state = cognitive_state,
    pupil_diameter_mm = pupil_diameter,
    grip_force_N = grip_force,
    tremor_rms_um = tremor_rms,
    rr_interval_ms = hrv_data$rr_intervals
  )
  
  # Add blink indicators (mark samples where blink occurred)
  df$blink <- 0
  if (nrow(blinks) > 0) {
    for (i in seq_len(nrow(blinks))) {
      blink_idx <- round(blinks$timestamp[i] * fs) + 1
      if (blink_idx <= nrow(df)) {
        df$blink[blink_idx] <- 1
      }
    }
  }
  
  # Store HRV features separately (one row per window)
  hrv_features <- hrv_data$hrv_features %>%
    mutate(surgeon_id = surgeon_params$surgeon_id)
  
  return(list(
    signals = df,
    hrv_features = hrv_features,
    blinks = blinks %>% mutate(surgeon_id = surgeon_params$surgeon_id)
  ))
}

# ==============================================================================
# MAIN EXECUTION
# ==============================================================================

cat("Generating surgeon parameters...\n")
surgeon_ids <- sprintf("S%03d", seq_len(params$simulation$num_surgeons))
all_surgeon_params <- lapply(surgeon_ids, generate_surgeon_params, params = params)

cat("Simulating cases...\n")
results <- lapply(all_surgeon_params, simulate_surgeon_case, params = params)

# Combine results
cat("Combining results...\n")
all_signals <- bind_rows(lapply(results, function(x) x$signals))
all_hrv_features <- bind_rows(lapply(results, function(x) x$hrv_features))
all_blinks <- bind_rows(lapply(results, function(x) x$blinks))

# Summary statistics
cat("\n=== Simulation Summary ===\n")
cat(sprintf("Total samples: %s\n", scales::comma(nrow(all_signals))))
cat(sprintf("Duration per surgeon: %.1f min\n", params$simulation$duration_s / 60))
cat(sprintf("Total duration: %.1f hours\n", 
            nrow(all_signals) / params$simulation$sampling_hz / 3600))

state_counts <- all_signals %>%
  count(cognitive_state) %>%
  mutate(pct = n / sum(n) * 100)

cat("\nCognitive State Distribution:\n")
print(state_counts)

cat("\nBiosignal Ranges:\n")
cat(sprintf("  Pupil: %.2f - %.2f mm (mean: %.2f)\n",
            min(all_signals$pupil_diameter_mm),
            max(all_signals$pupil_diameter_mm),
            mean(all_signals$pupil_diameter_mm)))
cat(sprintf("  Grip: %.2f - %.2f N (mean: %.2f)\n",
            min(all_signals$grip_force_N),
            max(all_signals$grip_force_N),
            mean(all_signals$grip_force_N)))
cat(sprintf("  Tremor: %.0f - %.0f μm (mean: %.0f)\n",
            min(all_signals$tremor_rms_um),
            max(all_signals$tremor_rms_um),
            mean(all_signals$tremor_rms_um)))
cat(sprintf("  RR intervals: %.0f - %.0f ms (mean: %.0f)\n",
            min(all_signals$rr_interval_ms),
            max(all_signals$rr_interval_ms),
            mean(all_signals$rr_interval_ms)))

cat(sprintf("\nTotal blinks: %d (%.1f per min avg)\n",
            nrow(all_blinks),
            nrow(all_blinks) / (nrow(all_signals) / params$simulation$sampling_hz / 60)))

# Save outputs
cat("\nSaving outputs...\n")

# Main signals (compressed CSV)
readr::write_csv(all_signals, "data/processed/sim_stream_enhanced.csv.gz")
cat("  ✓ data/processed/sim_stream_enhanced.csv.gz\n")

# HRV features
readr::write_csv(all_hrv_features, "data/processed/sim_hrv_features.csv")
cat("  ✓ data/processed/sim_hrv_features.csv\n")

# Blinks
readr::write_csv(all_blinks, "data/processed/sim_blinks.csv")
cat("  ✓ data/processed/sim_blinks.csv\n")

# Save as RDS for faster loading
saveRDS(list(
  signals = all_signals,
  hrv_features = all_hrv_features,
  blinks = all_blinks,
  params = params,
  surgeon_params = all_surgeon_params
), "data/processed/simulation_enhanced.rds")
cat("  ✓ data/processed/simulation_enhanced.rds\n")

cat("\n✅ Enhanced simulation complete!\n")

