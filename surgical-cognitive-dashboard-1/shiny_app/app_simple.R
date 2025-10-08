source("../scripts/00_setup.R")
source("../R/streaming_inference.R")
source("../R/diagnostics_module.R")
source("../scripts/utils_logging.R")

# Load models and data (adjust paths for shiny_app working directory)
models <- readRDS("../data/processed/xgb_loso_models.rds")
lapse_model <- readRDS("../data/processed/lapse_iso.rds")
calibration_data <- readRDS("../data/diagnostics/calibration.rds")
loso_eval <- readRDS("../data/diagnostics/loso_eval.rds")
model_artifacts <- readRDS("../data/diagnostics/model_artifacts.rds")
threshold_sandbox <- readRDS("../data/diagnostics/threshold_sandbox.rds")

ui <- shiny::navbarPage(
  "🧠 Surgical Cognitive Dashboard",
  tabPanel("🏥 Live Dashboard",
    fluidRow(
      column(3,
        wellPanel(
          h4("🎛️ Control Panel"),
          checkboxInput("silent", "🔇 Silent mode", FALSE),
          checkboxInput("enable_logging", "📝 Enable logging", TRUE),
          hr(),
          h5("⚙️ Alert Thresholds"),
          sliderInput("theta_lapse", "🚨 Lapse threshold", 0, 1, CFG$thresholds$alert_prob_lapse, 0.01),
          sliderInput("theta_high", "⚠️ High-load threshold", 0, 1, CFG$thresholds$alert_prob_highload, 0.01)
        )
      ),
      column(9,
        # Status Cards
        fluidRow(
          column(4, uiOutput("status_card")),
          column(4, uiOutput("lapse_prob_card")),
          column(4, uiOutput("performance_card"))
        ),
        
        # Real-time Plots
        fluidRow(
          column(6, plotlyOutput("pupil_plot", height = "300px")),
          column(6, plotlyOutput("grip_plot", height = "300px"))
        ),
        
        # Alert Log
        h4("📋 Alert Log"),
        DT::dataTableOutput("alertlog")
      )
    )
  ),
  
  tabPanel("🤖 ML Diagnostics",
    uiOutput("diagnostics")
  )
)

