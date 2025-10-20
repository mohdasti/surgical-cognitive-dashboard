# nolint start
md_colors <- list(
  accent = "#1f9bb6", ok = "#27ae60", warn = "#f39c12", crit = "#e74c3c",
  ink = "#0b1526", muted = "#4b5563", border = "#e5e7eb", bg = "#f7f9fc", card = "#ffffff",
  state = c("Normal"="#0ea5b7","High Load"="#bc3c29","Attentional Lapse"="#6b7280")
)

theme_md <- function() {
  ggplot2::theme_minimal(base_family = NULL) +
    ggplot2::theme(
      text = ggplot2::element_text(colour = md_colors$ink),
      plot.title   = ggplot2::element_text(face="bold", size=14),
      plot.subtitle= ggplot2::element_text(colour = md_colors$muted, size=11),
      axis.title   = ggplot2::element_text(size=11),
      panel.grid.major = ggplot2::element_line(colour = "#e9edf3", linewidth = 0.4),
      panel.grid.minor = ggplot2::element_blank()
    )
}

scale_state_color <- function() ggplot2::scale_color_manual(values = md_colors$state)
scale_state_fill  <- function() ggplot2::scale_fill_manual(values  = md_colors$state)
# nolint end

