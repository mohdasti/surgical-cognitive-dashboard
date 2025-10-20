#' HRV Feature Computation
#'
#' @description
#' Robust RMSSD (Root Mean Square of Successive Differences) computation
#' for heart rate variability analysis in real-time streaming data.
#'
#' @details
#' RMSSD is a time-domain HRV metric that reflects parasympathetic
#' (vagal) tone. Lower RMSSD typically accompanies sustained cognitive load.

#' Compute RMSSD from Inter-Beat Intervals
#'
#' @param ibi_ms Numeric vector of inter-beat intervals in milliseconds
#' @return RMSSD value in milliseconds, or NA if insufficient data
#' @export
compute_rmssd <- function(ibi_ms) {
  if (length(ibi_ms) < 3 || anyNA(ibi_ms)) return(NA_real_)
  sqrt(mean(diff(ibi_ms)^2, na.rm = TRUE))
}

#' Compute Rolling RMSSD over Time Windows
#'
#' @param ibi_ms Numeric vector of inter-beat intervals in milliseconds
#' @param t_index Time index (POSIXct or seconds) aligned to ibi_ms
#' @param win_s Window size in seconds (default: 60s)
#' @param step_s Step size in seconds (default: 1s)
#' @return Data frame with columns: t (time), rmssd (RMSSD values)
#' @export
rolling_rmssd <- function(ibi_ms, t_index, win_s = 60, step_s = 1) {
  # Validate inputs
  if (length(ibi_ms) != length(t_index)) {
    stop("ibi_ms and t_index must align")
  }
  
  out_t <- c()
  out_v <- c()
  
  start_t <- min(t_index, na.rm = TRUE)
  end_t <- max(t_index, na.rm = TRUE)
  
  for (tt in seq(from = start_t + win_s, to = end_t, by = step_s)) {
    sel <- t_index > (tt - win_s) & t_index <= tt
    v <- if (sum(sel) >= 3) compute_rmssd(ibi_ms[sel]) else NA_real_
    out_t <- c(out_t, tt)
    out_v <- c(out_v, v)
  }
  
  data.frame(t = out_t, rmssd = out_v)
}