server <- function(input, output, session) {
  # Initialize engine with models
  engine <- CogEngine$new(CFG)
  engine$load_models(models, lapse_model)
  
  # Load streaming data
  stream <- data.table::fread("../data/processed/sim_stream.csv.gz")
  idx <- reactiveVal(1L)
  
  # Reactive data storage
  logdf <- reactiveVal(tibble::tibble(
    t=integer(), type=character(), reasons=character(),
    lapse_p=double(), high_prob=double()
  ))
  
  # Real-time data storage for plots
  realtime_data <- reactiveVal(tibble::tibble(
    timestamp = numeric(),
    pupil_diameter = numeric(),
    grip_force = numeric(),
    tremor_amplitude = numeric(),
    state_probs_normal = numeric(),
    state_probs_highload = numeric(),
    state_probs_lapse = numeric(),
    lapse_prob = numeric(),
    final_state = character()
  ))
  
  # Logging setup
  run_logger <- reactiveVal(NULL)
  
  # Update thresholds
  observe({
    CFG$thresholds$alert_prob_lapse <<- input$theta_lapse
    CFG$thresholds$alert_prob_highload <<- input$theta_high
  })
  
  # Status Card
  output$status_card <- renderUI({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) {
      status_class <- "status-normal"
      status_text <- "Initializing"
      status_icon <- "🔄"
    } else {
      latest_state <- tail(current_data$final_state, 1)
      status_class <- switch(latest_state,
        "Normal" = "status-normal",
        "High Load" = "status-highload", 
        "Attentional Lapse" = "status-lapse",
        "status-normal"
      )
      status_text <- latest_state
      status_icon <- switch(latest_state,
        "Normal" = "✅",
        "High Load" = "⚠️",
        "Attentional Lapse" = "🚨",
        "🔄"
      )
    }
    
    div(class = paste("metric-card", status_class),
        h3(paste(status_icon, "Current Status")),
        h2(status_text)
    )
  })
  
  # Lapse Probability Card
  output$lapse_prob_card <- renderUI({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) {
      lapse_prob <- 0
    } else {
      lapse_prob <- tail(current_data$lapse_prob, 1)
    }
    
    card_class <- if (lapse_prob > input$theta_lapse) "alert-card" else "metric-card"
    
    div(class = card_class,
        h3("🚨 Lapse Probability"),
        h2(sprintf("%.1f%%", lapse_prob * 100))
    )
  })
  
  # Performance Card
  output$performance_card <- renderUI({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) {
      perf_text <- "N/A"
    } else {
      recent_data <- tail(current_data, 100)
      avg_lapse_prob <- mean(recent_data$lapse_prob, na.rm = TRUE)
      perf_text <- sprintf("%.1f%%", (1 - avg_lapse_prob) * 100)
    }
    
    div(class = "metric-card",
        h3("📊 Performance"),
        h2(perf_text)
    )
  })
  
  # Real-time Plots
  output$pupil_plot <- renderPlotly({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) return(plotly_empty())
    
    plot_ly(current_data, x = ~timestamp, y = ~pupil_diameter, 
            type = 'scatter', mode = 'lines+markers',
            line = list(color = '#3498db', width = 2),
            marker = list(size = 4)) %>%
      layout(title = "👁️ Pupil Diameter (mm)",
             xaxis = list(title = "Time"),
             yaxis = list(title = "Diameter (mm)"))
  })
  
  output$grip_plot <- renderPlotly({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) return(plotly_empty())
    
    plot_ly(current_data, x = ~timestamp, y = ~grip_force,
            type = 'scatter', mode = 'lines+markers',
            line = list(color = '#e74c3c', width = 2),
            marker = list(size = 4)) %>%
      layout(title = "✋ Grip Force (N)",
             xaxis = list(title = "Time"),
             yaxis = list(title = "Force (N)"))
  })
  
  # Diagnostics Module
  output$diagnostics <- renderUI({ 
    diagnosticsUI("diag") 
  })
  diagnosticsServer("diag", calibration_data, loso_eval, model_artifacts, threshold_sandbox)
  
  # Alert Log
  output$alertlog <- DT::renderDataTable({
    logdf()
  }, options = list(pageLength = 10, dom = 't'))
  
  # Main streaming loop
  observe({
    invalidateLater(200, session) # 5 Hz update rate
    i <- idx()
    if (i > nrow(stream)) return()
    
    row <- as.list(stream[i,])
    engine$update(row)
    
    t0 <- proc.time()[["elapsed"]]
    out <- engine$predict()
    lat <- (proc.time()[["elapsed"]] - t0) * 1000
    
    if (!is.null(out)) {
      # Update real-time data
      new_row <- tibble::tibble(
        timestamp = row$t,
        pupil_diameter = row$pupil_diameter_mm,
        grip_force = row$grip_force_n,
        tremor_amplitude = row$tremor_amplitude_um,
        state_probs_normal = out$state_probs["Normal"],
        state_probs_highload = out$state_probs["High Load"],
        state_probs_lapse = out$state_probs["Attentional Lapse"],
        lapse_prob = out$lapse_p,
        final_state = out$final_state
      )
      
      current_data <- realtime_data()
      updated_data <- dplyr::bind_rows(current_data, new_row)
      # Keep only last 1000 points for performance
      if (nrow(updated_data) > 1000) {
        updated_data <- tail(updated_data, 1000)
      }
      realtime_data(updated_data)
      
      # Log event if logging is enabled
      if (isTRUE(input$enable_logging)) {
        if (is.null(run_logger())) {
          run_logger(start_run())
        }
        log_event(run_logger(), t = row$t, final_state = out$final_state,
                 lapse_p = out$lapse_p, high_prob = out$state_probs["High Load"],
                 reasons = out$reasons)
      }
      
      # Add to alert log if not silent and there's an alert
      if (!isTRUE(input$silent) && (out$alert$lapse || out$alert$highload)) {
        alert_type <- ifelse(out$alert$lapse, "🚨 LAPSE", 
                           ifelse(out$alert$highload, "⚠️ HIGH", "ℹ️ INFO"))
        
        new_alert <- tibble::tibble(
          t = row$t,
          type = alert_type,
          reasons = paste(out$reasons, collapse = "; "),
          lapse_p = out$lapse_p,
          high_prob = out$state_probs["High Load"]
        )
        
        current_log <- logdf()
        updated_log <- dplyr::bind_rows(current_log, new_alert)
        logdf(updated_log)
      }
    }
    
    idx(i + 1L)
  })
}

shinyApp(ui, server)

