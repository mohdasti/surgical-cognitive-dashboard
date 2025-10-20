#' HRV Feature Engineering Functions
#' 
#' Evidence-based HRV features for cognitive workload classification
#' Following the specification from ChatGPT's evidence-based model design

# ============================================================================
# Time-Domain Features
# ============================================================================

#' Compute RMSSD (Root Mean Square of Successive Differences)
#' @param rr_ms Vector of RR intervals in milliseconds
#' @return RMSSD value in milliseconds
compute_rmssd <- function(rr_ms) {
  if (length(rr_ms) < 3 || anyNA(rr_ms) || any(is.na(rr_ms))) return(NA_real_)
  sqrt(mean(diff(rr_ms)^2, na.rm = TRUE))
}

#' Compute SDNN (Standard Deviation of NN intervals)
#' @param rr_ms Vector of RR intervals in milliseconds
#' @return SDNN value in milliseconds
compute_sdnn <- function(rr_ms) {
  if (length(rr_ms) < 3 || anyNA(rr_ms)) return(NA_real_)
  sd(rr_ms, na.rm = TRUE)
}

#' Compute pNN50 (% of successive RR intervals differing by >50ms)
#' @param rr_ms Vector of RR intervals in milliseconds
#' @return pNN50 percentage (0-100)
compute_pnn50 <- function(rr_ms) {
  if (length(rr_ms) < 3 || anyNA(rr_ms)) return(NA_real_)
  diffs <- abs(diff(rr_ms))
  100 * sum(diffs > 50, na.rm = TRUE) / length(diffs)
}

# ============================================================================
# Frequency-Domain Features (Welch PSD)
# ============================================================================

#' Compute HF and LF power using Welch PSD
#' @param rr_ms Vector of RR intervals in milliseconds
#' @param fs Sampling frequency (Hz) for resampled tachogram (default 4 Hz)
#' @return List with hf_power, lf_power, lf_hf_ratio
compute_freq_domain <- function(rr_ms, fs = 4) {
  if (length(rr_ms) < 10 || anyNA(rr_ms)) {
    return(list(hf_power = NA_real_, lf_power = NA_real_, lf_hf_ratio = NA_real_))
  }
  
  tryCatch({
    # Create time vector from RR intervals
    t_rr <- c(0, cumsum(rr_ms)) / 1000  # Convert to seconds
    
    # Resample to even grid (4 Hz)
    t_even <- seq(min(t_rr), max(t_rr), by = 1/fs)
    if (length(t_even) < 10) {
      return(list(hf_power = NA_real_, lf_power = NA_real_, lf_hf_ratio = NA_real_))
    }
    
    # Interpolate heart rate (bpm) on even grid
    hr_even <- 60000 / approx(t_rr[-1], rr_ms, xout = t_even, rule = 2)$y
    
    # Detrend
    hr_detrend <- hr_even - mean(hr_even, na.rm = TRUE)
    
    # Welch PSD using signal package
    if (!requireNamespace("signal", quietly = TRUE)) {
      return(list(hf_power = NA_real_, lf_power = NA_real_, lf_hf_ratio = NA_real_))
    }
    
    psd <- signal::pwelch(hr_detrend, fs = fs, window = min(256, length(hr_detrend)))
    freqs <- psd$freq
    power <- psd$spec
    
    # Integrate power in LF (0.04-0.15 Hz) and HF (0.15-0.40 Hz) bands
    lf_idx <- freqs >= 0.04 & freqs < 0.15
    hf_idx <- freqs >= 0.15 & freqs <= 0.40
    
    lf_power <- sum(power[lf_idx], na.rm = TRUE)
    hf_power <- sum(power[hf_idx], na.rm = TRUE)
    lf_hf_ratio <- ifelse(hf_power > 0, lf_power / hf_power, NA_real_)
    
    list(hf_power = hf_power, lf_power = lf_power, lf_hf_ratio = lf_hf_ratio)
  }, error = function(e) {
    list(hf_power = NA_real_, lf_power = NA_real_, lf_hf_ratio = NA_real_)
  })
}

# ============================================================================
# Nonlinear Features
# ============================================================================

#' Compute Poincaré plot SD1 (short-term variability)
#' @param rr_ms Vector of RR intervals in milliseconds
#' @return SD1 value in milliseconds
compute_sd1_poincare <- function(rr_ms) {
  if (length(rr_ms) < 3 || anyNA(rr_ms)) return(NA_real_)
  
  # SD1 = SD of points perpendicular to identity line
  # SD1 = sqrt(0.5 * var(RR_n+1 - RR_n))
  diffs <- diff(rr_ms)
  sd1 <- sqrt(0.5 * var(diffs, na.rm = TRUE))
  
  return(sd1)
}

#' Compute Sample Entropy (SampEn)
#' @param rr_ms Vector of RR intervals in milliseconds
#' @param m Embedding dimension (default 2)
#' @param r Tolerance (default 0.2 * SD)
#' @return Sample entropy value
compute_sampen <- function(rr_ms, m = 2, r = NULL) {
  if (length(rr_ms) < 10 || anyNA(rr_ms)) return(NA_real_)
  
  # Set tolerance to 0.2 * SD if not provided
  if (is.null(r)) {
    r <- 0.2 * sd(rr_ms, na.rm = TRUE)
  }
  
  tryCatch({
    # Simplified Sample Entropy calculation
    N <- length(rr_ms)
    
    # Count template matches for m and m+1
    count_matches <- function(m_val) {
      matches <- 0
      comparisons <- 0
      
      for (i in 1:(N - m_val)) {
        template <- rr_ms[i:(i + m_val - 1)]
        
        for (j in 1:(N - m_val)) {
          if (i != j) {
            candidate <- rr_ms[j:(j + m_val - 1)]
            
            # Check if max distance < r
            if (max(abs(template - candidate)) < r) {
              matches <- matches + 1
            }
            comparisons <- comparisons + 1
          }
        }
      }
      
      list(matches = matches, comparisons = comparisons)
    }
    
    m_result <- count_matches(m)
    m1_result <- count_matches(m + 1)
    
    if (m_result$matches == 0 || m1_result$matches == 0) {
      return(NA_real_)
    }
    
    # SampEn = -log(A/B) where A = matches at m+1, B = matches at m
    sampen <- -log(m1_result$matches / m_result$matches)
    
    return(sampen)
  }, error = function(e) {
    return(NA_real_)
  })
}

