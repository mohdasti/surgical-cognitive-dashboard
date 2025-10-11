#' Load and Validate Biosignal Parameters
#'
#' Loads parameters from YAML config and validates ranges/types.
#' This provides a single source of truth for all biosignal baselines,
#' thresholds, and system toggles.
#'
#' @param path Path to parameters.yml file
#' @return Named list with validated parameters
#' @export
#'
#' @examples
#' params <- load_params()
#' params$pupil$baseline_mm_mean  # 3.5
#' params$thresholds$lapse_prob   # 0.30

load_params <- function(path = "config/parameters.yml") {
  
  # Check file exists
  if (!file.exists(path)) {
    stop(sprintf("Parameters file not found: %s", path))
  }
  
  # Load YAML
  params <- tryCatch({
    yaml::read_yaml(path)
  }, error = function(e) {
    stop(sprintf("Failed to parse YAML: %s\nError: %s", path, e$message))
  })
  
  # Validate structure
  required_sections <- c("pupil", "grip", "tremor", "hrv", "windows", 
                         "thresholds", "toggles")
  missing <- setdiff(required_sections, names(params))
  if (length(missing) > 0) {
    stop(sprintf("Missing required sections: %s", paste(missing, collapse = ", ")))
  }
  
  # Validate pupil parameters
  validate_range(params$pupil$baseline_mm_mean, 2, 6, "pupil.baseline_mm_mean")
  validate_range(params$pupil$baseline_mm_sd, 0.05, 1, "pupil.baseline_mm_sd")
  validate_range(params$pupil$tepr_delta_mm_low, 0.1, 1, "pupil.tepr_delta_mm_low")
  validate_range(params$pupil$tepr_delta_mm_high, 0.2, 2, "pupil.tepr_delta_mm_high")
  validate_range(params$pupil$fatigue_baseline_drop_mm_per_hr, 0, 2, 
                 "pupil.fatigue_baseline_drop_mm_per_hr")
  
  if (params$pupil$tepr_delta_mm_low > params$pupil$tepr_delta_mm_high) {
    stop("pupil.tepr_delta_mm_low must be <= tepr_delta_mm_high")
  }
  
  # Validate grip parameters
  validate_range(params$grip$baseline_N_mean, 0.5, 10, "grip.baseline_N_mean")
  validate_range(params$grip$baseline_N_sd, 0.1, 5, "grip.baseline_N_sd")
  validate_range(params$grip$cv_fresh_pct, 1, 20, "grip.cv_fresh_pct")
  validate_range(params$grip$cv_fatigued_pct, 1, 30, "grip.cv_fatigued_pct")
  
  if (params$grip$cv_fresh_pct > params$grip$cv_fatigued_pct) {
    stop("grip.cv_fresh_pct must be <= cv_fatigued_pct")
  }
  
  # Validate tremor parameters
  validate_range(params$tremor$rms_um_mean, 20, 300, "tremor.rms_um_mean")
  validate_range(params$tremor$rms_um_sd, 5, 100, "tremor.rms_um_sd")
  validate_range(params$tremor$growth_pct_first_30min, 0, 50, 
                 "tremor.growth_pct_first_30min")
  validate_range(params$tremor$growth_pct_per_hr_after, 0, 100, 
                 "tremor.growth_pct_per_hr_after")
  
  if (length(params$tremor$band_hz) != 2 || params$tremor$band_hz[1] >= params$tremor$band_hz[2]) {
    stop("tremor.band_hz must be [low, high] with low < high")
  }
  
  # Validate HRV parameters
  validate_range(params$hrv$sdnn_ms_baseline, 20, 150, "hrv.sdnn_ms_baseline")
  validate_range(params$hrv$rmssd_ms_baseline, 10, 100, "hrv.rmssd_ms_baseline")
  validate_range(params$hrv$low_hrv_drop_pct_alert, 10, 70, 
                 "hrv.low_hrv_drop_pct_alert")
  validate_range(params$hrv$window_s, 60, 600, "hrv.window_s")
  
  # Validate windows
  validate_range(params$windows$short_s, 10, 300, "windows.short_s")
  validate_range(params$windows$medium_s, 60, 900, "windows.medium_s")
  validate_range(params$windows$long_s, 300, 1800, "windows.long_s")
  
  if (params$windows$short_s >= params$windows$medium_s || 
      params$windows$medium_s >= params$windows$long_s) {
    stop("Window durations must increase: short < medium < long")
  }
  
  # Validate thresholds
  validate_range(params$thresholds$high_load_prob, 0.5, 0.95, 
                 "thresholds.high_load_prob")
  validate_range(params$thresholds$lapse_prob, 0.05, 0.6, 
                 "thresholds.lapse_prob")
  validate_range(params$thresholds$tremor_fatigue_alert_pct_above_personal, 
                 5, 100, "thresholds.tremor_fatigue_alert_pct_above_personal")
  
  # Validate toggles are logical
  toggle_keys <- c("simulate", "enable_eda", "enable_blinks", "enable_hrv",
                   "enable_tremor", "enable_grip", "enable_pupil", 
                   "enable_calibration", "enable_audio_alerts", "enable_logging")
  for (key in toggle_keys) {
    if (!is.null(params$toggles[[key]]) && !is.logical(params$toggles[[key]])) {
      stop(sprintf("toggles.%s must be TRUE or FALSE", key))
    }
  }
  
  # Add metadata
  params$meta <- list(
    loaded_at = Sys.time(),
    path = path,
    version = "1.0.0"
  )
  
  # Set class for S3 methods
  class(params) <- c("surgical_params", "list")
  
  return(params)
}

