#' Tremor Analysis Utilities
#'
#' Functions for extracting tremor RMS from kinematic signals and computing
#' fatigue-related growth metrics.
#'
#' @references
#' Elble, R.J., & Koller, W.C. (1990). Tremor. Johns Hopkins University Press.
#' Riviere, C.N., et al. (1997). Characteristics of surgical tremor.

suppressPackageStartupMessages({
  library(dplyr)
  library(signal)  # For butter, filtfilt
})

#' Compute Tremor RMS in Specified Frequency Band
#'
#' Applies bandpass filter and computes RMS amplitude in micrometers.
#'
#' @param signal Numeric vector of position/velocity signal
#' @param fs Sampling frequency in Hz
#' @param band Frequency band as c(low_hz, high_hz), default c(8, 12)
#' @param unit_scale Scaling factor to convert signal to micrometers (default 1)
#' @return Numeric RMS amplitude in micrometers
#' @export
#'
#' @examples
#' # Simulate tremor at 10 Hz
#' fs <- 100
#' t <- seq(0, 10, by = 1/fs)
#' signal <- 50 * sin(2 * pi * 10 * t) + rnorm(length(t), sd = 10)
#' rms <- tremor_rms(signal, fs = fs, band = c(8, 12))

tremor_rms <- function(signal, fs, band = c(8, 12), unit_scale = 1) {
  
  # Handle missing/NA values
  if (all(is.na(signal)) || length(signal) < 10) {
    warning("Insufficient signal for tremor analysis")
    return(NA_real_)
  }
  
  # Remove NAs by interpolation
  if (any(is.na(signal))) {
    idx <- seq_along(signal)
    good <- !is.na(signal)
    signal <- approx(idx[good], signal[good], xout = idx, rule = 2)$y
  }
  
  # Validate band
  nyquist <- fs / 2
  if (band[1] >= nyquist || band[2] >= nyquist) {
    warning(sprintf("Band [%s, %s] Hz exceeds Nyquist frequency %s Hz", 
                    band[1], band[2], nyquist))
    return(NA_real_)
  }
  
  # Design Butterworth bandpass filter (4th order)
  tryCatch({
    bf <- signal::butter(n = 4, W = band / nyquist, type = "pass")
    
    # Apply zero-phase filter (forward-backward)
    filtered <- signal::filtfilt(bf, signal)
    
    # Compute RMS
    rms <- sqrt(mean(filtered^2, na.rm = TRUE)) * unit_scale
    
    return(rms)
    
  }, error = function(e) {
    warning(sprintf("Tremor filtering failed: %s", e$message))
    return(NA_real_)
  })
}

#' Compute Tremor Growth Percentage vs. Baseline
#'
#' @param current_rms Current RMS amplitude
#' @param baseline_rms Baseline (fresh) RMS amplitude
#' @return Percentage increase relative to baseline
#' @export
#'
#' @examples
#' baseline <- 100  # μm
#' current <- 125   # μm
#' growth <- tremor_growth_pct(current, baseline)  # 25%

tremor_growth_pct <- function(current_rms, baseline_rms) {
  if (is.na(current_rms) || is.na(baseline_rms) || baseline_rms <= 0) {
    return(NA_real_)
  }
  
  growth <- ((current_rms - baseline_rms) / baseline_rms) * 100
  return(growth)
}

#' Estimate Dominant Tremor Frequency
#'
#' Finds peak frequency in physiological tremor band using FFT.
#'
#' @param signal Numeric vector of position/velocity signal
#' @param fs Sampling frequency in Hz
#' @param band Frequency range to search c(low_hz, high_hz)
#' @return Dominant frequency in Hz
#' @export

tremor_peak_freq <- function(signal, fs, band = c(8, 12)) {
  
  if (all(is.na(signal)) || length(signal) < 10) {
    return(NA_real_)
  }
  
  # Remove NAs
  signal <- signal[!is.na(signal)]
  
  # Zero-pad to next power of 2
  n <- length(signal)
  nfft <- 2^ceiling(log2(n))
  signal_padded <- c(signal, rep(0, nfft - n))
  
  # Compute FFT
  fft_result <- fft(signal_padded)
  magnitude <- Mod(fft_result[1:(nfft/2)])
  freq <- seq(0, fs/2, length.out = nfft/2)
  
  # Find peak in band
  band_idx <- freq >= band[1] & freq <= band[2]
  if (sum(band_idx) == 0) {
    return(NA_real_)
  }
  
  peak_idx <- which.max(magnitude[band_idx])
  peak_freq <- freq[band_idx][peak_idx]
  
  return(peak_freq)
}

