library(shiny)
library(plotly)
library(DT)

# Load the setup
source("../scripts/00_setup.R")

# Source experimental control modules
source("../R/utils_thresholds.R")
source("../R/mod_inverted_u_adjuster.R")
source("../R/mod_unified_sensitivity.R")
source("../R/mod_fatigue_adaptive.R")
source("../R/mod_controls_router.R")
source("../R/mod_experimental_controls_tab.R")
source("../R/threshold_adapter.R")
source("../R/ui_banner.R")

ui <- tagList(
  # Mode Banner (fixed at top)
  ui_mode_banner_ui("banner"),
  
  navbarPage(
    "🧠 Surgical Cognitive Dashboard",
    id = "main_navbar",
    
    # Add custom CSS for better styling
    tags$head(
      tags$style(HTML("
      /* Add padding to body to account for fixed banner */
      body { padding-top: 60px !important; }
      
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
  
  # ========================================================================
  # TAB 1: LIVE MONITOR
  # ========================================================================
  tabPanel("🏥 Live Monitor",
    div(style = "margin-bottom: 10px;",
      h4(style = "margin: 0; color: #2c3e50;", "Real-Time Surgical Cognitive Monitoring"),
      p(style = "margin: 5px 0 0 0; color: #7f8c8d; font-size: 0.9em;",
        "Real-time HUD at 5 Hz with alerts & reasons")
    ),
    hr(),
    fluidRow(
      column(3,
        wellPanel(
          h4("🎛️ Control Panel"),
          
          # Experimental controls toggle
          checkboxInput("use_experimental", "🧪 Use Training Lab Controls", FALSE),
          helpText(style = "font-size: 0.85em; color: #666;",
            "When enabled, thresholds come from the Training Lab tab"),
          
          conditionalPanel(
            condition = "!input.use_experimental",
            hr(),
            checkboxInput("silent", "🔇 Silent mode", FALSE),
            checkboxInput("enable_logging", "📝 Enable logging", TRUE),
            hr(),
            h5("⚙️ Alert Thresholds"),
            sliderInput("theta_lapse", "🚨 Lapse threshold", 0, 1, 0.3, 0.01),
            sliderInput("theta_high", "⚠️ High-load threshold", 0, 1, 0.6, 0.01)
          ),
          conditionalPanel(
            condition = "input.use_experimental",
            hr(),
            checkboxInput("silent", "🔇 Silent mode", FALSE),
            checkboxInput("enable_logging", "📝 Enable logging", TRUE),
            hr(),
            div(style = "background: #e8f5e9; padding: 10px; border-radius: 5px; border-left: 3px solid #4caf50;",
              p(style = "margin: 0; font-size: 0.9em;",
                icon("check-circle"), " Thresholds are controlled by the ",
                strong("Training Lab tab"))
            )
          ),
          hr(),
          h5("📊 Display Options"),
          checkboxInput("show_plots", "📈 Show real-time plots", TRUE),
          checkboxInput("show_features", "🔬 Show feature values", TRUE),
          actionButton("reset_session", "🔄 Reset Session", class = "btn-warning")
        )
      ),
      column(9,
        # Simulation Clock Row
        fluidRow(
          column(12,
            div(style = "background: linear-gradient(135deg, #34495e 0%, #2c3e50 100%); color: white; padding: 15px; border-radius: 10px; margin-bottom: 15px; text-align: center;",
              h3(style = "margin: 5px;", uiOutput("simulation_clock", inline = TRUE)),
              h5(style = "margin: 5px; opacity: 0.8;", "🔴 LIVE MONITORING | 10-Min Segment of a Simulated Robotic-Assisted Cholecystectomy (da Vinci Xi)")
            )
          )
        ),
        
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
  ),
  
  # ========================================================================
  # TAB 2: TRAINING LAB
  # ========================================================================
  tabPanel("🧪 Training Lab",
    div(style = "margin-bottom: 10px;",
      h4(style = "margin: 0; color: #2c3e50;", "Experimental Control Paradigms"),
      p(style = "margin: 5px 0 0 0; color: #7f8c8d; font-size: 0.9em;",
        "Explore alternative threshold control strategies grounded in cognitive theory")
    ),
    hr(),
    mod_experimental_controls_tab_ui("exp_controls")
  ),
  
  # ========================================================================
  # TAB 3: DIAGNOSTICS
  # ========================================================================
  navbarMenu("📊 Diagnostics",
    tabPanel("Overview",
      div(style = "margin-bottom: 10px;",
        h4(style = "margin: 0; color: #2c3e50;", "Model Overview & Performance"),
        p(style = "margin: 5px 0 0 0; color: #7f8c8d; font-size: 0.9em;",
          "Simulated ML performance metrics and calibration analysis")
      ),
      hr(),
    fluidRow(
      column(6,
        h4("🎯 Simulated Performance Metrics"),
        plotlyOutput("performance_metrics", height = "400px"),
        h4("📈 Simulated Precision-Recall"),
        plotlyOutput("pr_curves", height = "300px")
      ),
      column(6,
        h4("🎲 Calibration Analysis"),
        plotlyOutput("calibration_plot", height = "300px"),
        h4("📊 Confusion Matrix"),
        plotlyOutput("confusion_matrix", height = "300px")
      )
    )
    ),
    
    # Additional diagnostic tabs (placeholders for future expansion)
    tabPanel("Cross-Validation",
      div(style = "margin-bottom: 10px;",
        h4(style = "margin: 0; color: #2c3e50;", "Leave-One-Surgeon-Out (LOSO) Validation"),
        p(style = "margin: 5px 0 0 0; color: #7f8c8d; font-size: 0.9em;",
          "Model generalizability across different surgeons")
      ),
      hr(),
      wellPanel(
        h5("🚧 Coming Soon"),
        p("This tab will display LOSO cross-validation results including:"),
        tags$ul(
          tags$li("Per-surgeon holdout performance"),
          tags$li("Confusion matrices for each fold"),
          tags$li("PR-AUC curves across surgeons"),
          tags$li("Feature stability analysis")
        )
      )
    ),
    
    tabPanel("Calibration",
      div(style = "margin-bottom: 10px;",
        h4(style = "margin: 0; color: #2c3e50;", "Probability Calibration Analysis"),
        p(style = "margin: 5px 0 0 0; color: #7f8c8d; font-size: 0.9em;",
          "Reliability plots and calibration metrics")
      ),
      hr(),
      wellPanel(
        h5("🚧 Coming Soon"),
        p("This tab will display calibration diagnostics including:"),
        tags$ul(
          tags$li("Reliability diagrams (expected vs observed)"),
          tags$li("ECE, MCE, and Brier scores"),
          tags$li("Probability histograms by class"),
          tags$li("Platt scaling parameters")
        )
      )
    ),
    
    tabPanel("Threshold Sandbox",
      div(style = "margin-bottom: 10px;",
        h4(style = "margin: 0; color: #2c3e50;", "Interactive Threshold Tuning"),
        p(style = "margin: 5px 0 0 0; color: #7f8c8d; font-size: 0.9em;",
          "Explore precision-recall tradeoffs at different decision boundaries")
      ),
      hr(),
      wellPanel(
        h5("🚧 Coming Soon"),
        p("This tab will provide interactive threshold exploration:"),
        tags$ul(
          tags$li("Precision/Recall/F1 vs threshold curves"),
          tags$li("Confusion matrices at custom thresholds"),
          tags$li("ROC curves with operating point selection"),
          tags$li("Cost-sensitive decision analysis")
        )
      )
    ),
    
    tabPanel("Feature Importance",
      div(style = "margin-bottom: 10px;",
        h4(style = "margin: 0; color: #2c3e50;", "Feature Contribution Analysis"),
        p(style = "margin: 5px 0 0 0; color: #7f8c8d; font-size: 0.9em;",
          "XGBoost importance and SHAP-based explanations")
      ),
      hr(),
      wellPanel(
        h5("🚧 Coming Soon"),
        p("This tab will display feature importance analysis:"),
        tags$ul(
          tags$li("XGBoost gain/cover/frequency importance"),
          tags$li("SHAP summary plots"),
          tags$li("Per-class feature contributions"),
          tags$li("Feature interaction effects")
        )
      )
    ),
    
    tabPanel("Partial Dependence",
      div(style = "margin-bottom: 10px;",
        h4(style = "margin: 0; color: #2c3e50;", "Partial Dependence Plots"),
        p(style = "margin: 5px 0 0 0; color: #7f8c8d; font-size: 0.9em;",
          "Marginal effects of individual features on predictions")
      ),
      hr(),
      wellPanel(
        h5("🚧 Coming Soon"),
        p("This tab will provide partial dependence analysis:"),
        tags$ul(
          tags$li("PD plots for all engineered features"),
          tags$li("ICE (Individual Conditional Expectation) curves"),
          tags$li("2D interaction plots"),
          tags$li("Feature effect summaries")
        )
      )
    )
  ) # Close navbarMenu (Diagnostics)
  ) # Close navbarPage
) # Close tagList

server <- function(input, output, session) {
  # Simple simulation data
  idx <- reactiveVal(1L)
  
  # Reactive data storage
  logdf <- reactiveVal(tibble::tibble(
    t=integer(), type=character(), reasons=character(),
    lapse_p=double(), high_prob=double()
  ))
  
  # ========================================================================
  # THRESHOLD ADAPTER - SINGLE SOURCE OF TRUTH
  # ========================================================================
  
  # Mount experimental controls module
  experimental <- mod_experimental_controls_tab_server(
    "exp_controls",
    cfg = list(
      current_time = reactive({ 
        data <- realtime_data()
        if (nrow(data) > 0) tail(data$timestamp, 1) / 60 else 0
      }),
      # Custom bounds (optional)
      high_min = 0.40,
      high_max = 0.80,
      lapse_min = 0.70,
      lapse_max = 0.95
    ),
    existing_thresholds = reactive({
      list(
        high_load_threshold = input$theta_high,
        lapse_threshold = input$theta_lapse,
        source = "current"
      )
    })
  )
  
  # Create centralized threshold adapter (SINGLE SOURCE OF TRUTH)
  threshold_adapter <- create_threshold_adapter(input, experimental)
  
  # Convenience accessor for classifier
  get_thresholds <- threshold_adapter$get_thresholds
  
  # ========================================================================
  # END THRESHOLD ADAPTER
  # ========================================================================
  
  # ========================================================================
  # MODE BANNER INTEGRATION
  # ========================================================================
  
  # Track active tab
  active_tab <- reactive({
    # Infer from navbar selection
    tab_name <- input$main_navbar
    
    if (is.null(tab_name)) return("live")
    
    # Map tab names to simplified mode names
    if (grepl("Live Monitor", tab_name, ignore.case = TRUE)) {
      "live"
    } else if (grepl("Training Lab", tab_name, ignore.case = TRUE)) {
      "experimental"
    } else if (grepl("Diagnostics", tab_name, ignore.case = TRUE) || 
               grepl("Overview|Cross-Validation|Calibration|Threshold|Feature|Partial", tab_name, ignore.case = TRUE)) {
      "performance"
    } else {
      "live"  # Default
    }
  })
  
  # Mount banner server (uses threshold adapter as single source of truth)
  ui_mode_banner_server(
    "banner",
    active_tab = active_tab,
    threshold_source = threshold_adapter$get_thresholds
  )
  
  # ========================================================================
  # END MODE BANNER INTEGRATION
  # ========================================================================
  
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
  
  # Simulation completion flag (to prevent duplicate notifications)
  simulation_complete <- reactiveVal(FALSE)
  
  # Reset session
  observeEvent(input$reset_session, {
    idx(1L)
    simulation_complete(FALSE)  # Reset completion flag
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
  
  # Simulation Clock
  output$simulation_clock <- renderUI({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) {
      HTML("<span style='font-size: 28px; font-weight: bold;'>⏱️ 00:00 | Waiting for data...</span>")
    } else {
      elapsed_sec <- tail(current_data$timestamp, 1)
      elapsed_min <- floor(elapsed_sec / 60)
      elapsed_sec_remainder <- round(elapsed_sec %% 60)
      total_duration <- 10  # 10 minutes total
      progress_pct <- min(100, round((elapsed_sec / (total_duration * 60)) * 100))
      
      HTML(sprintf(
        "<span style='font-size: 32px; font-weight: bold;'>⏱️ %02d:%02d</span> <span style='font-size: 18px; opacity: 0.7;'>/ %d:00 (%d%% complete)</span>",
        elapsed_min, elapsed_sec_remainder, total_duration, progress_pct
      ))
    }
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
    
    thresh <- get_thresholds()
    card_class <- if (lapse_prob > thresh$lapse_threshold) "alert-card" else "metric-card"
    
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
    
    plot_ly(current_data, x = ~(timestamp/60), y = ~pupil_diameter, 
            type = 'scatter', mode = 'lines',
            line = list(color = '#3498db', width = 2)) %>%
      layout(title = "👁️ Pupil Diameter (photopic, TEPR)",
             xaxis = list(title = "Time (minutes)"),
             yaxis = list(title = "Diameter (mm)", range = c(2.5, 5.0)))
  })
  
  output$grip_plot <- renderPlotly({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) return(plotly_empty())
    
    plot_ly(current_data, x = ~(timestamp/60), y = ~grip_force,
            type = 'scatter', mode = 'lines',
            line = list(color = '#e74c3c', width = 2)) %>%
      layout(title = "✋ Grip Force (da Vinci robotic instruments)",
             xaxis = list(title = "Time (minutes)"),
             yaxis = list(title = "Force (N)", range = c(0, 10)))
  })
  
  output$tremor_plot <- renderPlotly({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) return(plotly_empty())
    
    plot_ly(current_data, x = ~(timestamp/60), y = ~tremor_amplitude,
            type = 'scatter', mode = 'lines',
            line = list(color = '#f39c12', width = 2)) %>%
      layout(title = "🤲 Tremor Amplitude (8-12 Hz, μm)",
             xaxis = list(title = "Time (minutes)"),
             yaxis = list(title = "Amplitude (μm)", range = c(0, 100)))
  })
  
  output$state_prob_plot <- renderPlotly({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) return(plotly_empty())
    
    # Apply smoothing (rolling average) to reduce noise
    window_size <- 10  # Smooth over ~2 seconds (10 points at 5 Hz)
    if (nrow(current_data) >= window_size) {
      current_data <- current_data %>%
        dplyr::mutate(
          state_probs_normal_smooth = zoo::rollmean(state_probs_normal, k = window_size, fill = NA, align = "right"),
          state_probs_highload_smooth = zoo::rollmean(state_probs_highload, k = window_size, fill = NA, align = "right"),
          state_probs_lapse_smooth = zoo::rollmean(state_probs_lapse, k = window_size, fill = NA, align = "right")
        ) %>%
        tidyr::drop_na()
    } else {
      current_data <- current_data %>%
        dplyr::mutate(
          state_probs_normal_smooth = state_probs_normal,
          state_probs_highload_smooth = state_probs_highload,
          state_probs_lapse_smooth = state_probs_lapse
        )
    }
    
    # Create TRUE stacked area chart where areas sum to 100%
    plot_ly(current_data, x = ~(timestamp/60)) %>%
      # Layer 1 (bottom): Normal - from 0 to normal_prob
      add_trace(y = ~state_probs_normal_smooth, 
                name = '✅ Normal',
                type = 'scatter',
                mode = 'none',
                fill = 'tozeroy',
                fillcolor = 'rgba(46, 204, 113, 0.8)',
                line = list(width = 0),
                hovertemplate = 'Normal: %{y:.1%}<extra></extra>') %>%
      # Layer 2 (middle): Normal + High Load (cumulative)
      add_trace(y = ~(state_probs_normal_smooth + state_probs_highload_smooth),
                name = '⚠️ High Load',
                type = 'scatter',
                mode = 'none',
                fill = 'tonexty',
                fillcolor = 'rgba(243, 156, 18, 0.8)',
                line = list(width = 0),
                hovertemplate = 'High Load: %{customdata:.1%}<extra></extra>',
                customdata = ~state_probs_highload_smooth) %>%
      # Layer 3 (top): Normal + High Load + Lapse = 100%
      add_trace(y = ~(state_probs_normal_smooth + state_probs_highload_smooth + state_probs_lapse_smooth),
                name = '🚨 Lapse',
                type = 'scatter',
                mode = 'none',
                fill = 'tonexty',
                fillcolor = 'rgba(231, 76, 60, 0.8)',
                line = list(width = 0),
                hovertemplate = 'Lapse: %{customdata:.1%}<extra></extra>',
                customdata = ~state_probs_lapse_smooth) %>%
      layout(title = "🧠 Cognitive State Distribution (Stacked Probabilities)",
             xaxis = list(title = "Time (minutes)"),
             yaxis = list(title = "Probability", range = c(0, 1), tickformat = ',.0%'),
             hovermode = 'x unified',
             showlegend = TRUE,
             legend = list(orientation = 'h', y = -0.35, x = 0.5, xanchor = 'center'),
             margin = list(b = 100, t = 50, l = 50, r = 50))
  })
  
  # Features Table
  output$features_table <- DT::renderDataTable({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) return(data.frame())
    
    latest <- tail(current_data, 1)
    t_current <- latest$timestamp
    fatigue_min <- t_current / 60
    
    features_df <- data.frame(
      Feature = c("Pupil Diameter (mm)", 
                  "Grip Force (N)", 
                  "Grip CV (%)",
                  "Tremor RMS (μm)", 
                  "Time-on-Task (min)",
                  "Normal Prob", 
                  "High Load Prob", 
                  "Lapse Prob"),
      Value = c(
        sprintf("%.2f", latest$pupil_diameter),
        sprintf("%.2f", latest$grip_force),
        sprintf("%.1f", (0.08 + (0.04 * min(1, fatigue_min / 30))) * 100),
        sprintf("%.1f", latest$tremor_amplitude),
        sprintf("%.1f", fatigue_min),
        sprintf("%.3f", latest$state_probs_normal),
        sprintf("%.3f", latest$state_probs_highload),
        sprintf("%.3f", latest$state_probs_lapse)
      ),
      Reference = c(
        "Wu 2019: 3.5±0.2mm baseline",
        "Araki 2021: 4.5N baseline",
        "Fresh: 8%, Fatigued: 12%",
        "Wells 2013: 60-120μm RMS",
        "Tremor +12%/hour",
        "Multimodal fusion",
        "De Louche 2024 (HRV)",
        "Wu 2019 (pupil)"
      )
    )
    
    DT::datatable(features_df, options = list(dom = 't', pageLength = 10), rownames = FALSE)
  })
  
  # Model Performance Plots (simulated)
  output$performance_metrics <- renderPlotly({
    # Simulated performance data
    surgeons <- paste0("Surgeon_", LETTERS[1:8])
    pr_auc <- c(0.85, 0.78, 0.92, 0.81, 0.88, 0.75, 0.89, 0.83)
    
    plot_ly(x = surgeons, y = pr_auc, type = 'bar',
            marker = list(color = '#3498db')) %>%
      layout(title = "LOSO Cross-Validation Performance",
             xaxis = list(title = "Holdout Surgeon"),
             yaxis = list(title = "PR-AUC"))
  })
  
  output$pr_curves <- renderPlotly({
    # Simulated PR curve
    recall <- seq(0, 1, 0.1)
    precision <- 0.8 + 0.2 * recall - 0.1 * recall^2
    
    plot_ly(x = recall, y = precision, type = 'scatter', mode = 'lines',
            line = list(color = '#e74c3c', width = 3)) %>%
      layout(title = "Precision-Recall Curve (Lapse Detection)",
             xaxis = list(title = "Recall"),
             yaxis = list(title = "Precision"))
  })
  
  output$calibration_plot <- renderPlotly({
    # Simulated calibration plot
    expected <- seq(0, 1, 0.1)
    observed <- expected + rnorm(length(expected), 0, 0.05)
    observed <- pmax(0, pmin(1, observed))
    
    plot_ly(x = expected, y = observed, type = 'scatter', mode = 'markers+lines',
            marker = list(size = 8, color = '#3498db'),
            line = list(color = '#3498db', width = 2)) %>%
      add_trace(x = c(0, 1), y = c(0, 1), type = 'scatter', mode = 'lines',
                line = list(color = 'red', dash = 'dash')) %>%
      layout(title = "Calibration Plot",
             xaxis = list(title = "Expected Probability"),
             yaxis = list(title = "Observed Probability"))
  })
  
  output$confusion_matrix <- renderPlotly({
    # Simulated confusion matrix
    categories <- c("Normal", "High Load", "Attentional Lapse")
    values <- c(45, 8, 2, 5, 12, 3, 1, 2, 8)
    
    plot_ly(z = matrix(values, nrow = 3, byrow = TRUE),
            x = categories, y = categories,
            type = 'heatmap',
            colorscale = 'Blues') %>%
      layout(title = "Confusion Matrix",
             xaxis = list(title = "Predicted"),
             yaxis = list(title = "Actual"))
  })
  
  # Alert Log
  output$alertlog <- DT::renderDataTable({
    alert_data <- logdf()
    if (nrow(alert_data) == 0) {
      # Return an empty dataframe with correct headers to show an empty table
      return(
        data.frame(
          Time = character(0),
          Alert = character(0),
          Details = character(0),
          `Lapse Prob.` = character(0),
          `High Load Prob.` = character(0),
          check.names = FALSE
        )
      )
    }
    
    alert_data %>%
      dplyr::mutate(
        Time = sprintf("%02d:%02d", floor(t / 60), round(t %% 60)),
        `Lapse Prob.` = sprintf("%.1f%%", lapse_p * 100),
        `High Load Prob.` = sprintf("%.1f%%", high_prob * 100)
      ) %>%
      dplyr::rename(
        Alert = type,
        Details = reasons
      ) %>%
      dplyr::select(Time, Alert, Details, `Lapse Prob.`, `High Load Prob.`)
      
  }, options = list(pageLength = 5, dom = 'tp', searching = FALSE), rownames = FALSE)
  
  # Main streaming loop - TRUE REAL-TIME SIMULATION
  observe({
    invalidateLater(200, session) # Update every 200ms = 5 Hz (real-time feel)
    i <- idx()
    if (i > 3000) {
      # Simulation complete - show notification only once
      if (!simulation_complete()) {
        showNotification(
          "✅ Simulation Complete! 10 minutes of surgical monitoring data collected.",
          type = "message",
          duration = 10
        )
        simulation_complete(TRUE)
      }
      return()
    }
    
    # ========================================================================
    # EVIDENCE-BASED BIOSIGNAL SIMULATION
    # ========================================================================
    # All parameters derived from peer-reviewed surgical monitoring literature:
    # - Pupil: Wu et al. 2019 (PMC7672675), TEPR literature
    # - Grip: Araki et al. 2021 (PMID 27572059), Olig et al. 2023
    # - Tremor: Wells 2013 (PMC3989364), Becker 2008 (PMC3032442)
    # - HRV: De Louche et al. 2024 (BJS Open), Böhm et al. 2001
    # ========================================================================
    t <- i * 0.2  # Time in seconds
    
    # ==== PUPIL DIAMETER (mm) - Evidence from Wu et al. 2019 ====
    # Baseline: 3.5 mm (SD 0.2), TEPR < 0.5mm, hippus at 0.2-0.3 Hz
    pupil_baseline <- 3.5 + rnorm(1, 0, 0.2)                   # Baseline 3.5mm ± 0.2
    pupil_hippus <- 0.12 * sin(2 * pi * 0.25 * t)             # Fatigue hippus: 0.25 Hz, 0.12mm amplitude
    pupil_tepr <- 0.30 * exp(-((t %% 60) - 15)^2 / (2 * 1.2^2))  # TEPR peaks every 60s: +0.3mm, rise τ=1.2s
    pupil_noise <- rnorm(1, 0, 0.05)                           # Measurement noise
    pupil_diameter <- pupil_baseline + pupil_hippus + pupil_tepr + pupil_noise
    pupil_diameter <- max(2.5, min(5.0, pupil_diameter))       # Physiological limits
    
    # ==== GRIP FORCE (Newtons) - Evidence from Araki et al. 2021 ====
    # Baseline: 4.5N, CV 6-8% fresh → 10-12% fatigued, 8-12 Hz tremor component
    fatigue_minutes <- t / 60
    cv_current <- 0.08 + (0.04 * min(1, fatigue_minutes / 30))  # CV increases with fatigue
    grip_mean <- 4.5 * (1 + 0.10 * sin(t/45))                    # Task-related baseline: 4.5N ± 10%
    grip_tremor_8_12hz <- grip_mean * 0.025 * sin(2 * pi * 10 * t)  # 8-12 Hz component at 2.5% RMS
    grip_variability <- rnorm(1, 0, grip_mean * cv_current)      # Natural variability (CV-based)
    grip_force <- grip_mean + grip_tremor_8_12hz + grip_variability
    grip_force <- max(1, min(10, grip_force))                    # Physical limits
    
    # ==== TREMOR AMPLITUDE (micrometers) - Evidence from Wells 2013, Becker 2008 ====
    # Baseline: 60-120 µm RMS at 8-12 Hz, increases ~7-12%/hour time-on-task
    time_on_task_factor <- 1 + (0.12 * fatigue_minutes / 60)    # +12%/hour increase
    tremor_rms_baseline <- 90                                    # 90 µm baseline RMS
    tremor_8_12hz <- tremor_rms_baseline * sin(2 * pi * 10 * t) # 10 Hz component
    tremor_load_modulation <- 30 * sin(t/12)                     # Stress-related modulation
    tremor_noise <- rnorm(1, 0, 15)                              # Measurement noise
    tremor_amplitude <- (tremor_8_12hz + tremor_load_modulation + tremor_noise) * time_on_task_factor
    tremor_amplitude <- abs(tremor_amplitude)                    # Amplitude is always positive
    
    # ==== COGNITIVE STATE PROBABILITIES - Evidence-based relationships ====
    # Based on De Louche et al. 2024 (HRV), Wu et al. 2019 (pupil), and tremor literature
    
    # High cognitive load indicators (from literature):
    # - Pupil dilation: baseline + 0.2-0.4mm (Wu et al. 2019)
    # - Increased grip force mean: +10% (stress/co-contraction)
    # - Increased tremor: +7-12%/hour, higher RMS (Wells 2013)
    pupil_dilation <- max(0, (pupil_diameter - 3.5) / 0.4)      # Normalized: 0 at baseline, 1 at +0.4mm
    grip_elevation <- max(0, (grip_force - 4.5) / 1.0)          # Normalized: 0 at baseline, 1 at +1N
    tremor_elevation <- max(0, (tremor_amplitude - 90) / 60)    # Normalized: 0 at baseline, 1 at 150µm
    
    highload_prob <- max(0, min(1, 
      pupil_dilation * 0.5 +      # Pupil is primary indicator (Wu et al.)
      grip_elevation * 0.2 +       # Grip secondary (co-contraction)
      tremor_elevation * 0.3 +     # Tremor increases with load
      rnorm(1, 0, 0.06)            # Biological variability
    ))
    
    # Attentional lapse indicators (from literature):
    # - Pupil constriction OR hippus increase (fatigue)
    # - Reduced grip force steadiness (increased CV > 12%)
    # - Sustained high tremor (fatigue, not just load)
    pupil_constriction <- max(0, (3.5 - pupil_diameter) / 0.5)  # Constriction below baseline
    grip_unsteady <- max(0, (cv_current - 0.08) / 0.04)         # CV above baseline (8%)
    tremor_sustained_high <- max(0, (time_on_task_factor - 1) / 0.3)  # Fatigue-driven tremor
    
    lapse_prob <- max(0, min(1,
      pupil_constriction * 0.4 +        # Pupil constriction = inattention
      grip_unsteady * 0.3 +              # Loss of steadiness
      tremor_sustained_high * 0.3 +      # Sustained fatigue
      rnorm(1, 0, 0.06)                  # Biological variability
    ))
    
    normal_prob <- max(0, 1 - highload_prob - lapse_prob)
    
    # Normalize probabilities
    total_prob <- normal_prob + highload_prob + lapse_prob
    normal_prob <- normal_prob / total_prob
    highload_prob <- highload_prob / total_prob
    lapse_prob <- lapse_prob / total_prob
    
    # Determine final state
    thresh <- get_thresholds()
    final_state <- if (lapse_prob > thresh$lapse_threshold) {
      "Attentional Lapse"
    } else if (highload_prob > thresh$high_load_threshold) {
      "High Load"
    } else {
      "Normal"
    }
    
    # Update real-time data
    new_row <- tibble::tibble(
      timestamp = t,
      pupil_diameter = pupil_diameter,
      grip_force = grip_force,
      tremor_amplitude = tremor_amplitude,
      state_probs_normal = normal_prob,
      state_probs_highload = highload_prob,
      state_probs_lapse = lapse_prob,
      lapse_prob = lapse_prob,
      final_state = final_state
    )
    
    current_data <- realtime_data()
    updated_data <- dplyr::bind_rows(current_data, new_row)
    # Keep only last 1000 points for performance
    if (nrow(updated_data) > 1000) {
      updated_data <- tail(updated_data, 1000)
    }
    realtime_data(updated_data)
    
    # Add to alert log if not silent and there's an alert
    thresh <- get_thresholds()
    if (!isTRUE(input$silent) && (lapse_prob > thresh$lapse_threshold || highload_prob > thresh$high_load_threshold)) {
      alert_type <- ifelse(lapse_prob > thresh$lapse_threshold, "🚨 LAPSE", "⚠️ HIGH LOAD")
      
      details_text <- if (lapse_prob > thresh$lapse_threshold) {
        sprintf("Lapse probability (%.1f%%) exceeded threshold (%.1f%%)", 
                lapse_prob * 100, thresh$lapse_threshold * 100)
      } else {
        sprintf("High Load probability (%.1f%%) exceeded threshold (%.1f%%)", 
                highload_prob * 100, thresh$high_load_threshold * 100)
      }
      
      new_alert <- tibble::tibble(
        t = t,
        type = alert_type,
        reasons = details_text,
        lapse_p = lapse_prob,
        high_prob = highload_prob
      )
      
      current_log <- logdf()
      updated_log <- dplyr::bind_rows(current_log, new_alert)
      logdf(updated_log)
    }
    
    idx(i + 1L)
  })
}

shinyApp(ui, server)
