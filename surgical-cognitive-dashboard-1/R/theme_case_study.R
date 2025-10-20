# Case Study Theme for Consistent Plotting
# Provides consistent styling for gallery generation

#' Case Study Theme
#' 
#' A consistent ggplot2 theme for case study plots with standardized
#' colors, typography, and layout matching the Quarto document.
#' 
#' @return A ggplot2 theme object
#' @export
theme_case_study <- function() {
  ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      # Typography
      text = ggplot2::element_text(color = "#0b1526"),
      plot.title = ggplot2::element_text(
        face = "bold", 
        size = 14, 
        margin = ggplot2::margin(b = 8)
      ),
      plot.subtitle = ggplot2::element_text(
        color = "#4b5563", 
        size = 11,
        margin = ggplot2::margin(b = 12)
      ),
      axis.title = ggplot2::element_text(size = 11),
      axis.text = ggplot2::element_text(size = 10),
      
      # Grid and background
      panel.grid.major = ggplot2::element_line(
        color = "#e9edf3", 
        linewidth = 0.4
      ),
      panel.grid.minor = ggplot2::element_blank(),
      panel.background = ggplot2::element_rect(fill = "white", color = NA),
      plot.background = ggplot2::element_rect(fill = "white", color = NA),
      
      # Legend
      legend.position = "bottom",
      legend.title = ggplot2::element_text(size = 10),
      legend.text = ggplot2::element_text(size = 9),
      legend.margin = ggplot2::margin(t = 8),
      
      # Margins
      plot.margin = ggplot2::margin(12, 12, 12, 12)
    )
}

#' Case Study Color Palette
#' 
#' Standardized colors matching the Quarto case study document.
#' 
#' @return Named vector of hex colors
#' @export
case_study_colors <- c(
  accent = "#1f9bb6",
  ok = "#27ae60", 
  warn = "#f39c12",
  crit = "#e74c3c",
  neutral = "#6b7280",
  ink = "#0b1526",
  muted = "#4b5563",
  border = "#e5e7eb",
  bg = "#f7f9fc",
  card = "#ffffff"
)

#' Case Study State Colors
#' 
#' Colors for cognitive states matching the app's state definitions.
#' 
#' @return Named vector of state colors
#' @export
case_study_state_colors <- c(
  "Normal" = "#27ae60",
  "High Load" = "#f39c12", 
  "Attentional Lapse" = "#e74c3c"
)

#' Scale functions for case study colors
#' 
#' @return ggplot2 scale functions
#' @export
scale_case_study_color <- function() {
  ggplot2::scale_color_manual(values = case_study_state_colors)
}

#' @export
scale_case_study_fill <- function() {
  ggplot2::scale_fill_manual(values = case_study_state_colors)
}