# ============================================================================
# Rolling Window Feature Computation
# ============================================================================

#' Compute rolling HRV features
#' @param rr_ms Vector of RR intervals in milliseconds
#' @param t_rr Vector of timestamps (seconds) aligned to RR intervals
#' @param win_s Window size in seconds
#' @param step_s Step size in seconds
#' @param features Character vector of features to compute
#' @return Data frame with time and computed features
rolling_hrv_features <- function(rr_ms, t_rr, win_s = 60, step_s = 1, 
                                 features = c("rmssd", "sdnn", "pnn50")) {
  
  if (length(rr_ms) != length(t_rr)) stop("rr_ms and t_rr must align")
  
  start_t <- min(t_rr, na.rm = TRUE)
  end_t <- max(t_rr, na.rm = TRUE)
  
  # Output containers
  out <- list()
  out$t <- c()
  
  for (feat in features) {
    out[[feat]] <- c()
  }
  
  # Slide window
  for (tt in seq(from = start_t + win_s, to = end_t, by = step_s)) {
    sel <- t_rr > (tt - win_s) & t_rr <= tt
    window_rr <- rr_ms[sel]
    
    if (sum(sel) < 3) {
      # Not enough data
      out$t <- c(out$t, tt)
      for (feat in features) {
        out[[feat]] <- c(out[[feat]], NA_real_)
      }
      next
    }
    
    out$t <- c(out$t, tt)
    
    # Compute requested features
    if ("rmssd" %in% features) {
      out$rmssd <- c(out$rmssd, compute_rmssd(window_rr))
    }
    if ("sdnn" %in% features) {
      out$sdnn <- c(out$sdnn, compute_sdnn(window_rr))
    }
    if ("pnn50" %in% features) {
      out$pnn50 <- c(out$pnn50, compute_pnn50(window_rr))
    }
    if ("sd1" %in% features) {
      out$sd1 <- c(out$sd1, compute_sd1_poincare(window_rr))
    }
    if ("sampen" %in% features) {
      out$sampen <- c(out$sampen, compute_sampen(window_rr))
    }
    if ("hf" %in% features || "lf" %in% features || "lf_hf" %in% features) {
      freq <- compute_freq_domain(window_rr)
      if ("hf" %in% features) out$hf <- c(out$hf, freq$hf_power)
      if ("lf" %in% features) out$lf <- c(out$lf, freq$lf_power)
      if ("lf_hf" %in% features) out$lf_hf <- c(out$lf_hf, freq$lf_hf_ratio)
    }
  }
  
  as.data.frame(out)
}

# ============================================================================
# Derived Features
# ============================================================================

#' Compute within-subject z-score
#' @param x Vector of values
#' @param baseline_indices Indices to use for baseline (first 3 minutes)
#' @return Z-scored values
compute_z_score <- function(x, baseline_indices = NULL) {
  if (is.null(baseline_indices)) {
    baseline_indices <- seq_len(min(180, length(x)))  # First 3 min at 1Hz
  }
  
  baseline_mean <- mean(x[baseline_indices], na.rm = TRUE)
  baseline_sd <- sd(x[baseline_indices], na.rm = TRUE)
  
  if (is.na(baseline_sd) || baseline_sd == 0) {
    return(rep(NA_real_, length(x)))
  }
  
  (x - baseline_mean) / baseline_sd
}

#' Compute percentage drop from baseline
#' @param x Vector of values
#' @param baseline_indices Indices to use for baseline
#' @return Percentage drop (negative = decrease)
compute_pct_drop <- function(x, baseline_indices = NULL) {
  if (is.null(baseline_indices)) {
    baseline_indices <- seq_len(min(180, length(x)))
  }
  
  baseline_mean <- mean(x[baseline_indices], na.rm = TRUE)
  
  if (is.na(baseline_mean) || baseline_mean == 0) {
    return(rep(NA_real_, length(x)))
  }
  
  100 * (x - baseline_mean) / baseline_mean
}

#' Compute linear slope over window
#' @param x Vector of values
#' @param t Vector of time points
#' @param win_s Window size in seconds
#' @return Slope (units per second)
compute_slope <- function(x, t, win_s = 120) {
  if (length(x) != length(t)) stop("x and t must align")
  
  n <- length(x)
  slopes <- rep(NA_real_, n)
  
  for (i in seq_along(x)) {
    # Look back win_s seconds
    sel <- t >= (t[i] - win_s) & t <= t[i]
    
    if (sum(sel) < 5) {
      next
    }
    
    window_x <- x[sel]
    window_t <- t[sel]
    
    # Remove NAs
    valid <- !is.na(window_x) & !is.na(window_t)
    if (sum(valid) < 3) {
      next
    }
    
    # Linear regression
    fit <- lm(window_x[valid] ~ window_t[valid])
    slopes[i] <- coef(fit)[2]
  }
  
  slopes
}

