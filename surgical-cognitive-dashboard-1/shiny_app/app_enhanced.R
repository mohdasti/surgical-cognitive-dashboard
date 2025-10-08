library(shiny)
library(plotly)
library(DT)

# Load the setup and modules
source("../scripts/00_setup.R")
source("../R/streaming_inference.R")
source("../R/diagnostics_module.R")
source("../scripts/utils_logging.R")

# Load models and data
models <- readRDS("../data/processed/xgb_loso_models.rds")
lapse_model <- readRDS("../data/processed/lapse_iso.rds")
calibration_data <- readRDS("../data/diagnostics/calibration.rds")
loso_eval <- readRDS("../data/diagnostics/loso_eval.rds")
model_artifacts <- readRDS("../data/diagnostics/model_artifacts.rds")
threshold_sandbox <- readRDS("../data/diagnostics/threshold_sandbox.rds")

ui <- fluidPage(
  titlePanel("🧠 Surgical Cognitive Dashboard - Enhanced"),
  
  # Add custom CSS for better styling
  tags$head(
    tags$style(HTML("
      .metric-card { 
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white; 
        padding: 15px; 
        border-radius: 10px; 
        margin: 5px;
        box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        text-align: center;
      }
      .alert-card { 
        background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
        color: white; 
        padding: 15px; 
        border-radius: 10px; 
        margin: 5px;
        animation: pulse 2s infinite;
        text-align: center;
      }
      @keyframes pulse {
        0% { transform: scale(1); }
        50% { transform: scale(1.05); }
        100% { transform: scale(1); }
      }
      .status-normal { background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%); }
      .status-highload { background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%); }
      .status-lapse { background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%); }
    "))
  ),
  
  sidebarLayout(
    sidebarPanel(
      h4("🎛️ Control Panel"),
      checkboxInput("silent", "🔇 Silent mode", FALSE),
      checkboxInput("enable_logging", "📝 Enable logging", TRUE),
      hr(),
      h5("⚙️ Alert Thresholds"),
      sliderInput("theta_lapse", "🚨 Lapse threshold", 0, 1, CFG$thresholds$alert_prob_lapse, 0.01),
      sliderInput("theta_high", "⚠️ High-load threshold", 0, 1, CFG$thresholds$alert_prob_highload, 0.01),
      hr(),
      h5("📊 Display Options"),
      checkboxInput("show_plots", "📈 Show real-time plots", TRUE),
      checkboxInput("show_features", "🔬 Show feature values", TRUE),
      actionButton("reset_session", "🔄 Reset Session", class = "btn-warning")
    ),
    
    mainPanel(
      # Status Cards Row
      fluidRow(
        column(4, uiOutput("status_card")),
        column(4, uiOutput("lapse_prob_card")),
        column(4, uiOutput("performance_card"))
      ),
      
      # Real-time Plots
      conditionalPanel(
        condition = "input.show_plots",
        h4("📈 Real-time Biosignal Monitoring"),
        fluidRow(
          column(6, plotlyOutput("pupil_plot", height = "300px")),
          column(6, plotlyOutput("grip_plot", height = "300px"))
        ),
        fluidRow(
          column(6, plotlyOutput("tremor_plot", height = "300px")),
          column(6, plotlyOutput("state_prob_plot", height = "300px"))
        )
      ),
      
      # Feature Values Table
      conditionalPanel(
        condition = "input.show_features",
        h4("🔬 Real-time Feature Values"),
        DT::dataTableOutput("features_table")
      ),
      
      # Alert Log
      h4("📋 Alert Log"),
      DT::dataTableOutput("alertlog")
    )
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
  
  # Reset session
  observeEvent(input$reset_session, {
    idx(1L)
    logdf(tibble::tibble(t=integer(), type=character(), reasons=character(),
                        lapse_p=double(), high_prob=double()))
    realtime_data(tibble::tibble(
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
  
  output$tremor_plot <- renderPlotly({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) return(plotly_empty())
    
    plot_ly(current_data, x = ~timestamp, y = ~tremor_amplitude,
            type = 'scatter', mode = 'lines+markers',
            line = list(color = '#f39c12', width = 2),
            marker = list(size = 4)) %>%
      layout(title = "🤲 Tremor Amplitude (μm)",
             xaxis = list(title = "Time"),
             yaxis = list(title = "Amplitude (μm)"))
  })
  
  output$state_prob_plot <- renderPlotly({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) return(plotly_empty())
    
    plot_ly(current_data, x = ~timestamp) %>%
      add_trace(y = ~state_probs_normal, name = 'Normal', type = 'scatter', mode = 'lines', line = list(color = '#2ecc71')) %>%
      add_trace(y = ~state_probs_highload, name = 'High Load', type = 'scatter', mode = 'lines', line = list(color = '#f39c12')) %>%
      add_trace(y = ~state_probs_lapse, name = 'Attentional Lapse', type = 'scatter', mode = 'lines', line = list(color = '#e74c3c')) %>%
      layout(title = "🧠 State Probabilities",
             xaxis = list(title = "Time"),
             yaxis = list(title = "Probability", range = c(0, 1)))
  })
  
  # Features Table
  output$features_table <- DT::renderDataTable({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) return(data.frame())
    
    latest <- tail(current_data, 1)
    features_df <- data.frame(
      Feature = c("Pupil Diameter", "Grip Force", "Tremor Amplitude", 
                  "Normal Prob", "High Load Prob", "Lapse Prob"),
      Value = c(
        sprintf("%.2f mm", latest$pupil_diameter),
        sprintf("%.2f N", latest$grip_force),
        sprintf("%.2f μm", latest$tremor_amplitude),
        sprintf("%.3f", latest$state_probs_normal),
        sprintf("%.3f", latest$state_probs_highload),
        sprintf("%.3f", latest$state_probs_lapse)
      )
    )
    
    DT::datatable(features_df, options = list(dom = 't', pageLength = 10))
  })
  
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

