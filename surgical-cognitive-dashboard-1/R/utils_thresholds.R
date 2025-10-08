#' Threshold Utility Functions
#'
#' @description
#' Shared helpers for mapping control panel inputs to cognitive state thresholds.
#' All functions enforce interdependent logic to prevent illogical configurations.
#'
#' @details
#' Default ranges (tweakable via cfg):
#' - base_high = 0.60; base_lapse = 0.85
#' - high ∈ [0.40, 0.80]; lapse ∈ [0.70, 0.95]
#' 
#' Mapping logic:
#' - Sensitivity s maps linearly:
#'   high(s)  = high_max  - s*(high_max  - high_min)
#'   lapse(s) = lapse_max - s*(lapse_max - lapse_min)
#' - Zone->threshold mapping (heuristic):
#'   moving b_left right  -> lower lapse threshold (earlier lapse alert)
#'   moving b_right left  -> lower high_load threshold (earlier high-load alert)

#' Clamp a value to a range
#'
#' @param x Numeric value to clamp
#' @param min_val Minimum allowed value
#' @param max_val Maximum allowed value
#' @return Clamped value within [min_val, max_val]
#' @export
clamp <- function(x, min_val, max_val) {
  pmax(min_val, pmin(max_val, x))
}

#' Derive thresholds from inverted-U zone boundaries
#'
#' @param b_left Left boundary (0-1) between Low/Lapse and Optimal zones
#' @param b_right Right boundary (0-1) between Optimal and High/Overload zones
#' @param cfg Configuration list with:
#'   - base_high: baseline high-load threshold (default 0.60)
#'   - base_lapse: baseline lapse threshold (default 0.85)
#'   - high_min, high_max: bounds for high-load threshold (0.40, 0.80)
#'   - lapse_min, lapse_max: bounds for lapse threshold (0.70, 0.95)
#'   - k_left: gain for left boundary effect on lapse (default 0.25)
#'   - k_right: gain for right boundary effect on high-load (default 0.30)
#' @return List with high_load_threshold, lapse_threshold, zone_bounds
#' @export
derive_thresholds_from_zone_bounds <- function(b_left, b_right, cfg = list()) {
  # Extract config with defaults
  base_left <- cfg$base_left %||% 0.30
  base_right <- cfg$base_right %||% 0.70
  high_min <- cfg$high_min %||% 0.40
  high_max <- cfg$high_max %||% 0.80
  lapse_min <- cfg$lapse_min %||% 0.70
  lapse_max <- cfg$lapse_max %||% 0.95
  k_left <- cfg$k_left %||% 0.25
  k_right <- cfg$k_right %||% 0.30
  
  # Enforce constraints
  b_left <- clamp(b_left, 0.05, 0.95)
  b_right <- clamp(b_right, 0.05, 0.95)
  
  # Ensure min gap
  min_gap <- cfg$min_gap %||% 0.10
  if (b_right - b_left < min_gap) {
    b_right <- b_left + min_gap
  }
  b_right <- clamp(b_right, b_left + min_gap, 0.95)
  
  # Heuristic mapping (monotonic and bounded)
  # Moving b_left right → lower lapse threshold (more sensitive)
  # Moving b_right left → lower high_load threshold (more sensitive)
  lapse_threshold <- clamp(
    lapse_max - k_left * (b_left - base_left),
    lapse_min,
    lapse_max
  )
  
  high_threshold <- clamp(
    high_max - k_right * (base_right - b_right),
    high_min,
    high_max
  )
  
  # Ensure lapse > high (cognitive progression)
  if (lapse_threshold <= high_threshold) {
    lapse_threshold <- high_threshold + 0.05
  }
  lapse_threshold <- clamp(lapse_threshold, lapse_min, lapse_max)
  
  list(
    high_load_threshold = high_threshold,
    lapse_threshold = lapse_threshold,
    zone_bounds = c(b_left, b_right),
    source = "inverted_u"
  )
}

