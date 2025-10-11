#' Grip Force Analysis Utilities
#'
#' Functions for computing grip force statistics, coefficient of variation,
#' spike detection, and fatigue-related trends.
#'
#' @references
#' Johansson, R.S., & Westling, G. (1984). Roles of glabrous skin receptors.
#' Flanagan, J.R., & Wing, A.M. (1993). Modulation of grip force.

suppressPackageStartupMessages({
  library(dplyr)
})

#' Compute Grip Force Statistics for Window
#'
#' @param force_N Numeric vector of grip force in Newtons
#' @param window_s Window duration in seconds (for spike rate)
#' @param z_threshold Z-score threshold for spike detection (default 3)
#' @return List with mean, sd, cv_pct, spike_rate, trend
#' @export
#'
#' @examples
#' force <- rnorm(300, mean = 3.0, sd = 0.5)
#' stats <- grip_stats(force, window_s = 60)
#' stats$cv_pct  # Coefficient of variation

grip_stats <- function(force_N, window_s = 60, z_threshold = 3) {
  
  # Handle missing/invalid data
  if (all(is.na(force_N)) || length(force_N) < 3) {
    return(list(
      mean_N = NA_real_,
      sd_N = NA_real_,
      cv_pct = NA_real_,
      spike_rate = NA_real_,
      trend_slope = NA_real_
    ))
  }
  
  # Remove NAs
  force_clean <- force_N[!is.na(force_N)]
  
  # Basic statistics
  mean_force <- mean(force_clean)
  sd_force <- sd(force_clean)
  cv_pct <- if (mean_force > 0) (sd_force / mean_force) * 100 else NA_real_
  
  # Spike detection (z-score method)
  z_scores <- (force_clean - mean_force) / sd_force
  n_spikes <- sum(abs(z_scores) > z_threshold, na.rm = TRUE)
  spike_rate <- n_spikes / window_s  # spikes per second
  
  # Trend (linear regression slope)
  if (length(force_clean) >= 3) {
    time_idx <- seq_along(force_clean)
    trend_fit <- tryCatch({
      coef(lm(force_clean ~ time_idx))[2]
    }, error = function(e) NA_real_)
  } else {
    trend_fit <- NA_real_
  }
  
  return(list(
    mean_N = mean_force,
    sd_N = sd_force,
    cv_pct = cv_pct,
    spike_rate = spike_rate,
    trend_slope = trend_fit
  ))
}

#' Detect Stress-Induced Grip Force Spikes
#'
#' Identifies sustained increases in grip force that may indicate stress response.
#'
#' @param force_N Grip force vector
#' @param fs Sampling frequency
#' @param baseline_mean Baseline mean force
#' @param spike_threshold_N Minimum increase to classify as spike
#' @param min_duration_s Minimum spike duration
#' @return Tibble with spike_start, spike_end, spike_magnitude
#' @export

detect_grip_spikes <- function(force_N, fs, baseline_mean, 
                               spike_threshold_N = 1.5, min_duration_s = 3) {
  
  if (all(is.na(force_N)) || length(force_N) < fs * min_duration_s) {
    return(tibble::tibble(
      spike_start = numeric(),
      spike_end = numeric(),
      spike_magnitude = numeric()
    ))
  }
  
  # Smooth force signal
  window_size <- max(3, round(fs * 0.5))  # 0.5s smoothing
  force_smooth <- zoo::rollmean(force_N, k = window_size, fill = NA, align = "center")
  
  # Detect above-threshold regions
  above_threshold <- force_smooth > (baseline_mean + spike_threshold_N)
  above_threshold[is.na(above_threshold)] <- FALSE
  
  # Find contiguous regions
  transitions <- diff(c(FALSE, above_threshold, FALSE))
  starts <- which(transitions == 1)
  ends <- which(transitions == -1) - 1
  
  if (length(starts) == 0 || length(ends) == 0) {
    return(tibble::tibble(
      spike_start = numeric(),
      spike_end = numeric(),
      spike_magnitude = numeric()
    ))
  }
  
  # Filter by minimum duration
  durations_s <- (ends - starts) / fs
  valid <- durations_s >= min_duration_s
  
  if (sum(valid) == 0) {
    return(tibble::tibble(
      spike_start = numeric(),
      spike_end = numeric(),
      spike_magnitude = numeric()
    ))
  }
  
  starts <- starts[valid]
  ends <- ends[valid]
  
  # Compute spike magnitudes
  magnitudes <- sapply(seq_along(starts), function(i) {
    max(force_smooth[starts[i]:ends[i]], na.rm = TRUE) - baseline_mean
  })
  
  tibble::tibble(
    spike_start = starts / fs,
    spike_end = ends / fs,
    spike_magnitude = magnitudes
  )
}

