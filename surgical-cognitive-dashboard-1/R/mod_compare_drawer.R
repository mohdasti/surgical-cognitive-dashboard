#' Compare Drawer Module
#'
#' @description
#' Side-by-side comparison of baseline vs experimental thresholds.
#' Shows "what-if" analysis without affecting the actual classifier.
#'
#' @details
#' This module creates a sliding panel that displays:
#' - Left pane: Baseline threshold predictions
#' - Right pane: Experimental threshold predictions
#' - Diff bar: Alert deltas and precision/recall tradeoffs
#'
#' Both panes process the same data stream independently.

#' UI for Compare Drawer
#'
#' @param id Module namespace ID
#' @return Shiny UI element
#' @export
mod_compare_drawer_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Toggle button (fixed position in Live Monitor)
    div(
      id = ns("compare_toggle_btn"),
      style = "position: fixed; right: 20px; top: 80px; z-index: 1000;",
      actionButton(
        ns("toggle_drawer"),
        label = "🔬 Compare Thresholds",
        icon = icon("columns"),
        class = "btn-primary btn-lg",
        style = "box-shadow: 0 4px 8px rgba(0,0,0,0.3);"
      )
    ),
    
    # Sliding drawer panel
    div(
      id = ns("compare_drawer"),
      style = "
        position: fixed;
        top: 60px;
        right: -600px;
        width: 600px;
        height: calc(100vh - 60px);
        background: white;
        box-shadow: -4px 0 12px rgba(0,0,0,0.3);
        z-index: 999;
        transition: right 0.3s ease-in-out;
        overflow-y: auto;
        padding: 20px;
      ",
      
      # Header
      div(
        style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 15px; padding-bottom: 10px; border-bottom: 2px solid #3498db;",
        h3(style = "margin: 0;", "🔬 Threshold Comparison"),
        actionButton(ns("close_drawer"), "✕", class = "btn-sm btn-default")
      ),
      
      # Description
      p(style = "color: #666; font-size: 0.9em; margin-bottom: 15px;",
        "Compare how different threshold settings affect classification. ",
        "This is a 'what-if' analysis that doesn't change the actual classifier."
      ),
      
      # Diff Summary Bar
      wellPanel(
        style = "background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%); border-left: 4px solid #3498db;",
        h5("📊 Alert Delta Summary"),
        uiOutput(ns("diff_summary"))
      ),
      
      hr(),
      
      # Side-by-side comparison
      h4("⚖️ Side-by-Side State Classification"),
      
      fluidRow(
        # Left: Baseline
        column(6,
          div(
            style = "border: 2px solid #95a5a6; border-radius: 8px; padding: 10px; background: #f8f9fa;",
            h5(style = "margin-top: 0; color: #95a5a6;", "⚙️ Baseline"),
            uiOutput(ns("baseline_thresholds")),
            hr(style = "margin: 10px 0;"),
            h6("Current State:"),
            uiOutput(ns("baseline_state")),
            h6(style = "margin-top: 10px;", "Alert Count:"),
            textOutput(ns("baseline_alert_count"))
          )
        ),
        
        # Right: Experimental
        column(6,
          div(
            style = "border: 2px solid #9b59b6; border-radius: 8px; padding: 10px; background: #f3e5f5;",
            h5(style = "margin-top: 0; color: #9b59b6;", "🧪 Experimental"),
            uiOutput(ns("experimental_thresholds")),
            hr(style = "margin: 10px 0;"),
            h6("Current State:"),
            uiOutput(ns("experimental_state")),
            h6(style = "margin-top: 10px;", "Alert Count:"),
            textOutput(ns("experimental_alert_count"))
          )
        )
      ),
      
      hr(),
      
      # Mini timelines
      h4("📈 State Timeline Comparison"),
      p(style = "font-size: 0.85em; color: #666;",
        "Last 2 minutes of classification results"
      ),
      
      plotlyOutput(ns("timeline_comparison"), height = "300px"),
      
      hr(),
      
      # Precision/Recall Analysis
      h4("🎯 Precision/Recall Tradeoff"),
      p(style = "font-size: 0.85em; color: #666;",
        "How threshold changes affect detection performance"
      ),
      
      fluidRow(
        column(6,
          plotOutput(ns("pr_comparison"), height = "250px")
        ),
        column(6,
          wellPanel(
            h5("📊 Metrics Comparison"),
            uiOutput(ns("metrics_table"))
          )
        )
      )
    )
  )
}

