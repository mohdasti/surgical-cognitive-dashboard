#' Calibration Metrics for Probability Predictions
#'
#' @description
#' Computes Expected Calibration Error (ECE), Maximum Calibration Error (MCE),
#' and Brier Score for binary classification probability predictions.
#'
#' @details
#' ECE measures the average absolute difference between predicted probabilities
#' and observed frequencies across probability bins.
#' MCE is the maximum absolute difference across bins.
#' Brier Score is the mean squared error between predictions and outcomes.

#' Compute Calibration Metrics
#'
#' @param p_hat Numeric vector of predicted probabilities [0,1]
#' @param y Numeric/integer vector of binary outcomes (0 or 1)
#' @param bins Number of bins for calibration (default: 10)
#' @return List with df (calibration data frame), ece, mce, brier
#' @export
#'
#' @examples
#' # Simulated predictions
#' p_hat <- runif(1000)
#' y <- rbinom(1000, 1, p_hat)
#' m <- calib_metrics(p_hat, y, bins = 10)
#' print(c(ECE = m$ece, MCE = m$mce, Brier = m$brier))
calib_metrics <- function(p_hat, y, bins = 10) {
  stopifnot(length(p_hat) == length(y))
  
  # Create quantile-based bins
  brk <- quantile(p_hat, probs = seq(0, 1, length.out = bins + 1), 
                  na.rm = TRUE, type = 8)
  idx <- cut(p_hat, include.lowest = TRUE, breaks = unique(brk))
  
  # Aggregate by bin
  df <- aggregate(
    list(p = p_hat, y = y), 
    by = list(bin = idx), 
    function(z) mean(z, na.rm = TRUE)
  )
  df$n <- as.numeric(table(idx))
  
  # Compute metrics
  ece <- sum(df$n / sum(df$n) * abs(df$y - df$p))
  mce <- max(abs(df$y - df$p))
  brier <- mean((p_hat - y)^2)
  
  list(df = df, ece = ece, mce = mce, brier = brier)
}