#' Model Grip CV Increase with Fatigue
#'
#' Predicts coefficient of variation based on time-on-task.
#'
#' @param time_on_task_min Minutes since procedure start
#' @param cv_fresh_pct CV when fresh
#' @param cv_fatigued_pct CV when fatigued
#' @param fatigue_time_constant_min Time constant for exponential approach (default 30)
#' @return Expected CV percentage
#' @export
#'
#' @examples
#' # After 45 minutes, with CV rising from 8% to 12%
#' expected_cv <- grip_cv_fatigue_model(45, cv_fresh_pct = 8, 
#'                                      cv_fatigued_pct = 12)

grip_cv_fatigue_model <- function(time_on_task_min, cv_fresh_pct, 
                                  cv_fatigued_pct, 
                                  fatigue_time_constant_min = 30) {
  
  # Exponential approach to fatigued CV
  cv_delta <- cv_fatigued_pct - cv_fresh_pct
  cv_increase <- cv_delta * (1 - exp(-time_on_task_min / fatigue_time_constant_min))
  
  expected_cv <- cv_fresh_pct + cv_increase
  return(expected_cv)
}

#' Derive Grip Force Surrogate from Robot Joint Torques
#'
#' Provides a proxy for grip force when no direct sensor is available.
#' Uses correlation between joint torques/velocity and grip requirements.
#'
#' @param joint_data Tibble with timestamp and joint torque/velocity columns
#' @param method Method for surrogate: "torque_rms", "velocity_jerk"
#' @param scaling_factor Empirical scaling to approximate Newtons
#' @return Numeric vector of surrogate grip force
#' @export

grip_surrogate_from_robot <- function(joint_data, method = "torque_rms", 
                                     scaling_factor = 1.0) {
  
  if (nrow(joint_data) == 0) {
    return(numeric(0))
  }
  
  if (method == "torque_rms") {
    # Use RMS of joint torques as proxy
    torque_cols <- grep("torque", names(joint_data), ignore.case = TRUE, value = TRUE)
    
    if (length(torque_cols) == 0) {
      warning("No torque columns found, returning NA")
      return(rep(NA_real_, nrow(joint_data)))
    }
    
    # Compute RMS across joints
    torque_matrix <- as.matrix(joint_data[, torque_cols])
    rms_per_row <- sqrt(rowMeans(torque_matrix^2, na.rm = TRUE))
    surrogate <- rms_per_row * scaling_factor
    
  } else if (method == "velocity_jerk") {
    # Use velocity jerk magnitude as proxy
    vel_cols <- grep("vel|velocity", names(joint_data), ignore.case = TRUE, value = TRUE)
    
    if (length(vel_cols) == 0) {
      warning("No velocity columns found, returning NA")
      return(rep(NA_real_, nrow(joint_data)))
    }
    
    # Compute jerk (3rd derivative of position, 1st derivative of velocity)
    vel_matrix <- as.matrix(joint_data[, vel_cols])
    jerk_matrix <- apply(vel_matrix, 2, function(v) c(0, diff(v)))
    jerk_magnitude <- sqrt(rowMeans(jerk_matrix^2, na.rm = TRUE))
    surrogate <- jerk_magnitude * scaling_factor
    
  } else {
    stop(sprintf("Unknown method: %s", method))
  }
  
  return(surrogate)
}

#' Compute Rolling Grip Statistics
#'
#' @param force_N Grip force vector
#' @param fs Sampling frequency
#' @param window_s Window size in seconds
#' @param step_s Step size in seconds
#' @return Tibble with time, mean_N, sd_N, cv_pct, spike_rate
#' @export

grip_stats_rolling <- function(force_N, fs, window_s = 60, step_s = 10) {
  
  n <- length(force_N)
  window_samples <- window_s * fs
  step_samples <- step_s * fs
  
  if (n < window_samples) {
    warning("Signal shorter than window size")
    return(tibble::tibble(
      time_s = numeric(),
      mean_N = numeric(),
      sd_N = numeric(),
      cv_pct = numeric(),
      spike_rate = numeric()
    ))
  }
  
  starts <- seq(1, n - window_samples + 1, by = step_samples)
  
  results <- lapply(starts, function(start) {
    end <- start + window_samples - 1
    window_force <- force_N[start:end]
    stats <- grip_stats(window_force, window_s = window_s)
    
    tibble::tibble(
      time_s = (start + end) / (2 * fs),
      mean_N = stats$mean_N,
      sd_N = stats$sd_N,
      cv_pct = stats$cv_pct,
      spike_rate = stats$spike_rate,
      trend_slope = stats$trend_slope
    )
  })
  
  dplyr::bind_rows(results)
}

