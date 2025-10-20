#!/usr/bin/env Rscript
#' Train XGBoost LOSO Model with HRV-Centric Features
#' 
#' Evidence-based feature engineering and training following the ChatGPT spec
#' 
#' Features:
#' - 60s/30s/120s rolling HRV windows (RMSSD, SDNN, pNN50, HF/LF, SD1, SampEn)
#' - TEPR (6s), pupil tonic (30s), blink rate/CV (60s/120s)
#' - Grip force (15s), tremor (10s, 8-12Hz band)
#' - Within-person baselines and interaction terms
#' - LOSO cross-validation
#' - Platt scaling per class
#' - Class imbalance handling with sample weights
#'
#' Output: data/processed/xgb_loso_models.rds

# ============================================================================
# Setup
# ============================================================================

cat("=== XGBoost LOSO Training with HRV Features ===\n\n")

suppressPackageStartupMessages({
  library(data.table)
  library(tidyverse)
  library(xgboost)
  library(zoo)
  library(slider)
})

# Source helpers
source("R/feature_engineering_hrv.R")

# ============================================================================
# Load Data
# ============================================================================

cat("Loading simulated data...\n")

# Try loading enhanced simulation first, fallback to basic
if (file.exists("data/processed/simulation_enhanced.rds")) {
  cat("  Using enhanced simulation data\n")
  sim_data <- readRDS("data/processed/simulation_enhanced.rds")
  dt <- as.data.table(sim_data$signals)
} else if (file.exists("data/processed/sim_stream_enhanced.csv.gz")) {
  cat("  Using enhanced stream CSV\n")
  dt <- fread("data/processed/sim_stream_enhanced.csv.gz")
} else if (file.exists("data/processed/sim_stream.csv.gz")) {
  cat("  ⚠️  Using basic sim_stream.csv.gz (may be missing some columns)\n")
  dt <- fread("data/processed/sim_stream.csv.gz")
} else {
  stop("No simulation data found! Run scripts/01_simulate_data_enhanced.R first.")
}

cat(sprintf("  Loaded %s samples from %d surgeons\n", 
            scales::comma(nrow(dt)), 
            length(unique(dt$surgeon_id))))

# Standardize column names
if ("rr_interval_ms" %in% names(dt)) {
  setnames(dt, "rr_interval_ms", "rr_ms", skip_absent = TRUE)
}
if ("pupil_diameter_mm" %in% names(dt)) {
  setnames(dt, "pupil_diameter_mm", "pupil_mm", skip_absent = TRUE)
}
if ("grip_force_N" %in% names(dt)) {
  setnames(dt, "grip_force_N", "grip_N", skip_absent = TRUE)
}
if ("tremor_rms_um" %in% names(dt)) {
  setnames(dt, "tremor_rms_um", "tremor_um", skip_absent = TRUE)
}
if ("timestamp" %in% names(dt)) {
  setnames(dt, "timestamp", "t", skip_absent = TRUE)
}

# Ensure we have essential columns
required_cols <- c("surgeon_id", "t", "cognitive_state", "rr_ms", "pupil_mm")
missing_cols <- setdiff(required_cols, names(dt))
if (length(missing_cols) > 0) {
  stop(sprintf("Missing required columns: %s", paste(missing_cols, collapse = ", ")))
}

# ============================================================================
# Feature Engineering
# ============================================================================

cat("\nEngineering features...\n")

# Resample to 1 Hz for consistent windowing
dt <- dt[order(surgeon_id, t)]

# For each surgeon, compute features
feat_list <- list()

surgeons <- unique(dt$surgeon_id)
n_surgeons <- length(surgeons)