#' Server for Compare Drawer
#'
#' @param id Module namespace ID
#' @param realtime_data Reactive returning current simulation data
#' @param threshold_adapter The centralized threshold adapter
#' @return NULL (side-effect only)
#' @export
mod_compare_drawer_server <- function(id, realtime_data, threshold_adapter) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Track drawer state
    drawer_open <- reactiveVal(FALSE)
    
    # Toggle drawer
    observeEvent(input$toggle_drawer, {
      drawer_open(!drawer_open())
      
      # Use JavaScript to slide drawer in/out
      if (drawer_open()) {
        shinyjs::runjs(sprintf("$('#%s').css('right', '0px');", ns("compare_drawer")))
        shinyjs::runjs(sprintf("$('#%s').css('right', '-100px');", ns("compare_toggle_btn")))
      } else {
        shinyjs::runjs(sprintf("$('#%s').css('right', '-600px');", ns("compare_drawer")))
        shinyjs::runjs(sprintf("$('#%s').css('right', '20px');", ns("compare_toggle_btn")))
      }
    })
    
    observeEvent(input$close_drawer, {
      drawer_open(FALSE)
      shinyjs::runjs(sprintf("$('#%s').css('right', '-600px');", ns("compare_drawer")))
      shinyjs::runjs(sprintf("$('#%s').css('right', '20px');", ns("compare_toggle_btn")))
    })
    
    # Get baseline thresholds (always from sliders)
    baseline_thresholds <- threshold_adapter$existing_thresholds
    
    # Get experimental thresholds (from active paradigm)
    experimental_thresholds <- reactive({
      threshold_adapter$get_thresholds()
    })
    
    # Classify with baseline thresholds
    baseline_classification <- reactive({
      data <- realtime_data()
      if (nrow(data) == 0) return(NULL)
      
      thresh <- baseline_thresholds()
      
      # Take last 2 minutes of data
      recent_data <- data %>%
        dplyr::filter(timestamp >= max(timestamp) - 120)
      
      if (nrow(recent_data) == 0) return(NULL)
      
      # Classify each point
      recent_data %>%
        dplyr::mutate(
          predicted_state = dplyr::case_when(
            lapse_prob > thresh$lapse_threshold ~ "Attentional Lapse",
            state_probs_highload > thresh$high_load_threshold ~ "High Load",
            TRUE ~ "Normal"
          ),
          is_alert = (lapse_prob > thresh$lapse_threshold | 
                     state_probs_highload > thresh$high_load_threshold)
        )
    })
    
    # Classify with experimental thresholds
    experimental_classification <- reactive({
      data <- realtime_data()
      if (nrow(data) == 0) return(NULL)
      
      thresh <- experimental_thresholds()
      
      # Take last 2 minutes of data
      recent_data <- data %>%
        dplyr::filter(timestamp >= max(timestamp) - 120)
      
      if (nrow(recent_data) == 0) return(NULL)
      
      # Classify each point
      recent_data %>%
        dplyr::mutate(
          predicted_state = dplyr::case_when(
            lapse_prob > thresh$lapse_threshold ~ "Attentional Lapse",
            state_probs_highload > thresh$high_load_threshold ~ "High Load",
            TRUE ~ "Normal"
          ),
          is_alert = (lapse_prob > thresh$lapse_threshold | 
                     state_probs_highload > thresh$high_load_threshold)
        )
    })
    
    # Display baseline thresholds
    output$baseline_thresholds <- renderUI({
      thresh <- baseline_thresholds()
      tags$small(
        sprintf("High: %.2f | Lapse: %.2f", 
                thresh$high_load_threshold, 
                thresh$lapse_threshold)
      )
    })
    
    # Display experimental thresholds
    output$experimental_thresholds <- renderUI({
      thresh <- experimental_thresholds()
      tags$small(
        sprintf("High: %.2f | Lapse: %.2f", 
                thresh$high_load_threshold, 
                thresh$lapse_threshold)
      )
    })
    
    # Display current states
    output$baseline_state <- renderUI({
      data <- baseline_classification()
      if (is.null(data) || nrow(data) == 0) return(tags$em("No data"))
      
      current_state <- tail(data$predicted_state, 1)
      color <- switch(current_state,
        "Normal" = "#27ae60",
        "High Load" = "#f39c12",
        "Attentional Lapse" = "#e74c3c",
        "#95a5a6"
      )
      
      tags$strong(style = sprintf("color: %s;", color), current_state)
    })
    
    output$experimental_state <- renderUI({
      data <- experimental_classification()
      if (is.null(data) || nrow(data) == 0) return(tags$em("No data"))
      
      current_state <- tail(data$predicted_state, 1)
      color <- switch(current_state,
        "Normal" = "#27ae60",
        "High Load" = "#f39c12",
        "Attentional Lapse" = "#e74c3c",
        "#95a5a6"
      )
      
      tags$strong(style = sprintf("color: %s;", color), current_state)
    })
    
    # Alert counts
    output$baseline_alert_count <- renderText({
      data <- baseline_classification()
      if (is.null(data)) return("0")
      sum(data$is_alert, na.rm = TRUE)
    })
    
    output$experimental_alert_count <- renderText({
      data <- experimental_classification()
      if (is.null(data)) return("0")
      sum(data$is_alert, na.rm = TRUE)
    })
    
    # Diff summary
    output$diff_summary <- renderUI({
      baseline_data <- baseline_classification()
      experimental_data <- experimental_classification()
      
      if (is.null(baseline_data) || is.null(experimental_data)) {
        return(p("Waiting for data..."))
      }
      
      baseline_alerts <- sum(baseline_data$is_alert, na.rm = TRUE)
      experimental_alerts <- sum(experimental_data$is_alert, na.rm = TRUE)
      delta <- experimental_alerts - baseline_alerts
      
      delta_color <- if (delta > 0) "#e74c3c" else if (delta < 0) "#27ae60" else "#95a5a6"
      delta_text <- if (delta > 0) {
        sprintf("+%d more alerts", delta)
      } else if (delta < 0) {
        sprintf("%d fewer alerts", abs(delta))
      } else {
        "Same alert count"
      }
      
      tagList(
        fluidRow(
          column(4,
            div(style = "text-align: center;",
              h4(style = "margin: 5px 0; color: #95a5a6;", baseline_alerts),
              p(style = "margin: 0; font-size: 0.85em;", "Baseline Alerts")
            )
          ),
          column(4,
            div(style = "text-align: center;",
              h4(style = sprintf("margin: 5px 0; color: %s;", delta_color), delta_text),
              p(style = "margin: 0; font-size: 0.85em;", "Delta")
            )
          ),
          column(4,
            div(style = "text-align: center;",
              h4(style = "margin: 5px 0; color: #9b59b6;", experimental_alerts),
              p(style = "margin: 0; font-size: 0.85em;", "Experimental Alerts")
            )
          )
        )
      )
    })
    
    # Timeline comparison
    output$timeline_comparison <- plotly::renderPlotly({
      baseline_data <- baseline_classification()
      experimental_data <- experimental_classification()
      
      if (is.null(baseline_data) || is.null(experimental_data)) {
        return(plotly::plotly_empty())
      }
      
      # Create comparison plot
      p <- plotly::plot_ly() %>%
        # Baseline timeline
        plotly::add_trace(
          data = baseline_data,
          x = ~(timestamp/60),
          y = ~ifelse(predicted_state == "Normal", 0, 
                     ifelse(predicted_state == "High Load", 1, 2)),
          type = 'scatter',
          mode = 'lines+markers',
          name = 'Baseline',
          line = list(color = '#95a5a6', width = 2),
          marker = list(size = 4, color = '#95a5a6')
        ) %>%
        # Experimental timeline
        plotly::add_trace(
          data = experimental_data,
          x = ~(timestamp/60),
          y = ~ifelse(predicted_state == "Normal", 0, 
                     ifelse(predicted_state == "High Load", 1, 2)),
          type = 'scatter',
          mode = 'lines+markers',
          name = 'Experimental',
          line = list(color = '#9b59b6', width = 2, dash = 'dot'),
          marker = list(size = 4, color = '#9b59b6')
        ) %>%
        plotly::layout(
          title = "State Classification Over Time",
          xaxis = list(title = "Time (minutes)"),
          yaxis = list(
            title = "Cognitive State",
            tickvals = c(0, 1, 2),
            ticktext = c("Normal", "High Load", "Lapse"),
            range = c(-0.5, 2.5)
          ),
          hovermode = 'x unified',
          legend = list(orientation = 'h', y = -0.2)
        )
      
      p
    })
    
    # Precision/Recall comparison
    output$pr_comparison <- renderPlot({
      baseline_data <- baseline_classification()
      experimental_data <- experimental_classification()
      
      if (is.null(baseline_data) || is.null(experimental_data)) {
        plot.new()
        text(0.5, 0.5, "Waiting for data...", cex = 1.2, col = "#999")
        return()
      }
      
      # Count state occurrences
      baseline_states <- table(baseline_data$predicted_state)
      experimental_states <- table(experimental_data$predicted_state)
      
      # Create comparison bar plot
      states <- c("Normal", "High Load", "Attentional Lapse")
      baseline_counts <- sapply(states, function(s) {
        if (s %in% names(baseline_states)) baseline_states[s] else 0
      })
      experimental_counts <- sapply(states, function(s) {
        if (s %in% names(experimental_states)) experimental_states[s] else 0
      })
      
      # Plot
      par(mar = c(4, 4, 2, 1))
      barplot_data <- rbind(baseline_counts, experimental_counts)
      colnames(barplot_data) <- c("Normal", "High Load", "Lapse")
      
      barplot(barplot_data,
              beside = TRUE,
              col = c("#95a5a6", "#9b59b6"),
              border = NA,
              las = 1,
              ylab = "Count",
              main = "State Distribution",
              legend.text = c("Baseline", "Experimental"),
              args.legend = list(x = "topright", bty = "n", cex = 0.8))
    })
    
    # Metrics table
    output$metrics_table <- renderUI({
      baseline_data <- baseline_classification()
      experimental_data <- experimental_classification()
      
      if (is.null(baseline_data) || is.null(experimental_data)) {
        return(p("Waiting for data..."))
      }
      
      # Calculate metrics
      baseline_lapse_rate <- mean(baseline_data$predicted_state == "Attentional Lapse", na.rm = TRUE)
      experimental_lapse_rate <- mean(experimental_data$predicted_state == "Attentional Lapse", na.rm = TRUE)
      
      baseline_highload_rate <- mean(baseline_data$predicted_state == "High Load", na.rm = TRUE)
      experimental_highload_rate <- mean(experimental_data$predicted_state == "High Load", na.rm = TRUE)
      
      tags$table(
        style = "width: 100%; font-size: 0.9em;",
        tags$tr(
          tags$th("Metric"),
          tags$th("Baseline", style = "text-align: right; color: #95a5a6;"),
          tags$th("Experimental", style = "text-align: right; color: #9b59b6;")
        ),
        tags$tr(
          tags$td("Lapse Rate"),
          tags$td(sprintf("%.1f%%", baseline_lapse_rate * 100), style = "text-align: right;"),
          tags$td(sprintf("%.1f%%", experimental_lapse_rate * 100), style = "text-align: right;")
        ),
        tags$tr(
          tags$td("High Load Rate"),
          tags$td(sprintf("%.1f%%", baseline_highload_rate * 100), style = "text-align: right;"),
          tags$td(sprintf("%.1f%%", experimental_highload_rate * 100), style = "text-align: right;")
        ),
        tags$tr(
          tags$td(strong("Normal Rate")),
          tags$td(strong(sprintf("%.1f%%", (1 - baseline_lapse_rate - baseline_highload_rate) * 100)), 
                 style = "text-align: right;"),
          tags$td(strong(sprintf("%.1f%%", (1 - experimental_lapse_rate - experimental_highload_rate) * 100)), 
                 style = "text-align: right;")
        )
      )
    })
    
    # Return nothing (side-effect only)
    invisible(NULL)
  })
}

