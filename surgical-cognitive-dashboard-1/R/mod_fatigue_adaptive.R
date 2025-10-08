#' Fatigue-Adaptive Thresholds Module
#'
#' @description
#' Time-based threshold adaptation that makes the system more sensitive as
#' time-on-task increases, reflecting cognitive fatigue accumulation.

#' UI for Fatigue-Adaptive Thresholds
#'
#' @param id Module namespace ID
#' @return Shiny UI element
#' @export
mod_fatigue_adaptive_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    h4("⏱️ Fatigue-Adaptive Thresholds"),
    p(style = "color: #666; font-size: 0.9em;",
      "Thresholds automatically decrease over time to account for cognitive fatigue. ",
      "The system becomes more sensitive as time-on-task increases."
    ),
    
    fluidRow(
      column(6,
        wellPanel(
          h5("⚙️ Configuration"),
          checkboxInput(ns("enabled"), "🔄 Enable Fatigue Adaptation", value = FALSE),
          conditionalPanel(
            condition = sprintf("input['%s']", ns("enabled")),
            hr(),
            h6("Baseline Thresholds (t=0)"),
            sliderInput(ns("baseline_high"), "High Load (baseline)", 
                       0.4, 0.8, 0.60, 0.01),
            sliderInput(ns("baseline_lapse"), "Lapse (baseline)", 
                       0.7, 0.95, 0.85, 0.01),
            hr(),
            h6("Fatigue Timeline"),
            numericInput(ns("t0"), "Start time (minutes)", value = 0, min = 0, max = 180),
            numericInput(ns("t1"), "Full effect time (minutes)", value = 30, min = 1, max = 180),
            selectInput(ns("f_shape"), "Profile shape",
                       choices = c("Linear" = "linear", "Logistic" = "logistic"),
                       selected = "linear"),
            hr(),
            h6("Decay Gains"),
            sliderInput(ns("k_high"), "High Load decay", 
                       0, 0.30, 0.15, 0.01),
            sliderInput(ns("k_lapse"), "Lapse decay", 
                       0, 0.25, 0.10, 0.01)
          )
        )
      ),
      column(6,
        wellPanel(
          h5("📊 Current State"),
          conditionalPanel(
            condition = sprintf("!input['%s']", ns("enabled")),
            p(style = "color: #999; font-style: italic;", 
              "Fatigue adaptation is currently disabled.")
          ),
          conditionalPanel(
            condition = sprintf("input['%s']", ns("enabled")),
            # Time control (for demo if no external time provided)
            sliderInput(ns("time_demo"), "Current Time (minutes)",
                       min = 0, max = 60, value = 0, step = 0.5,
                       animate = animationOptions(interval = 500, loop = TRUE)),
            hr(),
            tags$table(style = "width: 100%;",
              tags$tr(
                tags$td(strong("Time-on-Task:")),
                tags$td(textOutput(ns("time_display")), style = "text-align: right;")
              ),
              tags$tr(
                tags$td(strong("Fatigue Factor:")),
                tags$td(textOutput(ns("fatigue_display")), style = "text-align: right;")
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
            plotOutput(ns("timeline_plot"), height = "250px")
          )
        )
      )
    )
  )
}

#' Server for Fatigue-Adaptive Thresholds
#'
#' @param id Module namespace ID
#' @param cfg Configuration list. Should include current_time reactive if available.
#' @return List of reactives: profile(), thresholds()
#' @export
mod_fatigue_adaptive_server <- function(id, cfg = list()) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Use external time if provided, otherwise use demo slider
    current_time <- reactive({
      if (!is.null(cfg$current_time) && is.reactive(cfg$current_time)) {
        cfg$current_time()
      } else {
        input$time_demo
      }
    })
    
    # Build profile configuration
    profile_reactive <- reactive({
      if (!input$enabled) return(NULL)
      
      list(
        enabled = TRUE,
        t0 = input$t0,
        t1 = input$t1,
        f_shape = input$f_shape,
        k_high = input$k_high,
        k_lapse = input$k_lapse
      )
    })
    
    # Compute thresholds
    thresholds_reactive <- reactive({
      if (!input$enabled) {
        # Return baseline when disabled
        return(list(
          high_load_threshold = input$baseline_high,
          lapse_threshold = input$baseline_lapse,
          source = "fatigue_disabled"
        ))
      }
      
      source("R/utils_thresholds.R", local = TRUE)
      
      baseline <- list(
        high_load_threshold0 = input$baseline_high,
        lapse_threshold0 = input$baseline_lapse
      )
      
      profile <- profile_reactive()
      
      derive_fatigue_adjusted_thresholds(
        current_time(),
        baseline,
        profile,
        cfg
      )
    })
    
    # Display values
    output$time_display <- renderText({
      sprintf("%.1f min", current_time())
    })
    
    output$fatigue_display <- renderText({
      if (!input$enabled) return("N/A")
      t <- thresholds_reactive()
      sprintf("%.2f (%.0f%%)", t$fatigue_factor, t$fatigue_factor * 100)
    })
    
    output$high_threshold_display <- renderText({
      sprintf("%.2f", thresholds_reactive()$high_load_threshold)
    })
    
    output$lapse_threshold_display <- renderText({
      sprintf("%.2f", thresholds_reactive()$lapse_threshold)
    })
    
    # Plot timeline
    output$timeline_plot <- renderPlot({
      if (!input$enabled) return(NULL)
      
      source("R/utils_thresholds.R", local = TRUE)
      
      # Generate timeline
      t_seq <- seq(0, input$t1 + 10, length.out = 100)
      baseline <- list(
        high_load_threshold0 = input$baseline_high,
        lapse_threshold0 = input$baseline_lapse
      )
      profile <- profile_reactive()
      
      timeline_data <- lapply(t_seq, function(t) {
        thresh <- derive_fatigue_adjusted_thresholds(t, baseline, profile, cfg)
        data.frame(
          time = t,
          high = thresh$high_load_threshold,
          lapse = thresh$lapse_threshold,
          fatigue = thresh$fatigue_factor
        )
      })
      timeline_df <- do.call(rbind, timeline_data)
      
      # Current state
      current_t <- current_time()
      current_thresh <- thresholds_reactive()
      
      par(mar = c(3, 3, 2, 1))
      plot(timeline_df$time, timeline_df$high,
           type = "l", col = "#f39c12", lwd = 2,
           xlab = "", ylab = "Threshold",
           ylim = c(0.3, 1.0), las = 1,
           main = "Threshold Decay Over Time")
      lines(timeline_df$time, timeline_df$lapse, col = "#e74c3c", lwd = 2)
      
      # Mark current time
      if (input$enabled) {
        abline(v = current_t, col = "#3498db", lty = 2, lwd = 1.5)
        points(current_t, current_thresh$high_load_threshold,
               pch = 19, col = "#f39c12", cex = 2)
        points(current_t, current_thresh$lapse_threshold,
               pch = 19, col = "#e74c3c", cex = 2)
      }
      
      # Add legend
      legend("topright",
             legend = c("High Load", "Lapse", "Current Time"),
             col = c("#f39c12", "#e74c3c", "#3498db"),
             lwd = c(2, 2, 1.5),
             lty = c(1, 1, 2),
             bty = "n", cex = 0.8)
      
      title(xlab = "Time (minutes)", line = 2)
    })
    
    # Return reactive interface
    list(
      profile = profile_reactive,
      thresholds = thresholds_reactive
    )
  })
}

