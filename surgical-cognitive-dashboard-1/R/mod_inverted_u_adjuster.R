#' Inverted-U Zone Adjuster Module
#'
#' @description
#' Interactive control panel that visualizes the inverted-U relationship between
#' arousal and performance. Users drag vertical handles to define zone boundaries,
#' which automatically map to interdependent thresholds.
#'
#' @details
#' The module enforces:
#' - 0.05 ≤ b_left < b_right ≤ 0.95
#' - Minimum gap of 0.10 between boundaries
#' - Monotonic mapping to thresholds (documented in utils_thresholds.R)

#' UI for Inverted-U Zone Adjuster
#'
#' @param id Module namespace ID
#' @return Shiny UI element
#' @export
mod_inverted_u_adjuster_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    h4("🎯 Inverted-U Zone Adjuster"),
    p(style = "color: #666; font-size: 0.9em;",
      "Drag the vertical handles to define cognitive state zones. ",
      "The system automatically adjusts thresholds to maintain theoretical consistency."
    ),
    
    fluidRow(
      column(8,
        plotly::plotlyOutput(ns("curve_plot"), height = "400px")
      ),
      column(4,
        wellPanel(
          h5("📊 Current Configuration"),
          tags$table(style = "width: 100%;",
            tags$tr(
              tags$td(strong("Left Boundary:")),
              tags$td(textOutput(ns("b_left_display")), style = "text-align: right;")
            ),
            tags$tr(
              tags$td(strong("Right Boundary:")),
              tags$td(textOutput(ns("b_right_display")), style = "text-align: right;")
            ),
            tags$hr(),
            tags$tr(
              tags$td(strong("High Load Threshold:")),
              tags$td(textOutput(ns("high_threshold_display")), style = "text-align: right; color: #f39c12;")
            ),
            tags$tr(
              tags$td(strong("Lapse Threshold:")),
              tags$td(textOutput(ns("lapse_threshold_display")), style = "text-align: right; color: #e74c3c;")
            )
          ),
          hr(),
          checkboxInput(ns("expert_mode"), "🔧 Expert Mode", value = FALSE),
          conditionalPanel(
            condition = sprintf("input['%s']", ns("expert_mode")),
            sliderInput(ns("b_left_slider"), "Left Boundary", 0.05, 0.95, 0.30, 0.01),
            sliderInput(ns("b_right_slider"), "Right Boundary", 0.05, 0.95, 0.70, 0.01),
            helpText("Note: Constraints are still enforced in expert mode.")
          )
        )
      )
    )
  )
}

