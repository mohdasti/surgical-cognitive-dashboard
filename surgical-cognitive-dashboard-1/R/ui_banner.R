#' Mode Banner UI Component
#'
#' @description
#' Persistent top banner that displays current mode and active threshold source.
#' Makes it impossible to miss which control paradigm is driving the classifier.
#'
#' @details
#' The banner is sticky (position: fixed) and appears above all content with high z-index.
#' Left side shows the current operational mode (inferred from active tab).
#' Right side shows the active threshold source (baseline vs experimental).

#' Create Mode Banner UI
#'
#' @param id Namespace ID for the banner module
#' @return Shiny UI element (fixed banner)
#' @export
ui_mode_banner_ui <- function(id) {
  ns <- NS(id)
  
  div(
    id = ns("mode_banner"),
    style = "
      position: fixed;
      top: 0;
      left: 0;
      right: 0;
      z-index: 9999;
      background: linear-gradient(135deg, #2c3e50 0%, #34495e 100%);
      color: white;
      padding: 8px 20px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.2);
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-size: 0.9em;
      border-bottom: 2px solid #3498db;
    ",
    
    # Left side: Mode badge
    div(
      style = "display: flex; align-items: center; gap: 10px;",
      span(style = "opacity: 0.7; font-size: 0.85em;", "MODE:"),
      uiOutput(ns("mode_badge"), inline = TRUE)
    ),
    
    # Right side: Threshold source pill
    div(
      style = "display: flex; align-items: center; gap: 10px;",
      span(style = "opacity: 0.7; font-size: 0.85em;", "THRESHOLD SOURCE:"),
      uiOutput(ns("threshold_pill"), inline = TRUE)
    )
  )
}

#' Mode Banner Server Logic
#'
#' @param id Namespace ID
#' @param active_tab Reactive returning the currently active tab name
#' @param threshold_source Reactive returning the threshold source info
#'   (should be the same reactive that feeds get_thresholds())
#' @return NULL (side-effect only: renders banner)
#' @export
ui_mode_banner_server <- function(id, active_tab, threshold_source) {
  moduleServer(id, function(input, output, session) {
    
    # Render mode badge based on active tab
    output$mode_badge <- renderUI({
      tab <- active_tab()
      
      badge_config <- switch(
        tab,
        "live" = list(
          icon = "🏥",
          text = "Live Monitor",
          color = "#27ae60",
          bg = "rgba(39, 174, 96, 0.2)"
        ),
        "experimental" = list(
          icon = "🧪",
          text = "Training Lab",
          color = "#9b59b6",
          bg = "rgba(155, 89, 182, 0.2)"
        ),
        "performance" = list(
          icon = "📊",
          text = "Diagnostics",
          color = "#3498db",
          bg = "rgba(52, 152, 219, 0.2)"
        ),
        # Default
        list(
          icon = "🔄",
          text = "System",
          color = "#95a5a6",
          bg = "rgba(149, 165, 166, 0.2)"
        )
      )
      
      span(
        style = sprintf(
          "background: %s; color: %s; padding: 4px 12px; border-radius: 12px; font-weight: bold; border: 1px solid %s;",
          badge_config$bg, badge_config$color, badge_config$color
        ),
        badge_config$icon, " ", badge_config$text
      )
    })
    
    # Render threshold source pill
    output$threshold_pill <- renderUI({
      source_info <- threshold_source()
      
      if (is.null(source_info)) {
        # Fallback
        return(span(
          style = "background: rgba(149, 165, 166, 0.2); color: #95a5a6; padding: 4px 12px; border-radius: 12px; font-weight: bold; border: 1px solid #95a5a6;",
          "⚙️ Unknown"
        ))
      }
      
      source_type <- source_info$source
      
      pill_config <- switch(
        source_type,
        "current" = list(
          icon = "⚙️",
          text = "Baseline Sliders",
          color = "#95a5a6",
          bg = "rgba(149, 165, 166, 0.2)",
          detail = sprintf("High: %.2f | Lapse: %.2f", 
                          source_info$high_load_threshold, 
                          source_info$lapse_threshold)
        ),
        "inverted_u" = list(
          icon = "📈",
          text = "Inverted-U Zones",
          color = "#e67e22",
          bg = "rgba(230, 126, 34, 0.2)",
          detail = sprintf("Zones: [%.2f, %.2f] → High: %.2f | Lapse: %.2f",
                          source_info$zone_bounds[1],
                          source_info$zone_bounds[2],
                          source_info$high_load_threshold,
                          source_info$lapse_threshold)
        ),
        "sensitivity" = list(
          icon = "🎚️",
          text = "Unified Sensitivity",
          color = "#3498db",
          bg = "rgba(52, 152, 219, 0.2)",
          detail = sprintf("s=%.2f → High: %.2f | Lapse: %.2f",
                          source_info$sensitivity,
                          source_info$high_load_threshold,
                          source_info$lapse_threshold)
        ),
        "fatigue" = list(
          icon = "⏱️",
          text = "Fatigue-Adaptive",
          color = "#e74c3c",
          bg = "rgba(231, 76, 60, 0.2)",
          detail = sprintf("t=%.1fmin (f=%.2f) → High: %.2f | Lapse: %.2f",
                          source_info$time_minutes,
                          source_info$fatigue_factor,
                          source_info$high_load_threshold,
                          source_info$lapse_threshold)
        ),
        "fatigue_disabled" = list(
          icon = "⏱️",
          text = "Fatigue (Disabled)",
          color = "#95a5a6",
          bg = "rgba(149, 165, 166, 0.2)",
          detail = sprintf("Baseline: High: %.2f | Lapse: %.2f",
                          source_info$high_load_threshold,
                          source_info$lapse_threshold)
        ),
        # Default
        list(
          icon = "❓",
          text = "Unknown",
          color = "#95a5a6",
          bg = "rgba(149, 165, 166, 0.2)",
          detail = ""
        )
      )
      
      div(
        style = "display: flex; flex-direction: column; align-items: flex-end;",
        span(
          style = sprintf(
            "background: %s; color: %s; padding: 4px 12px; border-radius: 12px; font-weight: bold; border: 1px solid %s;",
            pill_config$bg, pill_config$color, pill_config$color
          ),
          pill_config$icon, " ", pill_config$text
        ),
        if (nchar(pill_config$detail) > 0) {
          span(
            style = "font-size: 0.75em; opacity: 0.7; margin-top: 2px;",
            pill_config$detail
          )
        }
      )
    })
    
    # Return nothing (side-effect only)
    invisible(NULL)
  })
}

#' Helper to infer active tab from input
#'
#' @param session Shiny session object
#' @param navbar_id ID of the navbarPage (if using navbarPage)
#' @return Reactive returning simplified tab name
#' @export
infer_active_tab <- function(session, navbar_id = NULL) {
  reactive({
    # Try to get active tab from URL or input
    query <- parseQueryString(session$clientData$url_search)
    
    # Fallback: use a simple heuristic based on common patterns
    # This can be enhanced by explicitly tracking tab clicks
    "live"  # Default to live mode
  })
}

