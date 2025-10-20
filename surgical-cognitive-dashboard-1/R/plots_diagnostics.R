#' Diagnostics Plotting Functions
#'
#' @description
#' Reusable plotting functions for ML diagnostics.
#' These functions are used by both diagnostic scripts and the showcase script.

#' Plot Calibration (Reliability Diagram)
#'
#' @param p_hat Predicted probabilities
#' @param y True binary labels (0/1)
#' @param bins Number of calibration bins (default: 10)
#' @return ggplot object
#' @export
plot_calibration_lapse_demo <- function(p_hat, y, bins = 10) {
  # Source dependencies
  if (!exists("md_colors")) {
    if (file.exists("R/theme_md.R")) {
      source("R/theme_md.R")
    }
  }
  if (!exists("calib_metrics")) {
    if (file.exists("R/calibration_metrics.R")) {
      source("R/calibration_metrics.R")
    }
  }
  
  m <- calib_metrics(p_hat = p_hat, y = y, bins = bins)
  
  ggplot2::ggplot(m$df, ggplot2::aes(p, y)) +
    ggplot2::geom_point(ggplot2::aes(size = n), alpha = 0.85, colour = md_colors$warn) +
    ggplot2::geom_line(colour = md_colors$warn, linewidth = 1) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = 2, colour = md_colors$muted) +
    ggplot2::scale_size_area(max_size = 10, guide = "none") +
    ggplot2::scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
    ggplot2::scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
    ggplot2::labs(
      title = "Probability Calibration — Attentional Lapse",
      subtitle = sprintf("ECE=%.3f · MCE=%.3f · Brier=%.3f", m$ece, m$mce, m$brier),
      x = "Predicted Probability",
      y = "Observed Frequency"
    ) +
    ggplot2::theme_minimal() + theme_md()
}

#' Plot Probability Distributions by True State
#'
#' @param data Data frame with true_state and prob_lapse columns
#' @param bins Number of histogram bins (default: 35)
#' @return ggplot object
#' @export
plot_prob_dists_demo <- function(data, bins = 35) {
  if (!exists("scale_state_fill")) {
    if (file.exists("R/theme_md.R")) {
      source("R/theme_md.R")
    }
  }
  
  # Handle both column names for compatibility
  x_col <- if ("prob_lapse" %in% names(data)) "prob_lapse" else "lapse_prob"
  
  ggplot2::ggplot(data, ggplot2::aes(x = .data[[x_col]], fill = true_state)) +
    ggplot2::geom_histogram(bins = bins, alpha = 0.85, position = "identity") +
    ggplot2::facet_wrap(~ true_state, ncol = 1, scales = "free_y") +
    scale_state_fill() +
    ggplot2::scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
    ggplot2::labs(
      title = "Predicted Probability Distributions by True State",
      subtitle = "Lapse probability predictions grouped by actual cognitive state",
      x = "P(Attentional Lapse)",
      y = "Count"
    ) +
    ggplot2::theme_minimal() + theme_md() +
    ggplot2::theme(
      strip.text = ggplot2::element_text(face = "bold", size = 11),
      legend.position = "none"
    )
}

#' Plot Prediction Stability (2-panel)
#'
#' @param data Data frame with time_min, prob_lapse, prob_lapse_smooth, prob_lapse_sd
#' @return Combined ggplot object or list of plots
#' @export
plot_stability_lapse_demo <- function(data) {
  if (!exists("md_colors")) {
    if (file.exists("R/theme_md.R")) {
      source("R/theme_md.R")
    }
  }
  
  # Top panel: Raw vs Smoothed
  p_top <- ggplot2::ggplot(data, ggplot2::aes(x = time_min)) +
    ggplot2::geom_line(ggplot2::aes(y = prob_lapse, color = "Raw"), 
                      alpha = 0.4, linewidth = 0.5) +
    ggplot2::geom_line(ggplot2::aes(y = prob_lapse_smooth, color = "Smoothed (30pt)"), 
                      linewidth = 1.2) +
    ggplot2::geom_hline(yintercept = 0.3, linetype = "dashed", 
                       color = md_colors$muted, alpha = 0.6) +
    ggplot2::scale_color_manual(
      values = c("Raw" = md_colors$muted, "Smoothed (30pt)" = md_colors$warn),
      name = NULL
    ) +
    ggplot2::scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
    ggplot2::labs(
      title = "Prediction Stability Over Time",
      subtitle = "Raw vs. smoothed lapse probabilities with rolling uncertainty",
      x = NULL,
      y = "P(Lapse)"
    ) +
    ggplot2::theme_minimal() + theme_md() +
    ggplot2::theme(
      legend.position.inside = c(0.15, 0.88),
      legend.background = ggplot2::element_rect(fill = "white", color = md_colors$border)
    )
  
  # Bottom panel: Rolling SD
  p_bottom <- ggplot2::ggplot(data, ggplot2::aes(x = time_min)) +
    ggplot2::geom_line(ggplot2::aes(y = prob_lapse_sd), color = md_colors$accent, linewidth = 0.9) +
    ggplot2::labs(
      title = "Rolling Prediction Uncertainty",
      x = "Time (min)",
      y = "SD(P(Lapse))"
    ) +
    ggplot2::theme_minimal() + theme_md()
  
  # Combine if patchwork available
  if (requireNamespace("patchwork", quietly = TRUE)) {
    return(p_top / p_bottom + patchwork::plot_layout(heights = c(2, 1)))
  } else {
    return(list(top = p_top, bottom = p_bottom))
  }
}