#' Compute Tremor Statistics for Window
#'
#' Combined function that computes RMS, peak frequency, and growth metrics.
#'
#' @param signal Numeric vector
#' @param fs Sampling frequency
#' @param band Frequency band c(low, high)
#' @param baseline_rms Optional baseline for growth calculation
#' @param unit_scale Scaling to micrometers
#' @return List with rms_um, peak_freq_hz, growth_pct
#' @export

tremor_stats <- function(signal, fs, band = c(8, 12), 
                         baseline_rms = NULL, unit_scale = 1) {
  
  rms <- tremor_rms(signal, fs, band, unit_scale)
  peak_freq <- tremor_peak_freq(signal, fs, band)
  
  growth_pct <- if (!is.null(baseline_rms)) {
    tremor_growth_pct(rms, baseline_rms)
  } else {
    NA_real_
  }
  
  return(list(
    rms_um = rms,
    peak_freq_hz = peak_freq,
    growth_pct = growth_pct
  ))
}

#' Model Nonlinear Tremor Growth with Fatigue
#'
#' Predicts tremor RMS based on time-on-task using literature-validated model.
#'
#' @param time_on_task_min Minutes since procedure start
#' @param baseline_rms Baseline RMS amplitude
#' @param growth_first_30min Percentage growth in first 30 minutes
#' @param growth_per_hr_after Percentage growth per hour after 30 minutes
#' @return Expected RMS amplitude in micrometers
#' @export
#'
#' @examples
#' baseline <- 100  # μm
#' # After 60 minutes
#' expected <- tremor_fatigue_model(60, baseline, 
#'                                  growth_first_30min = 10, 
#'                                  growth_per_hr_after = 25)

tremor_fatigue_model <- function(time_on_task_min, baseline_rms, 
                                 growth_first_30min = 10, 
                                 growth_per_hr_after = 25) {
  
  if (time_on_task_min <= 30) {
    # Linear growth in first 30 minutes
    growth_pct <- (time_on_task_min / 30) * growth_first_30min
  } else {
    # Accumulated growth after 30 minutes
    hours_after <- (time_on_task_min - 30) / 60
    growth_pct <- growth_first_30min + (hours_after * growth_per_hr_after)
  }
  
  expected_rms <- baseline_rms * (1 + growth_pct / 100)
  return(expected_rms)
}

#' Extract Tremor from Robot Kinematics
#'
#' Derives tremor signal from high-rate position or velocity data.
#'
#' @param kinematics_df Tibble with timestamp, x, y, z columns (or velocity)
#' @param fs Sampling frequency
#' @param coordinate Which coordinate to analyze ("x", "y", "z", or "all")
#' @param band Tremor frequency band
#' @return Tremor RMS in micrometers
#' @export

tremor_from_kinematics <- function(kinematics_df, fs, 
                                   coordinate = "all", band = c(8, 12)) {
  
  if (nrow(kinematics_df) < 10) {
    return(NA_real_)
  }
  
  if (coordinate == "all") {
    # Compute 3D magnitude
    if (all(c("x", "y", "z") %in% names(kinematics_df))) {
      signal <- sqrt(kinematics_df$x^2 + 
                     kinematics_df$y^2 + 
                     kinematics_df$z^2)
    } else {
      warning("x, y, z columns not found, using first numeric column")
      signal <- kinematics_df[[which(sapply(kinematics_df, is.numeric))[1]]]
    }
  } else {
    if (!coordinate %in% names(kinematics_df)) {
      stop(sprintf("Coordinate '%s' not found in data", coordinate))
    }
    signal <- kinematics_df[[coordinate]]
  }
  
  # Convert to velocity if needed (derivative)
  if (all(c("x", "y", "z") %in% names(kinematics_df))) {
    # Position data - compute velocity
    signal <- c(0, diff(signal) * fs)
  }
  
  # Compute tremor RMS
  rms <- tremor_rms(signal, fs, band, unit_scale = 1000)  # mm to μm
  
  return(rms)
}

