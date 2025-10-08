# Netlify function to serve the Shiny app
library(shiny)
library(yaml)

# Load configuration
CFG <- yaml::read_yaml("config/config.yml")

# Source the app components
source("R/streaming_inference.R")
source("R/diagnostics_module.R")

# Create the Shiny app
ui <- shiny::navbarPage(
  "Surgical Cognitive Dashboard",
  header = tags$head(tags$base(target="_parent")),
  tabPanel("Dashboard",
    fluidRow(
      column(3,
        checkboxInput("silent", "Silent mode (no alerts, just log)", FALSE),
        checkboxInput("enable_logging", "Enable event logging", FALSE),
        sliderInput("theta_lapse", "Lapse threshold", 0, 1, CFG$thresholds$alert_prob_lapse, 0.01),
        sliderInput("theta_high",  "High-load threshold", 0, 1, CFG$thresholds$alert_prob_highload, 0.01)
      ),
      column(9,
        uiOutput("hud"),
        DT::dataTableOutput("alertlog")
      )
    )
  ),
  tabPanel("ML Model Diagnostics", uiOutput("diagnostics"))
)

server <- function(input, output, session) {
  # Initialize the cognitive engine
  engine <- CogEngine$new()
  
  # Reactive values for the app state
  current_state <- reactiveVal("Initializing...")
  alert_log <- reactiveVal(data.frame(
    timestamp = character(0),
    event = character(0),
    probability = numeric(0),
    stringsAsFactors = FALSE
  ))
  
  # Load pre-trained models
  models <- readRDS("data/processed/xgb_loso_models.rds")
  lapse_model <- readRDS("data/processed/lapse_iso.rds")
  
  # Load diagnostics data
  calibration_data <- readRDS("data/diagnostics/calibration.rds")
  loso_eval <- readRDS("data/diagnostics/loso_eval.rds")
  model_artifacts <- readRDS("data/diagnostics/model_artifacts.rds")
  threshold_sandbox <- readRDS("data/diagnostics/threshold_sandbox.rds")
  
  # Simulate real-time data stream
  observe({
    invalidateLater(200) # Update every 200ms (5Hz)
    
    # Generate synthetic data point
    new_data <- data.frame(
      timestamp = Sys.time(),
      pupil_diameter_mm = rnorm(1, 4.5, 0.3),
      grip_force_n = rnorm(1, 12, 2),
      tremor_amplitude_um = rnorm(1, 15, 5),
      blink_rate_per_min = rpois(1, 20),
      tool_switches_per_min = rpois(1, 3),
      noise_level_db = rnorm(1, 45, 5),
      segment_id = sample(1:10, 1)
    )
    
    # Make prediction
    pred <- engine$predict(new_data, models, lapse_model)
    
    # Update current state
    current_state(pred$state)
    
    # Check for alerts
    if (!input$silent) {
      if (pred$prob_lapse > input$theta_lapse) {
        new_alert <- data.frame(
          timestamp = format(Sys.time(), "%H:%M:%S"),
          event = "⚠️ ATTENTIONAL LAPSE DETECTED",
          probability = round(pred$prob_lapse, 3),
          stringsAsFactors = FALSE
        )
        alert_log(rbind(alert_log(), new_alert))
      }
      
      if (pred$prob_highload > input$theta_high) {
        new_alert <- data.frame(
          timestamp = format(Sys.time(), "%H:%M:%S"),
          event = "🔴 HIGH COGNITIVE LOAD",
          probability = round(pred$prob_highload, 3),
          stringsAsFactors = FALSE
        )
        alert_log(rbind(alert_log(), new_alert))
      }
    }
  })
  
  # Render HUD
  output$hud <- renderUI({
    state <- current_state()
    color <- switch(state,
      "Attentional Lapse" = "danger",
      "High Load" = "warning", 
      "Normal" = "success",
      "Low Load" = "info"
    )
    
    div(
      h3("Real-time Cognitive State Monitor"),
      div(class = paste("alert alert-", color, sep = ""),
        h4(paste("Current State:", state)),
        p(paste("Last Update:", format(Sys.time(), "%H:%M:%S")))
      )
    )
  })
  
  # Render alert log
  output$alertlog <- DT::renderDataTable({
    DT::datatable(alert_log(), 
      options = list(pageLength = 10, dom = 't'),
      rownames = FALSE
    )
  })
  
  # Diagnostics module
  output$diagnostics <- renderUI({
    diagnostics_ui("diagnostics")
  })
  
  diagnostics_server("diagnostics", 
    calibration_data, loso_eval, model_artifacts, threshold_sandbox)
}

# Export the app for Netlify
shinyApp(ui, server)
