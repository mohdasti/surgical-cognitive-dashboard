#' HRV Computation Utilities
#' 
#' Functions for computing heart rate variability metrics from RR intervals.
#' Supports both time-domain (SDNN, RMSSD) and frequency-domain (LF, HF) metrics.
#'
#' @references
#' Task Force of the European Society of Cardiology (1996). Heart rate variability.
#' Circulation, 93(5), 1043-1065.

suppressPackageStartupMessages({
  library(dplyr)
  library(zoo)
})

#' Compute HRV Metrics from RR Intervals
#'
#' @param rr_ms Numeric vector of RR intervals in milliseconds
#' @param fs Sampling frequency for interpolation (Hz), default 4 Hz
#' @param window_s Window duration in seconds, default 300s (5 min)
#' @param remove_ectopics Logical, filter outlier RR intervals
#' @return List with SDNN, RMSSD, LF, HF, LF_HF metrics
#' @export
#'
#' @examples
#' # Simulate RR intervals around 60 BPM (1000ms mean)
#' rr <- rnorm(300, mean = 1000, sd = 50)
#' hrv <- compute_hrv(rr)
#' hrv$SDNN  # Standard deviation of NN intervals
#' hrv$RMSSD # Root mean square of successive differences

compute_hrv <- function(rr_ms, fs = 4, window_s = 300, remove_ectopics = TRUE) {
  
  # Validate input
  if (length(rr_ms) < 10) {
    warning("Insufficient RR intervals for HRV analysis (need >= 10)")
    return(list(
      SDNN = NA_real_,
      RMSSD = NA_real_,
      LF_power = NA_real_,
      HF_power = NA_real_,
      LF_HF = NA_real_,
      n_intervals = length(rr_ms)
    ))
  }
  
  # Remove NAs
  rr_ms <- rr_ms[!is.na(rr_ms)]
  
  # Filter ectopic beats (simple threshold method)
  if (remove_ectopics) {
    rr_ms <- filter_ectopics(rr_ms)
    if (length(rr_ms) < 10) {
      warning("Too few intervals remaining after ectopic removal")
      return(list(
        SDNN = NA_real_,
        RMSSD = NA_real_,
        LF_power = NA_real_,
        HF_power = NA_real_,
        LF_HF = NA_real_,
        n_intervals = length(rr_ms)
      ))
    }
  }
  
  # Time-domain metrics
  sdnn <- sd(rr_ms, na.rm = TRUE)
  
  # RMSSD: root mean square of successive differences
  diff_rr <- diff(rr_ms)
  rmssd <- sqrt(mean(diff_rr^2, na.rm = TRUE))
  
  # Frequency-domain metrics (simplified PSD estimation)
  freq_metrics <- tryCatch({
    compute_hrv_frequency(rr_ms, fs)
  }, error = function(e) {
    list(LF_power = NA_real_, HF_power = NA_real_, LF_HF = NA_real_)
  })
  
  return(list(
    SDNN = sdnn,
    RMSSD = rmssd,
    LF_power = freq_metrics$LF_power,
    HF_power = freq_metrics$HF_power,
    LF_HF = freq_metrics$LF_HF,
    n_intervals = length(rr_ms)
  ))
}

#' Filter Ectopic Beats (Simple Threshold Method)
#' @keywords internal
filter_ectopics <- function(rr_ms, threshold_sd = 3) {
  median_rr <- median(rr_ms, na.rm = TRUE)
  mad_rr <- mad(rr_ms, na.rm = TRUE)
  
  # Keep RR intervals within threshold_sd * MAD of median
  lower <- median_rr - threshold_sd * mad_rr
  upper <- median_rr + threshold_sd * mad_rr
  
  rr_filtered <- rr_ms[rr_ms >= lower & rr_ms <= upper]
  
  if (length(rr_filtered) < length(rr_ms) * 0.8) {
    warning(sprintf("Filtered %d/%d intervals as ectopic", 
                    length(rr_ms) - length(rr_filtered), length(rr_ms)))
  }
  
  return(rr_filtered)
}

