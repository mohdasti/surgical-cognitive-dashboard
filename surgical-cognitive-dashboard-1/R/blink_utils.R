#' Blink Metrics from Eye-Tracking
#'
#' Functions for computing blink rate, duration, PERCLOS (percentage of eyelid closure),
#' and detecting anomalous blink patterns associated with fatigue or hyperfocus.
#'
#' @references
#' Stern, J.A., Boyer, D., & Schroeder, D. (1994). Blink rate: a possible measure of fatigue.
#' Wierwille, W.W., & Ellsworth, L.A. (1994). Evaluation of driver drowsiness by trained raters.

suppressPackageStartupMessages({
  library(dplyr)
  library(tibble)
})

#' Compute Blink Metrics for Window
#'
#' @param blink_timestamps Numeric vector of blink onset times (in seconds)
#' @param blink_durations Numeric vector of blink durations (in milliseconds)
#' @param window_s Window duration in seconds
#' @param perclos Optional PERCLOS value (0-100), if available
#' @return List with blink_rate_per_min, mean_duration_ms, perclos_pct
#' @export
#'
#' @examples
#' # 20 blinks in 60 seconds
#' timestamps <- sort(runif(20, 0, 60))
#' durations <- rnorm(20, mean = 150, sd = 30)
#' metrics <- compute_blink_metrics(timestamps, durations, window_s = 60)
#' metrics$blink_rate_per_min  # ~20 blinks/min

compute_blink_metrics <- function(blink_timestamps, blink_durations, 
                                  window_s, perclos = NULL) {
  
  # Validate inputs
  if (length(blink_timestamps) == 0) {
    return(list(
      blink_rate_per_min = 0,
      mean_blink_duration_ms = NA_real_,
      perclos_pct = if (is.null(perclos)) NA_real_ else perclos,
      n_blinks = 0
    ))
  }
  
  # Compute blink rate
  n_blinks <- length(blink_timestamps)
  blink_rate_per_min <- (n_blinks / window_s) * 60
  
  # Mean blink duration
  mean_duration_ms <- if (length(blink_durations) > 0) {
    mean(blink_durations, na.rm = TRUE)
  } else {
    NA_real_
  }
  
  # PERCLOS (if not provided, estimate from durations)
  if (is.null(perclos) && length(blink_durations) > 0) {
    total_closed_ms <- sum(blink_durations, na.rm = TRUE)
    perclos_pct <- (total_closed_ms / (window_s * 1000)) * 100
  } else if (!is.null(perclos)) {
    perclos_pct <- perclos
  } else {
    perclos_pct <- NA_real_
  }
  
  return(list(
    blink_rate_per_min = blink_rate_per_min,
    mean_blink_duration_ms = mean_duration_ms,
    perclos_pct = perclos_pct,
    n_blinks = n_blinks
  ))
}

#' Detect Anomalous Blink Patterns
#'
#' Identifies blink patterns associated with fatigue (high PERCLOS, low rate)
#' or hyperfocus (very low rate).
#'
#' @param blink_rate_per_min Current blink rate
#' @param perclos_pct Current PERCLOS percentage
#' @param personal_p05 Personal 5th percentile for blink rate (hyperfocus threshold)
#' @param personal_p95 Personal 95th percentile for blink rate (fatigue threshold)
#' @param perclos_threshold PERCLOS threshold for drowsiness (default 10%)
#' @return List with anomaly flag and reason
#' @export
#'
#' @examples
#' result <- blink_anomaly(blink_rate_per_min = 5, perclos_pct = 12, 
#'                         personal_p05 = 10, personal_p95 = 30, 
#'                         perclos_threshold = 10)
#' result$anomaly  # TRUE
#' result$reason   # "High PERCLOS (drowsiness)"

blink_anomaly <- function(blink_rate_per_min, perclos_pct, 
                         personal_p05 = NULL, personal_p95 = NULL, 
                         perclos_threshold = 10) {
  
  anomaly <- FALSE
  reasons <- character()
  
  # High PERCLOS check
  if (!is.na(perclos_pct) && perclos_pct > perclos_threshold) {
    anomaly <- TRUE
    reasons <- c(reasons, sprintf("High PERCLOS (%.1f%% > %.1f%%)", 
                                  perclos_pct, perclos_threshold))
  }
  
  # High blink rate check (fatigue)
  if (!is.null(personal_p95) && !is.na(blink_rate_per_min) && 
      blink_rate_per_min > personal_p95) {
    anomaly <- TRUE
    reasons <- c(reasons, sprintf("High blink rate (%.1f > p95 %.1f)", 
                                  blink_rate_per_min, personal_p95))
  }
  
  # Low blink rate check (hyperfocus/reduced awareness)
  if (!is.null(personal_p05) && !is.na(blink_rate_per_min) && 
      blink_rate_per_min < personal_p05) {
    anomaly <- TRUE
    reasons <- c(reasons, sprintf("Low blink rate (%.1f < p05 %.1f)", 
                                  blink_rate_per_min, personal_p05))
  }
  
  return(list(
    anomaly = anomaly,
    reason = if (length(reasons) > 0) paste(reasons, collapse = "; ") else "Normal"
  ))
}

