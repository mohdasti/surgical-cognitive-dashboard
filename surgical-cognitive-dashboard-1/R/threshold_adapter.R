#' Threshold Adapter - Single Source of Truth
#'
#' @description
#' Centralized threshold management that provides a unified interface
#' for the classifier regardless of which control paradigm is active.
#'
#' @details
#' This adapter ensures that:
#' 1. The classifier reads from exactly ONE place: get_thresholds()
#' 2. The UI banner always reflects the active source
#' 3. Switching between baseline and experimental is seamless
#' 4. All threshold state is consistent across the app

#' Create Threshold Adapter
#'
#' @param input Shiny input object
#' @param experimental_module The mounted experimental controls module
#' @return List of reactive functions:
#'   - get_thresholds(): Returns current thresholds (single source of truth)
#'   - threshold_source_label(): Returns formatted source info for UI display
#'   - is_experimental_active(): Boolean indicating if experimental mode is on
#' @export
create_threshold_adapter <- function(input, experimental_module) {
  
  # Wrap existing baseline thresholds
  existing_thresholds <- reactive({
    list(
      high_load_threshold = input$theta_high,
      lapse_threshold = input$theta_lapse,
      source = "current"
    )
  })
  
  # Main adapter: select between baseline and experimental
  get_thresholds <- reactive({
    if (isTRUE(input$use_experimental)) {
      # Use experimental thresholds
      experimental_module$thresholds()
    } else {
      # Use baseline sliders
      existing_thresholds()
    }
  })
  
  # Check if experimental mode is active
  is_experimental_active <- reactive({
    isTRUE(input$use_experimental)
  })
  
  # Format threshold source for display
  threshold_source_label <- reactive({
    thresh <- get_thresholds()
    
    if (is.null(thresh)) {
      return(list(
        icon = "❓",
        text = "Unknown",
        detail = "",
        color = "#95a5a6"
      ))
    }
    
    source_type <- thresh$source
    
    # Return formatted label based on source
    switch(
      source_type,
      
      "current" = list(
        icon = "⚙️",
        text = "Baseline Sliders",
        detail = sprintf("High: %.2f | Lapse: %.2f", 
                        thresh$high_load_threshold, 
                        thresh$lapse_threshold),
        color = "#95a5a6"
      ),
      
      "inverted_u" = list(
        icon = "📈",
        text = "Inverted-U Zones",
        detail = sprintf("Zones: [%.2f, %.2f] → High: %.2f | Lapse: %.2f",
                        thresh$zone_bounds[1],
                        thresh$zone_bounds[2],
                        thresh$high_load_threshold,
                        thresh$lapse_threshold),
        color = "#e67e22"
      ),
      
      "sensitivity" = list(
        icon = "🎚️",
        text = "Unified Sensitivity",
        detail = sprintf("s=%.2f → High: %.2f | Lapse: %.2f",
                        thresh$sensitivity,
                        thresh$high_load_threshold,
                        thresh$lapse_threshold),
        color = "#3498db"
      ),
      
      "fatigue" = list(
        icon = "⏱️",
        text = "Fatigue-Adaptive",
        detail = sprintf("t=%.1fmin (f=%.2f) → High: %.2f | Lapse: %.2f",
                        thresh$time_minutes,
                        thresh$fatigue_factor,
                        thresh$high_load_threshold,
                        thresh$lapse_threshold),
        color = "#e74c3c"
      ),
      
      "fatigue_disabled" = list(
        icon = "⏱️",
        text = "Fatigue (OFF)",
        detail = sprintf("Baseline: High: %.2f | Lapse: %.2f",
                        thresh$high_load_threshold,
                        thresh$lapse_threshold),
        color = "#95a5a6"
      ),
      
      # Default fallback
      list(
        icon = "❓",
        text = source_type,
        detail = sprintf("High: %.2f | Lapse: %.2f",
                        thresh$high_load_threshold,
                        thresh$lapse_threshold),
        color = "#95a5a6"
      )
    )
  })
  
  # Return adapter interface
  list(
    get_thresholds = get_thresholds,
    threshold_source_label = threshold_source_label,
    is_experimental_active = is_experimental_active,
    existing_thresholds = existing_thresholds
  )
}

#' Get Threshold Values for Classification
#'
#' @description
#' Helper function to extract just the threshold values from the adapter.
#' Use this in the classifier logic.
#'
#' @param adapter The threshold adapter object
#' @return Named list with high_load_threshold and lapse_threshold
#' @export
get_threshold_values <- function(adapter) {
  thresh <- adapter$get_thresholds()
  list(
    high_load = thresh$high_load_threshold,
    lapse = thresh$lapse_threshold
  )
}

#' Format Threshold Source for Banner Display
#'
#' @description
#' Helper to get formatted source info for the UI banner.
#'
#' @param adapter The threshold adapter object
#' @return List with icon, text, detail, color
#' @export
format_threshold_source <- function(adapter) {
  adapter$threshold_source_label()
}

