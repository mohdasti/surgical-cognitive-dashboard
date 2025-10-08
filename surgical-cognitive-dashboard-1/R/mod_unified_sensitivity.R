#' Unified Sensitivity Slider Module
#'
#' @description
#' Single-slider control that maps system sensitivity to interdependent thresholds.
#' Strict (1.0) = more alerts, Lenient (0.0) = fewer alerts.

#' UI for Unified Sensitivity Slider
#'
#' @param id Module namespace ID
#' @return Shiny UI element
#' @export
mod_unified_sensitivity_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    h4("🎚️ Unified Sensitivity Control"),
    p(style = "color: #666; font-size: 0.9em;",
      "A single slider that intelligently adjusts both thresholds. ",
      "Moving toward 'Strict' increases sensitivity (more alerts)."
    ),
    
    fluidRow(
      column(8,
        wellPanel(
          sliderInput(
            ns("sensitivity"),
            label = NULL,
            min = 0,
            max = 1,
            value = 0.5,
            step = 0.01,
            width = "100%"
          ),
          div(style = "display: flex; justify-content: space-between; margin-top: -15px;",
            span(style = "color: #3498db; font-weight: bold;", "← Lenient (Fewer Alerts)"),
            span(style = "color: #e74c3c; font-weight: bold;", "Strict (More Alerts) →")
          ),
          hr(),
          h5("📋 Quick Presets"),
          actionButton(ns("preset_lenient"), "Lenient (0.1)", class = "btn-sm"),
          actionButton(ns("preset_balanced"), "Balanced (0.5)", class = "btn-sm"),
          actionButton(ns("preset_strict"), "Strict (0.9)", class = "btn-sm")
        )
      ),
      column(4,
        wellPanel(
          h5("📊 Derived Thresholds"),
          tags$table(style = "width: 100%;",
            tags$tr(
              tags$td(strong("Sensitivity:")),
              tags$td(textOutput(ns("sensitivity_display")), style = "text-align: right;")
            ),
            tags$hr(),
            tags$tr(
              tags$td(strong("High Load:")),
              tags$td(textOutput(ns("high_threshold_display")), style = "text-align: right; color: #f39c12;")
            ),
            tags$tr(
              tags$td(strong("Lapse:")),
              tags$td(textOutput(ns("lapse_threshold_display")), style = "text-align: right; color: #e74c3c;")
            )
          ),
          hr(),
          plotOutput(ns("threshold_viz"), height = "200px")
        )
      )
    )
  )
}

#' Server for Unified Sensitivity Slider
#'
#' @param id Module namespace ID
#' @param cfg Configuration list
#' @return List of reactives: sensitivity(), thresholds()
#' @export
mod_unified_sensitivity_server <- function(id, cfg = list()) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Preset buttons
    observeEvent(input$preset_lenient, {
      updateSliderInput(session, "sensitivity", value = 0.1)
    })
    
    observeEvent(input$preset_balanced, {
      updateSliderInput(session, "sensitivity", value = 0.5)
    })
    
    observeEvent(input$preset_strict, {
      updateSliderInput(session, "sensitivity", value = 0.9)
    })
    
    # Compute derived thresholds
    thresholds_reactive <- reactive({
      # Don't re-source, functions already loaded
      derive_thresholds_from_sensitivity(input$sensitivity, cfg)
    })
    
    # Display values
    output$sensitivity_display <- renderText({
      sprintf("%.2f (%s)", 
              input$sensitivity,
              if (input$sensitivity < 0.3) "Lenient" 
              else if (input$sensitivity > 0.7) "Strict" 
              else "Balanced")
    })
    
    output$high_threshold_display <- renderText({
      sprintf("%.2f", thresholds_reactive()$high_load_threshold)
    })
    
    output$lapse_threshold_display <- renderText({
      sprintf("%.2f", thresholds_reactive()$lapse_threshold)
    })
    
    # Visualize threshold progression
    output$threshold_viz <- renderPlot({
      # Generate threshold curves across sensitivity range
      s_seq <- seq(0, 1, length.out = 100)
      # Functions already loaded, no need to source
      
      thresh_data <- lapply(s_seq, function(s) {
        t <- derive_thresholds_from_sensitivity(s, cfg)
        data.frame(
          sensitivity = s,
          high = t$high_load_threshold,
          lapse = t$lapse_threshold
        )
      })
      thresh_df <- do.call(rbind, thresh_data)
      
      # Current position
      current_s <- input$sensitivity
      current_thresh <- thresholds_reactive()
      
      par(mar = c(3, 3, 1, 1))
      plot(thresh_df$sensitivity, thresh_df$high, 
           type = "l", col = "#f39c12", lwd = 2,
           xlab = "", ylab = "Threshold",
           ylim = c(0.3, 1.0), las = 1)
      lines(thresh_df$sensitivity, thresh_df$lapse, col = "#e74c3c", lwd = 2)
      
      # Mark current position
      points(current_s, current_thresh$high_load_threshold, 
             pch = 19, col = "#f39c12", cex = 2)
      points(current_s, current_thresh$lapse_threshold, 
             pch = 19, col = "#e74c3c", cex = 2)
      
      # Add legend
      legend("topright", 
             legend = c("High Load", "Lapse"),
             col = c("#f39c12", "#e74c3c"),
             lwd = 2, bty = "n", cex = 0.8)
      
      title(xlab = "Sensitivity", line = 2)
    })
    
    # Return reactive interface
    list(
      sensitivity = reactive({ input$sensitivity }),
      thresholds = thresholds_reactive
    )
  })
}

