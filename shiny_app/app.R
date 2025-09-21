# Surgeon Cognitive Black Box - Shiny Application
# Real-time surgical cognitive state monitoring dashboard

# Load Libraries ----
library(shiny)
library(tidyverse)
library(xgboost)
library(zoo)
library(DT)

# Load Model and Data ----
# Load the trained XGBoost model
if (file.exists("xgb_model.rds")) {
  xgb_model <- readRDS("xgb_model.rds")
} else {
  stop("Model file 'xgb_model.rds' not found. Please run 03_train_model.R first.")
}

# Load the feature dataset
if (file.exists("../data/processed/features_data.csv")) {
  features_data <- read_csv("../data/processed/features_data.csv", show_col_types = FALSE)
} else {
  stop("Feature data file not found. Please run 02_feature_engineering.R first.")
}

# Define cognitive state mapping
cognitive_states <- c("Optimal", "High Load", "Fatigued", "Attentional Lapse")
state_colors <- c("#2E8B57", "#FF8C00", "#DC143C", "#8B0000")  # Green, Orange, Red, Dark Red
names(state_colors) <- cognitive_states

# UI Definition ----
ui <- fluidPage(
  # Application title
  titlePanel("Surgeon Cognitive Black Box - Real-Time Monitoring"),
  
  # Add custom CSS for styling
  tags$head(
    tags$style(HTML("
      .status-box {
        background-color: #f8f9fa;
        border: 2px solid #dee2e6;
        border-radius: 8px;
        padding: 15px;
        margin: 10px 0;
        font-size: 16px;
        font-weight: bold;
      }
      .status-optimal { border-color: #2E8B57; color: #2E8B57; }
      .status-highload { border-color: #FF8C00; color: #FF8C00; }
      .status-fatigued { border-color: #DC143C; color: #DC143C; }
      .status-lapse { border-color: #8B0000; color: #8B0000; }
      .why-panel {
        background-color: #e9ecef;
        border-radius: 8px;
        padding: 12px;
        margin: 10px 0;
        font-size: 14px;
      }
      .why-panel ul {
        margin: 5px 0;
        padding-left: 20px;
      }
      .why-panel li {
        margin: 3px 0;
      }
    "))
  ),
  
  # Main tab panel
  tabsetPanel(
    
    # First Tab: Live Surgical Dashboard ----
    tabPanel("Live Surgical Dashboard",
      sidebarLayout(
        
        # Sidebar Panel
        sidebarPanel(
          width = 4,
          
          # Control buttons
          div(
            actionButton("start_btn", "Start Monitoring", class = "btn-success"),
            br(), br(),
            actionButton("pause_btn", "Pause", class = "btn-warning"),
            br(), br(),
            actionButton("reset_btn", "Reset", class = "btn-danger")
          ),
          
          br(),
          
          # Speed controls
          h4("Simulation Speed"),
          div(
            selectInput("speed_multiplier", "Speed:",
                       choices = list("Real-time (1x)" = 1,
                                     "Fast (10x)" = 10,
                                     "Very Fast (50x)" = 50,
                                     "Demo Mode (100x)" = 100),
                       selected = 50),
            helpText("Higher speeds are better for demos and testing")
          ),
          
          br(),
          
          # Current status display
          h4("Current Status"),
          div(class = "status-box", uiOutput("status_box")),
          
          # Why panel - explanation of current state
          h4("Clinical Interpretation"),
          div(class = "why-panel", uiOutput("why_panel"))
        ),
        
        # Main Panel with plots
        mainPanel(
          width = 8,
          
          # Time display and cognitive state spectrum
          h3(textOutput("time_display"), style = "text-align: center;"),
          
          # Cognitive State Spectrum with Dial
          div(style = "text-align: center; margin: 20px;",
            h4("Cognitive State Spectrum", style = "margin-bottom: 10px;"),
            tags$div(
              style = "position: relative; height: 40px; margin: 10px 50px;",
              # Background spectrum
              tags$div(
                style = "background: linear-gradient(90deg, #2E8B57 0%, #2E8B57 25%, #FF8C00 25%, #FF8C00 50%, #DC143C 50%, #DC143C 75%, #8B0000 75%, #8B0000 100%); 
                         height: 20px; border-radius: 10px; position: relative; margin-bottom: 10px;",
                # State labels
                tags$div(style = "position: absolute; top: 25px; left: 12.5%; transform: translateX(-50%); font-size: 12px; font-weight: bold;", "Optimal"),
                tags$div(style = "position: absolute; top: 25px; left: 37.5%; transform: translateX(-50%); font-size: 12px; font-weight: bold;", "High Load"),
                tags$div(style = "position: absolute; top: 25px; left: 62.5%; transform: translateX(-50%); font-size: 12px; font-weight: bold;", "Fatigued"),
                tags$div(style = "position: absolute; top: 25px; left: 87.5%; transform: translateX(-50%); font-size: 12px; font-weight: bold;", "Alert"),
                # Moving dial indicator
                uiOutput("state_dial")
              )
            ),
            textOutput("state_info")
          ),
          
          # Surgery progress bar
          div(style = "text-align: center; margin-bottom: 20px;",
            h5("Surgery Progress"),
            tags$div(
              style = "background-color: #e6f3ff; border-radius: 8px; height: 20px; position: relative; margin: 5px 50px; border: 1px solid #b3d9ff; overflow: hidden;",
              uiOutput("time_progress_bar")
            ),
            textOutput("progress_text")
          ),
          
          # Live sensor plots
          fluidRow(
            column(6, 
              plotOutput("pupil_plot", height = "300px")
            ),
            column(6,
              plotOutput("grip_plot", height = "300px")
            )
          )
        )
      )
    ),
    
    # Second Tab: ML Model Diagnostics ----
    tabPanel("ML Model Diagnostics",
      fluidRow(
        column(6,
          h3("Model Predictions", style = "font-size: 20px; font-weight: bold;"),
          plotOutput("probability_plot", height = "400px")
        ),
        column(6,
          h3("Live Feature Values", style = "font-size: 20px; font-weight: bold;"),
          DT::dataTableOutput("features_table")
        )
      ),
      
      fluidRow(
        column(12,
          h3("Feature Importance", style = "font-size: 20px; font-weight: bold;"),
          div(style = "text-align: center; border: 1px solid #ddd; padding: 10px; border-radius: 5px; background-color: #f9f9f9;",
            imageOutput("importance_plot", height = "400px")
          )
        )
      )
    )
  )
)

# Server Logic ----
server <- function(input, output, session) {
  
  # Reactive Values ----
  current_time <- reactiveVal(1)
  is_running <- reactiveVal(FALSE)
  max_time <- nrow(features_data)
  surgery_duration_seconds <- 3 * 3600  # 3 hours = 10,800 seconds
  
  # Timer for live updates ----
  timer <- reactiveTimer(1000)  # Update every second
  
  # Control button events ----
  observeEvent(input$start_btn, {
    is_running(TRUE)
  })
  
  observeEvent(input$pause_btn, {
    is_running(FALSE)
  })
  
  observeEvent(input$reset_btn, {
    is_running(FALSE)
    current_time(1)
  })
  
  # Auto-advance time when running ----
  observeEvent(timer(), {
    if (is_running()) {
      # Get speed multiplier from input
      speed <- as.numeric(input$speed_multiplier)
      if (is.null(speed) || is.na(speed)) speed <- 1
      
      # Advance time by speed multiplier
      new_time <- current_time() + speed
      if (new_time <= surgery_duration_seconds && new_time <= max_time) {
        current_time(new_time)
      } else {
        # Loop back to beginning when reaching end
        current_time(1)
      }
    }
  })
  
  # Reactive data ----
  live_data <- reactive({
    req(current_time())
    features_data[current_time(), ]
  })
  
  # Get recent data for plots (last 30 seconds)
  recent_data <- reactive({
    req(current_time())
    start_time <- max(1, current_time() - 29)
    end_time <- current_time()
    features_data[start_time:end_time, ]
  })
  
  # Make prediction ----
  current_prediction <- reactive({
    req(live_data())
    
    # Prepare feature data for prediction
    feature_cols <- c("tonic_pupil_level_30s", "grip_force_variability_15s", 
                     "tremor_trend_10s", "phasic_pupil_change_5s", "pupil_diameter_lag_5s")
    
    features_matrix <- as.matrix(live_data()[feature_cols])
    
    # Make prediction with probabilities
    pred_probs <- predict(xgb_model, features_matrix)
    
    # Convert to matrix and get class with highest probability
    prob_matrix <- matrix(pred_probs, ncol = 4)
    colnames(prob_matrix) <- cognitive_states
    
    predicted_class <- cognitive_states[which.max(prob_matrix)]
    
    list(
      probabilities = prob_matrix[1, ],
      predicted_class = predicted_class,
      confidence = max(prob_matrix[1, ])
    )
  })
  
  # Render Outputs ----
  
  # Time display
  output$time_display <- renderText({
    req(current_time())
    paste("Surgery Time:", 
          sprintf("%02d:%02d:%02d", 
                 (current_time() %/% 3600),
                 ((current_time() %% 3600) %/% 60),
                 (current_time() %% 60)))
  })
  
  # Cognitive State Dial
  output$state_dial <- renderUI({
    req(live_data())
    
    # Use the actual cognitive state from the data, not the prediction
    current_state <- live_data()$cognitive_state
    
    # Map states to positions on the spectrum (0-100%)
    state_positions <- list(
      "Optimal" = 12.5,
      "High Load" = 37.5,
      "Fatigued" = 62.5,
      "Attentional Lapse" = 87.5
    )
    
    # Get position for current state
    dial_position <- state_positions[[current_state]]
    if (is.null(dial_position)) dial_position <- 12.5
    
    # Create the dial indicator
    tags$div(
      style = paste0("position: absolute; left: ", dial_position, "%; top: -5px; transform: translateX(-50%); 
                      width: 30px; height: 30px; background-color: white; border: 3px solid #333; 
                      border-radius: 50%; box-shadow: 0 2px 10px rgba(0,0,0,0.3); 
                      transition: left 0.5s ease-in-out; z-index: 10;"),
      tags$div(
        style = "position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); 
                 width: 16px; height: 16px; background-color: #333; border-radius: 50%;"
      )
    )
  })
  
  # State information text
  output$state_info <- renderText({
    req(live_data(), current_prediction())
    
    # Use actual state from data for dial consistency
    actual_state <- live_data()$cognitive_state
    
    # Get prediction confidence
    pred <- current_prediction()
    confidence <- round(pred$confidence * 100, 1)
    
    paste0("Current State: ", actual_state, " (Model Confidence: ", confidence, "%)")
  })
  
  # Video player style progress bar
  output$time_progress_bar <- renderUI({
    req(current_time())
    progress_percent <- (current_time() / surgery_duration_seconds) * 100
    
    # Create the filled portion (dark blue) that grows from left to right
    tags$div(
      style = paste0("width: ", progress_percent, "%; height: 100%; 
                      background: linear-gradient(90deg, #1e3a8a, #3b82f6, #60a5fa); 
                      border-radius: 6px 0 0 6px; 
                      transition: width 0.3s ease-in-out; 
                      position: absolute; 
                      left: 0; 
                      top: 0;
                      box-shadow: inset 0 1px 2px rgba(255,255,255,0.3);")
    )
  })
  
  # Progress text
  output$progress_text <- renderText({
    req(current_time(), input$speed_multiplier)
    progress_percent <- round((current_time() / surgery_duration_seconds) * 100, 1)
    
    # Calculate remaining time in simulation accounting for speed multiplier
    remaining_seconds_real <- surgery_duration_seconds - current_time()  # Remaining in real surgery time
    speed <- as.numeric(input$speed_multiplier)
    if (is.null(speed) || is.na(speed)) speed <- 1
    
    # Convert to actual time remaining in the simulation
    remaining_seconds_sim <- remaining_seconds_real / speed
    remaining_hours <- as.integer(remaining_seconds_sim %/% 3600)
    remaining_mins <- as.integer((remaining_seconds_sim %% 3600) %/% 60)
    remaining_secs <- as.integer(remaining_seconds_sim %% 60)
    
    paste0("Surgery Progress: ", progress_percent, "% • Remaining: ", 
           sprintf("%02d:%02d:%02d", remaining_hours, remaining_mins, remaining_secs))
  })
  
  # Status box
  output$status_box <- renderUI({
    req(current_prediction())
    
    pred <- current_prediction()
    state <- pred$predicted_class
    confidence <- round(pred$confidence * 100, 1)
    
    # Determine CSS class based on state
    css_class <- switch(state,
      "Optimal" = "status-optimal",
      "High Load" = "status-highload", 
      "Fatigued" = "status-fatigued",
      "Attentional Lapse" = "status-lapse"
    )
    
    div(class = css_class,
        paste0("COGNITIVE STATE: ", state),
        br(),
        paste0("Confidence: ", confidence, "%")
    )
  })
  
  # Why panel - DYNAMIC clinical interpretation
  output$why_panel <- renderUI({
    req(current_prediction(), live_data())
    
    pred <- current_prediction()
    state <- pred$predicted_class
    data <- live_data()
    
    # Base explanation
    base_explanation <- switch(state,
      "Optimal" = "Surgeon is in a state of low cognitive load with stable physiological and motor control.",
      "High Load" = "Elevated cognitive demand detected. This is primarily driven by:",
      "Fatigued" = "Signs of fatigue are present, indicated by a decline in fine motor control. Key drivers include:",
      "Attentional Lapse" = "ALERT: High probability of an attentional lapse. The model detected:"
    )
    
    # Dynamic details based on live data
    details <- ""
    if (state == "High Load") {
      details <- tags$ul(
        tags$li(paste0("Elevated Tonic Pupil Level (", round(data$tonic_pupil_level_30s, 2), " mm)")),
        if(data$phasic_pupil_change_5s > 0.1) {
          tags$li(paste0("Rapid Pupil Dilation Event (", round(data$phasic_pupil_change_5s, 3), " mm change)"))
        }
      )
    } else if (state == "Fatigued") {
      details <- tags$ul(
        tags$li(paste0("Increased Instrument Tremor (", round(data$tremor_trend_10s, 2), " Hz)")),
        tags$li(paste0("Elevated Grip Variability (", round(data$grip_force_variability_15s, 3), " N)")),
        if(data$tonic_pupil_level_30s < 3.2) {
          tags$li("Constricted pupil indicating reduced arousal")
        }
      )
    } else if (state == "Attentional Lapse") {
      details <- tags$ul(
        tags$li(strong(paste0("High Grip Force Variability (", round(data$grip_force_variability_15s, 3), " N)"))),
        tags$li(paste0("Constricted Pupil Diameter (", round(data$pupil_diameter_mm, 2), " mm)")),
        tags$li(strong(paste0("Elevated Tremor (", round(data$instrument_tremor_hz, 2), " Hz)")))
      )
    } else if (state == "Optimal") {
      details <- tags$ul(
        tags$li(paste0("Stable Pupil Diameter (", round(data$pupil_diameter_mm, 2), " mm)")),
        tags$li(paste0("Consistent Grip Force (", round(data$grip_force_newtons, 1), " N)")),
        tags$li(paste0("Low Tremor (", round(data$instrument_tremor_hz, 2), " Hz)"))
      )
    }
    
    # Combine base explanation and dynamic details
    tagList(
      p(base_explanation),
      details
    )
  })
  
  # Pupil diameter plot
  output$pupil_plot <- renderPlot({
    req(recent_data())
    
    data <- recent_data()
    current_state <- live_data()$cognitive_state
    
    ggplot(data, aes(x = timestamp, y = pupil_diameter_mm)) +
      geom_line(color = "blue", linewidth = 1.2) +
      geom_point(data = tail(data, 1), aes(x = timestamp, y = pupil_diameter_mm), 
                color = state_colors[current_state], size = 5) +
      labs(title = "Pupil Diameter", 
           y = "Diameter (mm)", 
           x = "Surgery Time") +
      scale_x_continuous(
        breaks = function(x) {
          x_range <- range(x, na.rm = TRUE)
          range_diff <- diff(x_range)
          
          if (range_diff <= 120) {
            # For 2 min or less, show every 30 seconds
            start <- ceiling(x_range[1]/30)*30
            end <- x_range[2]
            if (start <= end) {
              seq(from = start, to = end, by = 30)
            } else {
              x_range[1]
            }
          } else {
            # For longer ranges, show every 2 minutes
            start <- ceiling(x_range[1]/120)*120
            end <- x_range[2]
            if (start <= end) {
              seq(from = start, to = end, by = 120)
            } else {
              x_range[1]
            }
          }
        },
        labels = function(x) {
          hours <- as.integer(x %/% 3600)
          minutes <- as.integer((x %% 3600) %/% 60)
          seconds <- as.integer(x %% 60)
          
          if (any(x >= 3600)) {
            sprintf("%01d:%02d:%02d", hours, minutes, seconds)
          } else {
            sprintf("%02d:%02d", minutes, seconds)
          }
        }
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        axis.title = element_text(size = 14, face = "bold"),
        axis.text = element_text(size = 12),
        panel.grid.minor = element_blank()
      ) +
      ylim(c(2, 5))
  })
  
  # Grip force plot
  output$grip_plot <- renderPlot({
    req(recent_data())
    
    data <- recent_data()
    current_state <- live_data()$cognitive_state
    
    ggplot(data, aes(x = timestamp, y = grip_force_newtons)) +
      geom_line(color = "red", linewidth = 1.2) +
      geom_point(data = tail(data, 1), aes(x = timestamp, y = grip_force_newtons),
                color = state_colors[current_state], size = 5) +
      labs(title = "Grip Force", 
           y = "Force (N)", 
           x = "Surgery Time") +
      scale_x_continuous(
        breaks = function(x) {
          x_range <- range(x, na.rm = TRUE)
          range_diff <- diff(x_range)
          
          if (range_diff <= 120) {
            # For 2 min or less, show every 30 seconds
            start <- ceiling(x_range[1]/30)*30
            end <- x_range[2]
            if (start <= end) {
              seq(from = start, to = end, by = 30)
            } else {
              x_range[1]
            }
          } else {
            # For longer ranges, show every 2 minutes
            start <- ceiling(x_range[1]/120)*120
            end <- x_range[2]
            if (start <= end) {
              seq(from = start, to = end, by = 120)
            } else {
              x_range[1]
            }
          }
        },
        labels = function(x) {
          hours <- as.integer(x %/% 3600)
          minutes <- as.integer((x %% 3600) %/% 60)
          seconds <- as.integer(x %% 60)
          
          if (any(x >= 3600)) {
            sprintf("%01d:%02d:%02d", hours, minutes, seconds)
          } else {
            sprintf("%02d:%02d", minutes, seconds)
          }
        }
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        axis.title = element_text(size = 14, face = "bold"),
        axis.text = element_text(size = 12),
        panel.grid.minor = element_blank()
      ) +
      ylim(c(5, 25))
  })
  
  # Prediction probability plot
  output$probability_plot <- renderPlot({
    req(current_prediction())
    
    probs <- current_prediction()$probabilities
    
    prob_df <- data.frame(
      State = names(probs),
      Probability = as.numeric(probs)
    )
    
    ggplot(prob_df, aes(x = State, y = Probability, fill = State)) +
      geom_col() +
      scale_fill_manual(values = state_colors) +
      labs(title = "Model Prediction Probabilities",
           y = "Probability", x = "Cognitive State") +
      theme_minimal() +
      theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        axis.title = element_text(size = 14, face = "bold"),
        axis.text = element_text(size = 11),
        axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
        legend.position = "none",
        panel.grid.minor = element_blank()
      ) +
      ylim(c(0, 1)) +
      geom_hline(yintercept = 0.5, linetype = "dashed", alpha = 0.7)
  })
  
  # Features table
  output$features_table <- DT::renderDataTable({
    req(live_data())
    
    feature_cols <- c("tonic_pupil_level_30s", "grip_force_variability_15s", 
                     "tremor_trend_10s", "phasic_pupil_change_5s", "pupil_diameter_lag_5s")
    
    feature_data <- live_data()[feature_cols]
    
    # Create a clean display table
    display_data <- data.frame(
      Feature = c("Tonic Pupil (30s)", "Grip Variability (15s)", 
                 "Tremor Trend (10s)", "Phasic Pupil Change", "Pupil Lag (5s)"),
      Value = round(as.numeric(feature_data), 4)
    )
    
    display_data
  }, options = list(pageLength = 10, searching = FALSE, paging = FALSE, info = FALSE))
  
  # Feature importance image
  output$importance_plot <- renderImage({
    # Get the absolute path to the image
    image_path <- normalizePath(file.path("..", "case_study", "images", "feature_importance.png"))
    
    list(
      src = image_path,
      contentType = "image/png",
      width = "100%",
      height = "auto",
      style = "max-width: 100%; height: auto; object-fit: contain;",
      alt = "Feature Importance Plot"
    )
  }, deleteFile = FALSE)
}

# Run the application ----
shinyApp(ui = ui, server = server)