#' Derive thresholds from unified sensitivity slider
#'
#' @param s Sensitivity value (0-1). 1.0 = strict (lower thresholds, more alerts),
#'   0.0 = lenient (higher thresholds, fewer alerts)
#' @param cfg Configuration list (same as derive_thresholds_from_zone_bounds)
#' @return List with high_load_threshold, lapse_threshold, sensitivity
#' @export
derive_thresholds_from_sensitivity <- function(s, cfg = list()) {
  # Extract config with defaults
  high_min <- cfg$high_min %||% 0.40
  high_max <- cfg$high_max %||% 0.80
  lapse_min <- cfg$lapse_min %||% 0.70
  lapse_max <- cfg$lapse_max %||% 0.95
  
  # Clamp sensitivity
  s <- clamp(s, 0, 1)
  
  # Linear mapping: strict (1.0) → lower thresholds
  high_threshold <- high_max - s * (high_max - high_min)
  lapse_threshold <- lapse_max - s * (lapse_max - lapse_min)
  
  # Ensure lapse > high
  if (lapse_threshold <= high_threshold) {
    lapse_threshold <- high_threshold + 0.05
  }
  lapse_threshold <- clamp(lapse_threshold, lapse_min, lapse_max)
  
  list(
    high_load_threshold = high_threshold,
    lapse_threshold = lapse_threshold,
    sensitivity = s,
    source = "sensitivity"
  )
}

#' Derive fatigue-adjusted thresholds
#'
#' @param t_minutes Current time in minutes
#' @param baseline List with high_load_threshold0, lapse_threshold0
#' @param profile List with:
#'   - t0: start time for fatigue effect (minutes)
#'   - t1: end time for full fatigue effect (minutes)
#'   - f_shape: "linear" or "logistic"
#'   - k_high: gain for high-load threshold decay
#'   - k_lapse: gain for lapse threshold decay
#' @param cfg Configuration list for bounds
#' @return List with high_load_threshold, lapse_threshold (time-varying)
#' @export
derive_fatigue_adjusted_thresholds <- function(t_minutes, baseline, profile, cfg = list()) {
  # Extract config
  high_min <- cfg$high_min %||% 0.40
  high_max <- cfg$high_max %||% 0.80
  lapse_min <- cfg$lapse_min %||% 0.70
  lapse_max <- cfg$lapse_max %||% 0.95
  
  # Extract profile parameters
  t0 <- profile$t0 %||% 0
  t1 <- profile$t1 %||% 30
  f_shape <- profile$f_shape %||% "linear"
  k_high <- profile$k_high %||% 0.15
  k_lapse <- profile$k_lapse %||% 0.10
  
  # Compute fatigue factor f(t) ∈ [0, 1]
  if (f_shape == "logistic") {
    t_mid <- (t0 + t1) / 2
    a <- 8 / (t1 - t0)  # steepness parameter
    f_t <- 1 / (1 + exp(-a * (t_minutes - t_mid)))
  } else {  # linear
    f_t <- clamp((t_minutes - t0) / (t1 - t0), 0, 1)
  }
  
  # Apply time-based decay (thresholds decrease over time = more sensitive)
  high_threshold_t <- clamp(
    baseline$high_load_threshold0 - k_high * f_t,
    high_min,
    high_max
  )
  
  lapse_threshold_t <- clamp(
    baseline$lapse_threshold0 - k_lapse * f_t,
    lapse_min,
    lapse_max
  )
  
  # Ensure lapse > high
  if (lapse_threshold_t <= high_threshold_t) {
    lapse_threshold_t <- high_threshold_t + 0.05
  }
  lapse_threshold_t <- clamp(lapse_threshold_t, lapse_min, lapse_max)
  
  list(
    high_load_threshold = high_threshold_t,
    lapse_threshold = lapse_threshold_t,
    fatigue_factor = f_t,
    time_minutes = t_minutes,
    source = "fatigue"
  )
}

# Internal helper for %||% operator (if not available)
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