#' Compute Frequency-Domain HRV Metrics
#' @keywords internal
compute_hrv_frequency <- function(rr_ms, fs = 4) {
  
  # Create time vector (cumulative sum of RR intervals)
  time_s <- cumsum(c(0, rr_ms[-length(rr_ms)])) / 1000
  
  # Interpolate to evenly sampled tachogram
  time_regular <- seq(min(time_s), max(time_s), by = 1/fs)
  if (length(time_regular) < 10) {
    return(list(LF_power = NA_real_, HF_power = NA_real_, LF_HF = NA_real_))
  }
  
  rr_interp <- approx(time_s, rr_ms, xout = time_regular, rule = 2)$y
  
  # Remove trend (detrend)
  rr_detrend <- rr_interp - mean(rr_interp, na.rm = TRUE)
  
  # Compute Power Spectral Density using Welch's method (simplified)
  psd <- compute_psd_welch(rr_detrend, fs)
  
  # Extract LF (0.04-0.15 Hz) and HF (0.15-0.4 Hz) power
  freq <- psd$freq
  power <- psd$power
  
  lf_idx <- freq >= 0.04 & freq < 0.15
  hf_idx <- freq >= 0.15 & freq <= 0.4
  
  lf_power <- sum(power[lf_idx], na.rm = TRUE)
  hf_power <- sum(power[hf_idx], na.rm = TRUE)
  lf_hf_ratio <- if (hf_power > 0) lf_power / hf_power else NA_real_
  
  return(list(
    LF_power = lf_power,
    HF_power = hf_power,
    LF_HF = lf_hf_ratio
  ))
}

#' Simplified Welch PSD Estimation
#' @keywords internal
compute_psd_welch <- function(signal, fs, nfft = 256) {
  n <- length(signal)
  
  if (n < nfft) {
    nfft <- 2^floor(log2(n))
  }
  
  # Zero-pad if needed
  if (n < nfft) {
    signal <- c(signal, rep(0, nfft - n))
  }
  
  # Compute FFT
  fft_result <- fft(signal[1:nfft])
  power <- Mod(fft_result[1:(nfft/2)])^2 / nfft
  freq <- seq(0, fs/2, length.out = nfft/2)
  
  return(list(freq = freq, power = power))
}

#' Subscribe to RR Interval Data Source
#'
#' Creates a reactive for Shiny that reads RR intervals from various sources
#'
#' @param source Character: "simulate", "csv", or "websocket"
#' @param path Path to CSV file (if source = "csv")
#' @param params Parameters object (if source = "simulate")
#' @return Reactive expression returning tibble with timestamp_ms, rr_ms columns
#' @export
subscribe_rr <- function(source = "simulate", path = NULL, params = NULL) {
  
  if (source == "simulate") {
    # Simulate RR intervals based on params
    if (is.null(params)) {
      stop("params required for simulate mode")
    }
    
    return(function() {
      # Generate simulated RR intervals
      # Mean RR from baseline HR (~60 BPM = 1000ms)
      mean_rr <- 1000
      sd_rr <- params$hrv$rmssd_ms_baseline
      
      # Generate ~5 minutes of data
      n_beats <- 300
      rr_ms <- rnorm(n_beats, mean = mean_rr, sd = sd_rr)
      rr_ms <- pmax(rr_ms, 400)  # Physiological minimum
      rr_ms <- pmin(rr_ms, 2000) # Physiological maximum
      
      tibble::tibble(
        timestamp_ms = cumsum(c(0, rr_ms[-length(rr_ms)])),
        rr_ms = rr_ms
      )
    })
    
  } else if (source == "csv") {
    # Read from CSV file
    if (is.null(path) || !file.exists(path)) {
      stop(sprintf("CSV file not found: %s", path))
    }
    
    return(function() {
      readr::read_csv(path, col_types = "dd", show_col_types = FALSE)
    })
    
  } else if (source == "websocket") {
    stop("WebSocket source not yet implemented")
    
  } else {
    stop(sprintf("Unknown source: %s", source))
  }
}

#' Compute HRV Metrics for Rolling Windows
#'
#' @param rr_data Tibble with timestamp_ms and rr_ms columns
#' @param window_s Window size in seconds
#' @param step_s Step size in seconds (for overlapping windows)
#' @return Tibble with window_start, window_end, and HRV metrics
#' @export
compute_hrv_rolling <- function(rr_data, window_s = 300, step_s = 60) {
  
  if (nrow(rr_data) == 0) {
    return(tibble::tibble(
      window_start = numeric(),
      window_end = numeric(),
      SDNN = numeric(),
      RMSSD = numeric(),
      LF_power = numeric(),
      HF_power = numeric(),
      LF_HF = numeric()
    ))
  }
  
  window_ms <- window_s * 1000
  step_ms <- step_s * 1000
  
  max_time <- max(rr_data$timestamp_ms)
  starts <- seq(0, max_time - window_ms, by = step_ms)
  
  results <- lapply(starts, function(start_ms) {
    end_ms <- start_ms + window_ms
    window_rr <- rr_data %>%
      filter(timestamp_ms >= start_ms, timestamp_ms < end_ms) %>%
      pull(rr_ms)
    
    hrv <- compute_hrv(window_rr, window_s = window_s)
    
    tibble::tibble(
      window_start = start_ms / 1000,
      window_end = end_ms / 1000,
      SDNN = hrv$SDNN,
      RMSSD = hrv$RMSSD,
      LF_power = hrv$LF_power,
      HF_power = hrv$HF_power,
      LF_HF = hrv$LF_HF
    )
  })
  
  dplyr::bind_rows(results)
}