#' Server for Inverted-U Zone Adjuster
#'
#' @param id Module namespace ID
#' @param cfg Configuration list
#' @return List of reactives: zone_bounds(), thresholds()
#' @export
mod_inverted_u_adjuster_server <- function(id, cfg = list()) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Initialize boundary values
    b_left <- reactiveVal(0.30)
    b_right <- reactiveVal(0.70)
    
    # Enforce constraints on slider changes
    observeEvent(input$b_left_slider, {
      new_left <- input$b_left_slider
      current_right <- b_right()
      min_gap <- cfg$min_gap %||% 0.10
      
      # Ensure min gap
      if (new_left + min_gap > current_right) {
        new_left <- current_right - min_gap
      }
      new_left <- max(0.05, min(0.95, new_left))
      
      b_left(new_left)
    }, ignoreInit = TRUE)
    
    observeEvent(input$b_right_slider, {
      new_right <- input$b_right_slider
      current_left <- b_left()
      min_gap <- cfg$min_gap %||% 0.10
      
      # Ensure min gap
      if (new_right - min_gap < current_left) {
        new_right <- current_left + min_gap
      }
      new_right <- max(0.05, min(0.95, new_right))
      
      b_right(new_right)
    }, ignoreInit = TRUE)
    
    # Compute derived thresholds
    thresholds_reactive <- reactive({
      # Don't re-source, functions already loaded
      derive_thresholds_from_zone_bounds(b_left(), b_right(), cfg)
    })
    
    # Render inverted-U curve with zones
    output$curve_plot <- plotly::renderPlotly({
      # Generate inverted-U curve (normalized Gaussian)
      x <- seq(0, 1, length.out = 200)
      sigma <- 0.18
      y <- exp(-((x - 0.5)^2) / (2 * sigma^2))
      
      # Current boundaries
      left <- b_left()
      right <- b_right()
      
      # Create base plot
      p <- plotly::plot_ly() %>%
        # Add performance curve
        plotly::add_trace(
          x = x, y = y,
          type = 'scatter', mode = 'lines',
          line = list(color = '#2c3e50', width = 3),
          name = 'Performance',
          hovertemplate = 'Arousal: %{x:.2f}<br>Performance: %{y:.2f}<extra></extra>'
        ) %>%
        # Add vertical boundary lines
        plotly::add_segments(
          x = left, xend = left, y = 0, yend = 1,
          line = list(color = "#e74c3c", width = 3, dash = "dash"),
          name = "Left Boundary",
          hovertemplate = paste0("Left Boundary<br>Arousal: ", sprintf("%.2f", left), "<extra></extra>")
        ) %>%
        plotly::add_segments(
          x = right, xend = right, y = 0, yend = 1,
          line = list(color = "#f39c12", width = 3, dash = "dash"),
          name = "Right Boundary",
          hovertemplate = paste0("Right Boundary<br>Arousal: ", sprintf("%.2f", right), "<extra></extra>")
        ) %>%
        plotly::layout(
          title = "🧠 Arousal-Performance Relationship (Inverted-U)",
          xaxis = list(title = "Arousal Level", range = c(0, 1)),
          yaxis = list(title = "Performance", range = c(0, 1.1)),
          showlegend = FALSE,
          hovermode = 'x unified',
          # Add zone shading using shapes in layout
          shapes = list(
            # Left zone (Low/Lapse) - red
            list(
              type = "rect",
              x0 = 0, x1 = left, y0 = 0, y1 = 1,
              fillcolor = "rgba(231, 76, 60, 0.2)",
              line = list(width = 0),
              layer = "below"
            ),
            # Middle zone (Optimal) - green
            list(
              type = "rect",
              x0 = left, x1 = right, y0 = 0, y1 = 1,
              fillcolor = "rgba(46, 204, 113, 0.2)",
              line = list(width = 0),
              layer = "below"
            ),
            # Right zone (High/Overload) - red
            list(
              type = "rect",
              x0 = right, x1 = 1, y0 = 0, y1 = 1,
              fillcolor = "rgba(231, 76, 60, 0.2)",
              line = list(width = 0),
              layer = "below"
            )
          ),
          annotations = list(
            list(x = left/2, y = 0.95, text = "<b>Low/Lapse</b>", showarrow = FALSE, font = list(color = "#e74c3c", size = 12)),
            list(x = (left+right)/2, y = 0.95, text = "<b>Optimal</b>", showarrow = FALSE, font = list(color = "#27ae60", size = 14)),
            list(x = (right+1)/2, y = 0.95, text = "<b>High/Overload</b>", showarrow = FALSE, font = list(color = "#e74c3c", size = 12))
          )
        )
      
      p
    })
    
    # Display values
    output$b_left_display <- renderText({
      sprintf("%.2f", b_left())
    })
    
    output$b_right_display <- renderText({
      sprintf("%.2f", b_right())
    })
    
    output$high_threshold_display <- renderText({
      sprintf("%.2f", thresholds_reactive()$high_load_threshold)
    })
    
    output$lapse_threshold_display <- renderText({
      sprintf("%.2f", thresholds_reactive()$lapse_threshold)
    })
    
    # Return reactive interface
    list(
      zone_bounds = reactive({ c(b_left(), b_right()) }),
      thresholds = thresholds_reactive
    )
  })
}