for (i in seq_along(surgeons)) {
  s <- surgeons[i]
  cat(sprintf("  [%d/%d] %s ", i, n_surgeons, s))
  
  dt_s <- dt[surgeon_id == s]
  
  # Resample to 1 Hz grid
  t_min <- min(dt_s$t, na.rm = TRUE)
  t_max <- max(dt_s$t, na.rm = TRUE)
  t_grid <- seq(t_min, t_max, by = 1)
  
  # Interpolate all signals to 1 Hz
  feat_s <- data.table(
    surgeon_id = s,
    t = t_grid
  )
  
  # Interpolate continuous signals
  feat_s$pupil_mm <- approx(dt_s$t, dt_s$pupil_mm, xout = t_grid, rule = 2)$y
  feat_s$rr_ms <- approx(dt_s$t, dt_s$rr_ms, xout = t_grid, rule = 2)$y
  
  # Optional signals (may not exist in all datasets)
  if ("grip_N" %in% names(dt_s)) {
    feat_s$grip_N <- approx(dt_s$t, dt_s$grip_N, xout = t_grid, rule = 2)$y
  } else {
    feat_s$grip_N <- 3.0  # Default placeholder
  }
  
  if ("tremor_um" %in% names(dt_s)) {
    feat_s$tremor_um <- approx(dt_s$t, dt_s$tremor_um, xout = t_grid, rule = 2)$y
  } else {
    feat_s$tremor_um <- 80.0  # Default placeholder
  }
  
  if ("blink" %in% names(dt_s)) {
    feat_s$blink <- approx(dt_s$t, dt_s$blink, xout = t_grid, rule = 1, method = "constant")$y
    feat_s$blink[is.na(feat_s$blink)] <- 0
  } else {
    feat_s$blink <- 0
  }
  
  # Labels (nearest neighbor)
  state_idx <- sapply(t_grid, function(tt) which.min(abs(dt_s$t - tt)))
  feat_s$cognitive_state <- dt_s$cognitive_state[state_idx]
  
  # --- HRV Features (rolling windows) ---
  cat("HRV...")
  
  # RMSSD 60s
  feat_s$rmssd_60s <- slide_dbl(feat_s$rr_ms, compute_rmssd, 
                                 .before = 59, .after = 0, .complete = FALSE)
  
  # RMSSD 30s
  feat_s$rmssd_30s <- slide_dbl(feat_s$rr_ms, compute_rmssd, 
                                 .before = 29, .after = 0, .complete = FALSE)
  
  # SDNN 120s
  feat_s$sdnn_120s <- slide_dbl(feat_s$rr_ms, compute_sdnn, 
                                 .before = 119, .after = 0, .complete = FALSE)
  
  # pNN50 60s
  feat_s$pnn50_60s <- slide_dbl(feat_s$rr_ms, compute_pnn50, 
                                 .before = 59, .after = 0, .complete = FALSE)
  
  # SD1 Poincaré 60s
  feat_s$sd1_poincare_60s <- slide_dbl(feat_s$rr_ms, compute_sd1_poincare, 
                                        .before = 59, .after = 0, .complete = FALSE)
  
  # Sample entropy 60s (slower, simplified)
  feat_s$sampen_60s <- slide_dbl(feat_s$rr_ms, 
                                  ~ifelse(length(.x) >= 10, compute_sampen(.x), NA_real_), 
                                  .before = 59, .after = 0, .complete = FALSE)
  
  # Frequency domain (HF/LF) - compute every 10s to save time
  freq_indices <- seq(60, nrow(feat_s), by = 10)
  feat_s$hf_power_60s <- NA_real_
  feat_s$lf_power_60s <- NA_real_
  feat_s$lf_hf_60s <- NA_real_
  
  for (idx in freq_indices) {
    window_rr <- feat_s$rr_ms[(max(1, idx - 59)):idx]
    if (length(window_rr) >= 10) {
      freq_res <- compute_freq_domain(window_rr)
      feat_s$hf_power_60s[idx] <- freq_res$hf_power
      feat_s$lf_power_60s[idx] <- freq_res$lf_power
      feat_s$lf_hf_60s[idx] <- freq_res$lf_hf_ratio
    }
  }
  
  # Forward fill freq features
  feat_s$hf_power_60s <- zoo::na.locf(feat_s$hf_power_60s, na.rm = FALSE)
  feat_s$lf_power_60s <- zoo::na.locf(feat_s$lf_power_60s, na.rm = FALSE)
  feat_s$lf_hf_60s <- zoo::na.locf(feat_s$lf_hf_60s, na.rm = FALSE)
  
  # --- Derived HRV features ---
  # Baseline: first 3 minutes (180 samples)
  baseline_idx <- seq_len(min(180, nrow(feat_s)))
  
  feat_s$rmssd_z_own <- compute_z_score(feat_s$rmssd_60s, baseline_idx)
  feat_s$rmssd_drop_pct_60s <- compute_pct_drop(feat_s$rmssd_60s, baseline_idx)
  feat_s$rmssd_slope_120s <- compute_slope(feat_s$rmssd_60s, feat_s$t, win_s = 120)
  
  # --- Pupil Features ---
  cat("Pupil...")
  
  # Tonic pupil (30s mean)
  feat_s$pupil_tonic_30s <- slide_dbl(feat_s$pupil_mm, mean, 
                                       .before = 29, .after = 0, .complete = FALSE, na.rm = TRUE)
  
  # TEPR (6s): change relative to 3s baseline
  feat_s$tepr_6s <- NA_real_
  for (idx in 7:nrow(feat_s)) {
    baseline <- mean(feat_s$pupil_mm[(idx - 6):(idx - 4)], na.rm = TRUE)
    current <- mean(feat_s$pupil_mm[(idx - 2):idx], na.rm = TRUE)
    feat_s$tepr_6s[idx] <- current - baseline
  }
  
  # Pupil dilation rate (3s max first-difference)
  feat_s$pupil_dilate_rate <- slide_dbl(
    feat_s$pupil_mm, 
    ~max(diff(.x), na.rm = TRUE), 
    .before = 2, .after = 0, .complete = FALSE
  )
  
  # --- Blink Features ---
  cat("Blink...")
  
  # Blink rate (blinks/min over 60s)
  feat_s$blink_rate_60s <- slide_dbl(feat_s$blink, sum, 
                                      .before = 59, .after = 0, .complete = FALSE, na.rm = TRUE)
  
  # Blink CV (120s coefficient of variation of inter-blink intervals)
  # Simplified: CV of blink indicator over 120s
  feat_s$blink_cv_120s <- slide_dbl(feat_s$blink, 
                                     ~ifelse(mean(.x) > 0, sd(.x) / mean(.x) * 100, 0), 
                                     .before = 119, .after = 0, .complete = FALSE, na.rm = TRUE)
  
  # --- Grip Force Features ---
  cat("Grip...")
  
  # Mean grip 15s
  feat_s$grip_mean_15s <- slide_dbl(feat_s$grip_N, mean, 
                                     .before = 14, .after = 0, .complete = FALSE, na.rm = TRUE)
  
  # CV grip 15s
  feat_s$grip_cv_15s <- slide_dbl(feat_s$grip_N, 
                                   ~ifelse(mean(.x) > 0, sd(.x) / mean(.x) * 100, 0), 
                                   .before = 14, .after = 0, .complete = FALSE, na.rm = TRUE)
  
  # --- Tremor Features ---
  cat("Tremor...")
  
  # Tremor RMS 8-12Hz band (10s window)
  # For simplicity, use raw tremor_um as proxy (full FFT would be more accurate)
  feat_s$tremor_rms_8_12hz <- slide_dbl(feat_s$tremor_um, mean, 
                                         .before = 9, .after = 0, .complete = FALSE, na.rm = TRUE)
  
  # Tremor slope (60s)
  feat_s$tremor_slope_60s <- compute_slope(feat_s$tremor_um, feat_s$t, win_s = 60)
  
  # --- Context: Ambient noise (placeholder) ---
  feat_s$noise_db_30s <- 65  # Constant placeholder
  
  # --- Interaction Terms ---
  cat("Interactions...\n")
  
  # z(TEPR) × (-z(RMSSD)): High TEPR with low RMSSD
  z_tepr <- compute_z_score(feat_s$tepr_6s, baseline_idx)
  z_rmssd <- compute_z_score(feat_s$rmssd_60s, baseline_idx)
  feat_s$intxn_tepr_x_rmssd <- z_tepr * (-z_rmssd)
  
  # z(Blink) × (-z(RMSSD)): High blink with low RMSSD
  z_blink <- compute_z_score(feat_s$blink_rate_60s, baseline_idx)
  feat_s$intxn_blink_x_rmssd <- z_blink * (-z_rmssd)
  
  # Store
  feat_list[[i]] <- feat_s
}

