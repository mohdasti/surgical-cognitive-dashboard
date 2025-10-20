#' Live Monitor Plotting Functions
#'
#' @description
#' Reusable plotting functions for the Live Monitor tab.
#' These functions are used by both the Shiny app and the showcase script
#' to ensure visual consistency.

#' Plot TEPR and HRV Time Series (2-panel)
#'
#' @param data Data frame with time_min, pupil_mm, rmssd_ms, cognitive_state
#' @return Combined ggplot object (if patchwork available) or list of plots
#' @export
plot_tepr_hrv_demo <- function(data) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 required")
  }
  
  # Source theme if not already loaded
  if (!exists("md_colors")) {
    if (file.exists("R/theme_md.R")) {
      source("R/theme_md.R")
    } else if (file.exists("../R/theme_md.R")) {
      source("../R/theme_md.R")
    }
  }
  
  # Create state background ribbons
  state_changes <- data %>%
    dplyr::mutate(
      state_num = as.numeric(factor(cognitive_state, 
                                     levels = c("Normal", "High Load", "Attentional Lapse"))),
      change = state_num != dplyr::lag(state_num, default = 0)
    ) %>%
    dplyr::filter(change) %>%
    dplyr::mutate(
      xend = dplyr::lead(time_min, default = max(data$time_min)),
      ymin = -Inf,
      ymax = Inf,
      fill_color = dplyr::case_when(
        cognitive_state == "Normal" ~ md_colors$state["Normal"],
        cognitive_state == "High Load" ~ md_colors$state["High Load"],
        cognitive_state == "Attentional Lapse" ~ md_colors$state["Attentional Lapse"]
      )
    )
  
  # TEPR plot
  p1 <- ggplot2::ggplot(data, ggplot2::aes(x = time_min, y = pupil_mm)) +
    ggplot2::geom_rect(
      data = state_changes,
      ggplot2::aes(xmin = time_min, xmax = xend, ymin = 2.5, ymax = 6.5, fill = I(fill_color)),
      alpha = 0.15,
      inherit.aes = FALSE
    ) +
    ggplot2::geom_line(color = md_colors$state["Normal"], linewidth = 0.8) +
    ggplot2::geom_hline(yintercept = 4.0, linetype = 3, linewidth = 0.4, 
                       colour = md_colors$muted) +
    ggplot2::scale_y_continuous(limits = c(2.5, 6.5), breaks = seq(2.5, 6.5, 0.5)) +
    ggplot2::labs(
      title = "Task-Evoked Pupillary Response (TEPR)",
      subtitle = "Pupil diameter shows phasic dilations during high cognitive load",
      x = NULL,
      y = "Pupil Diameter (mm)"
    ) +
    ggplot2::theme_minimal() + theme_md()
  
  # HRV plot
  p2 <- ggplot2::ggplot(data, ggplot2::aes(x = time_min, y = rmssd_ms)) +
    ggplot2::geom_rect(
      data = state_changes,
      ggplot2::aes(xmin = time_min, xmax = xend, ymin = 20, ymax = 60, fill = I(fill_color)),
      alpha = 0.15,
      inherit.aes = FALSE
    ) +
    ggplot2::geom_line(color = md_colors$state["Normal"], linewidth = 0.8) +
    ggplot2::geom_hline(yintercept = median(data$rmssd_ms, na.rm = TRUE), 
                       linetype = 3, linewidth = 0.4, colour = md_colors$muted) +
    ggplot2::scale_y_continuous(limits = c(20, 60), breaks = seq(20, 60, 10)) +
    ggplot2::labs(
      title = "Heart Rate Variability (RMSSD)",
      subtitle = "HRV decreases during cognitive load",
      x = "Time (min)",
      y = "RMSSD (ms)"
    ) +
    ggplot2::theme_minimal() + theme_md()
  
  # Combine if patchwork available
  if (requireNamespace("patchwork", quietly = TRUE)) {
    return(p1 / p2)
  } else {
    return(list(tepr = p1, hrv = p2))
  }
}

#' Plot Feature Values by Cognitive State
#'
#' @param data Data frame with cognitive_state and feature columns
#' @return ggplot object
#' @export
plot_feat_by_state_demo <- function(data) {
  # Calculate summary statistics
  feature_summary <- data %>%
    dplyr::group_by(cognitive_state) %>%
    dplyr::summarise(
      pupil_mean = mean(pupil_mm, na.rm = TRUE),
      rmssd_mean = mean(rmssd_ms, na.rm = TRUE),
      grip_cv_mean = mean(grip_cv_pct, na.rm = TRUE),
      tremor_mean = mean(tremor_rms_um, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    tidyr::pivot_longer(
      cols = -cognitive_state,
      names_to = "feature",
      values_to = "value"
    ) %>%
    dplyr::mutate(
      feature_label = dplyr::case_when(
        feature == "pupil_mean" ~ "Pupil Diameter (mm)",
        feature == "rmssd_mean" ~ "RMSSD (ms)",
        feature == "grip_cv_mean" ~ "Grip CV (%)",
        feature == "tremor_mean" ~ "Tremor RMS (µm)"
      )
    )
  
  ggplot2::ggplot(feature_summary, ggplot2::aes(x = cognitive_state, y = value, fill = cognitive_state)) +
    ggplot2::geom_col(width = 0.7, alpha = 0.9) +
    ggplot2::facet_wrap(~ feature_label, scales = "free_y", ncol = 2) +
    scale_state_fill() +
    ggplot2::labs(
      title = "Feature Values by Cognitive State",
      subtitle = "Average biosignal characteristics across states",
      x = NULL,
      y = "Mean Value"
    ) +
    ggplot2::theme_minimal() + theme_md() +
    ggplot2::theme(
      strip.text = ggplot2::element_text(face = "bold", size = 11),
      legend.position = "bottom",
      legend.title = ggplot2::element_blank()
    )
}