#' Simulate Blink Data for Testing/Demo
#'
#' Generates synthetic blink timestamps and durations with fatigue effects.
#'
#' @param duration_s Total duration in seconds
#' @param baseline_rate_per_min Baseline blink rate (default 15)
#' @param fatigue_segments List of lists with start_s, end_s, rate_multiplier
#' @return Tibble with timestamp, duration_ms
#' @export
#'
#' @examples
#' # 10 minutes with fatigue episode from 300-400s
#' blinks <- simulate_blinks(
#'   duration_s = 600, 
#'   baseline_rate_per_min = 15,
#'   fatigue_segments = list(list(start_s = 300, end_s = 400, rate_multiplier = 0.5))
#' )

simulate_blinks <- function(duration_s, baseline_rate_per_min = 15, 
                           fatigue_segments = NULL) {
  
  # Generate blink times using Poisson process
  baseline_lambda <- baseline_rate_per_min / 60  # rate per second
  
  # Generate timestamps
  timestamps <- numeric()
  t <- 0
  
  while (t < duration_s) {
    # Check if we're in a fatigue segment
    rate_mult <- 1.0
    if (!is.null(fatigue_segments)) {
      for (seg in fatigue_segments) {
        if (t >= seg$start_s && t < seg$end_s) {
          rate_mult <- seg$rate_multiplier
          break
        }
      }
    }
    
    current_lambda <- baseline_lambda * rate_mult
    inter_blink_interval <- rexp(1, rate = current_lambda)
    t <- t + inter_blink_interval
    
    if (t < duration_s) {
      timestamps <- c(timestamps, t)
    }
  }
  
  # Generate durations (log-normal distribution)
  n_blinks <- length(timestamps)
  durations_ms <- rlnorm(n_blinks, meanlog = log(150), sdlog = 0.3)
  durations_ms <- pmin(pmax(durations_ms, 50), 500)  # Physiological range
  
  # During fatigue segments, increase duration slightly
  if (!is.null(fatigue_segments) && n_blinks > 0) {
    for (seg in fatigue_segments) {
      in_segment <- timestamps >= seg$start_s & timestamps < seg$end_s
      durations_ms[in_segment] <- durations_ms[in_segment] * 1.2
    }
  }
  
  tibble::tibble(
    timestamp = timestamps,
    duration_ms = durations_ms
  )
}

#' Compute PERCLOS from Eyelid Closure Signal
#'
#' Percentage of time eyelid is >80% closed over a window.
#'
#' @param eyelid_closure Numeric vector (0-1, where 1 = fully closed)
#' @param fs Sampling frequency
#' @param threshold Closure threshold (default 0.8)
#' @return PERCLOS percentage
#' @export

compute_perclos <- function(eyelid_closure, fs, threshold = 0.8) {
  
  if (all(is.na(eyelid_closure)) || length(eyelid_closure) == 0) {
    return(NA_real_)
  }
  
  # Count samples above threshold
  n_closed <- sum(eyelid_closure >= threshold, na.rm = TRUE)
  n_total <- sum(!is.na(eyelid_closure))
  
  if (n_total == 0) {
    return(NA_real_)
  }
  
  perclos_pct <- (n_closed / n_total) * 100
  return(perclos_pct)
}

#' Compute Rolling Blink Metrics
#'
#' @param blink_data Tibble with timestamp and duration_ms columns
#' @param window_s Window size in seconds
#' @param step_s Step size in seconds
#' @return Tibble with window_start, window_end, and blink metrics
#' @export

blink_metrics_rolling <- function(blink_data, window_s = 60, step_s = 10) {
  
  if (nrow(blink_data) == 0) {
    return(tibble::tibble(
      window_start = numeric(),
      window_end = numeric(),
      blink_rate_per_min = numeric(),
      mean_duration_ms = numeric(),
      perclos_pct = numeric()
    ))
  }
  
  max_time <- max(blink_data$timestamp)
  starts <- seq(0, max_time - window_s, by = step_s)
  
  if (length(starts) == 0) {
    starts <- 0
  }
  
  results <- lapply(starts, function(start_s) {
    end_s <- start_s + window_s
    
    window_blinks <- blink_data %>%
      filter(timestamp >= start_s, timestamp < end_s)
    
    metrics <- compute_blink_metrics(
      window_blinks$timestamp,
      window_blinks$duration_ms,
      window_s = window_s
    )
    
    tibble::tibble(
      window_start = start_s,
      window_end = end_s,
      blink_rate_per_min = metrics$blink_rate_per_min,
      mean_duration_ms = metrics$mean_blink_duration_ms,
      perclos_pct = metrics$perclos_pct,
      n_blinks = metrics$n_blinks
    )
  })
  
  dplyr::bind_rows(results)
}