#' Validate numeric parameter is in valid range
#' @keywords internal
validate_range <- function(value, min_val, max_val, param_name) {
  if (is.null(value) || !is.numeric(value) || length(value) != 1) {
    stop(sprintf("%s must be a single numeric value", param_name))
  }
  if (value < min_val || value > max_val) {
    stop(sprintf("%s = %s is out of range [%s, %s]", 
                 param_name, value, min_val, max_val))
  }
}

#' Print method for surgical_params
#' @export
print.surgical_params <- function(x, ...) {
  cat("Surgical Cognitive Dashboard Parameters\n")
  cat("========================================\n")
  cat(sprintf("Loaded: %s\n", x$meta$loaded_at))
  cat(sprintf("Version: %s\n", x$meta$version))
  cat(sprintf("Path: %s\n\n", x$meta$path))
  
  cat("Key Settings:\n")
  cat(sprintf("  Simulation Mode: %s\n", x$toggles$simulate))
  cat(sprintf("  Lapse Threshold: %.2f\n", x$thresholds$lapse_prob))
  cat(sprintf("  High Load Threshold: %.2f\n", x$thresholds$high_load_prob))
  cat(sprintf("  Pupil Baseline: %.2f ± %.2f mm\n", 
              x$pupil$baseline_mm_mean, x$pupil$baseline_mm_sd))
  cat(sprintf("  Grip Baseline: %.2f ± %.2f N\n", 
              x$grip$baseline_N_mean, x$grip$baseline_N_sd))
  cat(sprintf("  Tremor Baseline: %.0f ± %.0f μm\n", 
              x$tremor$rms_um_mean, x$tremor$rms_um_sd))
  cat(sprintf("  HRV RMSSD Baseline: %.0f ms\n", x$hrv$rmssd_ms_baseline))
  
  cat("\nEnabled Features:\n")
  cat(sprintf("  Pupil: %s | Grip: %s | Tremor: %s | HRV: %s | Blinks: %s\n",
              x$toggles$enable_pupil, x$toggles$enable_grip, 
              x$toggles$enable_tremor, x$toggles$enable_hrv,
              x$toggles$enable_blinks))
  
  invisible(x)
}

#' Get parameter value with dot notation
#' @param params Surgical parameters object
#' @param path Dot-separated path (e.g., "pupil.baseline_mm_mean")
#' @export
get_param <- function(params, path) {
  parts <- strsplit(path, "\\.")[[1]]
  value <- params
  for (part in parts) {
    value <- value[[part]]
    if (is.null(value)) {
      stop(sprintf("Parameter not found: %s", path))
    }
  }
  return(value)
}

#' Update parameter value (for dynamic threshold tuning)
#' @param params Surgical parameters object
#' @param path Dot-separated path
#' @param value New value
#' @export
set_param <- function(params, path, value) {
  parts <- strsplit(path, "\\.")[[1]]
  
  # Navigate to parent
  obj <- params
  for (i in seq_len(length(parts) - 1)) {
    obj <- obj[[parts[i]]]
    if (is.null(obj)) {
      stop(sprintf("Path not found: %s", paste(parts[1:i], collapse = ".")))
    }
  }
  
  # Set value
  last_key <- parts[length(parts)]
  obj[[last_key]] <- value
  
  return(params)
}