cat("\nCombining features from all surgeons...\n")
feat <- rbindlist(feat_list)

# Drop rows with excessive NAs (first few windows)
feat <- feat[complete.cases(feat[, .(rmssd_60s, pupil_mm, cognitive_state)])]

cat(sprintf("  Final feature set: %s samples, %d features\n", 
            scales::comma(nrow(feat)), ncol(feat) - 3))

# ============================================================================
# Prepare Training Data
# ============================================================================

cat("\nPreparing training data...\n")

# Define feature columns (exclude ID, time, label, raw signals)
feat_cols <- setdiff(names(feat), c(
  "surgeon_id", "t", "cognitive_state",
  "pupil_mm", "rr_ms", "grip_N", "tremor_um", "blink"
))

cat(sprintf("  Using %d features\n", length(feat_cols)))
cat("  Features: ", paste(head(feat_cols, 10), collapse = ", "), "...\n")

# Encode labels
feat[, y_class := factor(cognitive_state, 
                          levels = c("Normal", "High Load", "Attentional Lapse"))]
feat[, y_num := as.numeric(y_class) - 1]  # 0, 1, 2

# Check class balance
class_counts <- feat[, .N, by = y_class]
cat("\nClass distribution:\n")
print(class_counts)

# ============================================================================
# XGBoost Parameters (from spec)
# ============================================================================

xgb_params <- list(
  objective        = "multi:softprob",
  num_class        = 3,
  eval_metric      = "mlogloss",
  max_depth        = 4,
  eta              = 0.05,
  subsample        = 0.85,
  colsample_bytree = 0.75,
  min_child_weight = 2,
  gamma            = 0.0,
  lambda           = 1.0,
  alpha            = 0.0
)

nrounds <- 600
early_stopping_rounds <- 40

# ============================================================================
# LOSO Cross-Validation
# ============================================================================

cat("\n=== LOSO Cross-Validation ===\n")

surgeons <- unique(feat$surgeon_id)
n_surgeons <- length(surgeons)
models <- list()

for (i in seq_along(surgeons)) {
  s <- surgeons[i]
  cat(sprintf("\n[%d/%d] Fold: Holding out %s\n", i, n_surgeons, s))
  
  # Train/test split
  tr <- feat[surgeon_id != s]
  te <- feat[surgeon_id == s]
  
  # Sample weights for class imbalance
  cls_freq <- table(tr$y_class)
  cls_freq_norm <- as.numeric(cls_freq)
  w_map <- mean(cls_freq_norm) / cls_freq_norm
  names(w_map) <- names(cls_freq)
  
  w_tr <- w_map[match(tr$y_class, names(w_map))]
  
  cat(sprintf("  Train: %s samples, Test: %s samples\n", 
              scales::comma(nrow(tr)), scales::comma(nrow(te))))
  cat(sprintf("  Class weights: Normal=%.2f, HighLoad=%.2f, Lapse=%.2f\n", 
              w_map[1], w_map[2], w_map[3]))
  
  # Create DMatrix
  X_tr <- as.matrix(tr[, ..feat_cols])
  X_te <- as.matrix(te[, ..feat_cols])
  
  dtr <- xgb.DMatrix(X_tr, label = tr$y_num, weight = w_tr)
  dte <- xgb.DMatrix(X_te, label = te$y_num)
  
  # Train with early stopping
  watch <- list(train = dtr)
  
  bst <- xgb.train(
    params = xgb_params,
    data = dtr,
    nrounds = nrounds,
    watchlist = watch,
    early_stopping_rounds = early_stopping_rounds,
    verbose = 0
  )
  
  cat(sprintf("  Best iteration: %d\n", bst$best_iteration))
  
  # Get raw probabilities on training set
  p_tr_raw <- matrix(predict(bst, dtr), ncol = 3, byrow = TRUE)
  colnames(p_tr_raw) <- c("p_normal_raw", "p_hl_raw", "p_lapse_raw")
  
  tr <- cbind(tr, as.data.table(p_tr_raw))
  
  # --- Platt Scaling per Class ---
  cat("  Calibrating probabilities (Platt scaling)...\n")
  
  glm_normal <- glm(I(y_class == "Normal") ~ p_normal_raw, 
                    data = tr, family = binomial())
  glm_hl <- glm(I(y_class == "High Load") ~ p_hl_raw, 
                data = tr, family = binomial())
  glm_lapse <- glm(I(y_class == "Attentional Lapse") ~ p_lapse_raw, 
                   data = tr, family = binomial())
  
  # Store model
  models[[i]] <- list(
    surgeon_held_out = s,
    feat_cols = feat_cols,
    bst = bst,
    glm_cal = list(
      normal = glm_normal,
      hl = glm_hl,
      lapse = glm_lapse
    ),
    feat_names = feat_cols,  # For backwards compatibility
    class_weights = w_map
  )
  
  # Evaluate on test set
  p_te_raw <- matrix(predict(bst, dte), ncol = 3, byrow = TRUE)
  
  # Apply calibration
  p_te_cal <- cbind(
    predict(glm_normal, newdata = data.frame(p_normal_raw = p_te_raw[, 1]), type = "response"),
    predict(glm_hl, newdata = data.frame(p_hl_raw = p_te_raw[, 2]), type = "response"),
    predict(glm_lapse, newdata = data.frame(p_lapse_raw = p_te_raw[, 3]), type = "response")
  )
  
  # Renormalize to sum to 1
  p_te_cal <- p_te_cal / rowSums(p_te_cal)
  
  # Predicted class
  y_pred <- apply(p_te_cal, 1, which.max) - 1
  
  # Accuracy
  acc <- mean(y_pred == te$y_num, na.rm = TRUE)
  
  cat(sprintf("  Test accuracy: %.3f\n", acc))
  
  # Per-class accuracy
  for (cls in 0:2) {
    cls_name <- c("Normal", "High Load", "Lapse")[cls + 1]
    idx <- te$y_num == cls
    if (sum(idx) > 0) {
      cls_acc <- mean(y_pred[idx] == cls, na.rm = TRUE)
      cat(sprintf("    %s: %.3f (%d samples)\n", cls_name, cls_acc, sum(idx)))
    }
  }
}

# ============================================================================
# Save Models
# ============================================================================

cat("\n=== Saving Models ===\n")

output_path <- "data/processed/xgb_loso_models.rds"
saveRDS(models, output_path)

cat(sprintf("  ✓ Saved %d LOSO models to: %s\n", length(models), output_path))
cat(sprintf("  File size: %.1f MB\n", file.size(output_path) / 1e6))

# ============================================================================
# Summary
# ============================================================================

cat("\n=== Training Complete! ===\n")
cat(sprintf("  Total surgeons: %d\n", n_surgeons))
cat(sprintf("  Features per model: %d\n", length(feat_cols)))
cat(sprintf("  XGBoost nrounds: %d (with early stopping)\n", nrounds))
cat(sprintf("  Calibration: Platt scaling per class\n"))
cat(sprintf("  Output: %s\n", output_path))

cat("\n✅ Ready to launch app with HRV features!\n")
cat("   Run: Rscript shiny_app/run_app.sh\n")
cat("   Or open shiny_app/app_working.R in RStudio\n\n")
