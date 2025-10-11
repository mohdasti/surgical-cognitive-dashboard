library(shiny)
library(bslib)
library(plotly)
library(DT)
library(shinyjs)
# library(cicerone)  # DISABLED - causes opacity overlay

# Load the setup
source("../scripts/00_setup.R")

# Source experimental control modules
source("../R/ui_constants.R")
source("../R/ui_theme.R")
source("../R/mod_error_sources.R")
source("../R/mod_scenario_presets.R")
source("../R/mod_diagnostics_progressive.R")
source("../R/utils_thresholds.R")
source("../R/mod_inverted_u_adjuster.R")
source("../R/mod_unified_sensitivity.R")
source("../R/mod_fatigue_adaptive.R")
source("../R/mod_controls_router.R")
source("../R/mod_experimental_controls_tab.R")
source("../R/threshold_adapter.R")
source("../R/ui_banner.R")
source("../R/mod_compare_drawer.R")
source("../R/mod_guided_tour.R")

ui <- tagList(
  # Initialize shinyjs
  shinyjs::useShinyjs(),
  
  # Initialize cicerone for guided tour (DISABLED - missing banner module elements)
  # cicerone::use_cicerone(),
  
  # Custom CSS for typography and spacing
  dashboard_css(),
  
  # Tour start button (fixed position) - DISABLED until banner module implemented
  # div(
  #   id = "tour_button",
  #   style = "position: fixed; right: 20px; bottom: 20px; z-index: 1000;",
  #   actionButton(
  #     "start_tour",
  #     label = "🎓 Start Tour",
  #     icon = icon("play-circle"),
  #     class = "btn-info btn-lg",
  #     style = "box-shadow: 0 4px 8px rgba(0,0,0,0.3); border-radius: 50px; padding: 12px 24px;"
  #   )
  # ),
  
  # Mode Banner (fixed at top) - DISABLED temporarily to fix opacity issue
  # ui_mode_banner_ui("banner"),
  
  # Compare Drawer (available in Live Monitor) - DISABLED temporarily
  # mod_compare_drawer_ui("compare"),
  
  navbarPage(
    "Surgical Cognitive Dashboard",
    id = "main_navbar",
    theme = create_dashboard_theme(),  # Apply theme to navbarPage
    
    # Add custom CSS for better styling
    tags$head(
      tags$style(HTML("
      /* Padding removed - no banner in this version */
      
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
      @keyframes live-pulse {
        0% { opacity: 1; box-shadow: 0 0 0 0 rgba(231, 76, 60, 0.7); }
        50% { opacity: 0.7; box-shadow: 0 0 0 5px rgba(231, 76, 60, 0); }
        100% { opacity: 1; box-shadow: 0 0 0 0 rgba(231, 76, 60, 0); }
      }
      .live-indicator {
        animation: live-pulse 2s infinite;
      }
      .status-normal { background: linear-gradient(135deg, #2ecc71 0%, #27ae60 100%); }
      .status-highload { background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%); }
      .status-lapse { background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%); }
      
      /* KILL OPACITY - Disable Shiny's recalculating fade */
      body, .container-fluid, * { opacity: 1 !important; }
      .recalculating { opacity: 1 !important; }
      .recalculating::after { display: none !important; }
      .shiny-busy { opacity: 1 !important; }
      
      /* Kill DataTables modal/alert overlays */
      .dataTables_processing { display: none !important; }
      div.dt-buttons { opacity: 1 !important; }
    ")),
    
    # JavaScript to clean up any modal overlays
    tags$script(HTML("
      // Remove any modal backdrops that get stuck
      $(document).on('shown.bs.modal hidden.bs.modal', function() {
        $('.modal-backdrop').remove();
        $('body').removeClass('modal-open');
        $('body').css('overflow', 'auto');
      });
      
      // Clean up DataTables alerts
      $(document).on('click', '.dataTables_wrapper', function() {
        $('.modal-backdrop').remove();
        $('body').removeClass('modal-open');  
      });
      
      // Force clean on page load
      $(document).ready(function() {
        setTimeout(function() {
          $('.modal-backdrop').remove();
          $('body').removeClass('modal-open');
          $('body').css({opacity: 1, filter: 'none'});
        }, 100);
      });
    "))
  ),
  
  # ========================================================================
  # TAB 1: LIVE MONITOR
  # ========================================================================
  tabPanel("🏥 Live Monitor",
    
    fluidRow(
      column(3,
        wellPanel(
          h4("⚙️ Control Panel"),
          
          checkboxInput("silent", "Silent mode", FALSE),
          helpText(style = "font-size: 0.85em; color: #666; margin-top: -10px;",
            "Suppress alert notifications"),
          
          hr(),
          h5("Alert Thresholds"),
          sliderInput("theta_lapse", "Lapse threshold", 0, 1, 0.3, 0.01),
          sliderInput("theta_high", "High-load threshold", 0, 1, 0.6, 0.01),
          
          hr(),
          h5("Display Options"),
          checkboxInput("show_features", "Show feature values", value = TRUE),
          helpText(style = "font-size: 0.85em; color: #666; margin-top: -10px;",
            "Toggle 57-feature biosignal table"),
          
          hr(),
          actionButton("reset_session", "Reset Session", class = "btn-warning")
        )
      ),
      column(9,
        # Simulation Clock Row
        fluidRow(
          column(12,
            div(style = "background: linear-gradient(135deg, #34495e 0%, #2c3e50 100%); color: white; padding: 15px; border-radius: 10px; margin-bottom: 15px; text-align: center;",
              h3(style = "margin: 5px; color: white; font-weight: 600;", 
                 textOutput("simulation_clock", inline = TRUE)),
              h5(style = "margin: 5px; color: rgba(255, 255, 255, 0.95); font-weight: 500;", 
                 tags$span(class = "live-indicator", style = "display: inline-block; width: 8px; height: 8px; background: #e74c3c; border-radius: 50%; margin-right: 8px;"),
                 "LIVE MONITORING | 10-Min Segment of a Simulated Robotic-Assisted Cholecystectomy (da Vinci Xi)")
            )
          )
        ),
        
        # Status Cards Row - STATIC UI (prevents 5Hz renderUI)
        fluidRow(
          column(4, 
            div(class = "metric-card status-normal",
                h3("Current Status"),
                h2(textOutput("status_text", inline = TRUE))
            )
          ),
          column(4,
            div(class = "metric-card",
                h3("🚨 Lapse Probability"),
                h2(textOutput("lapse_prob_text", inline = TRUE))
            )
          ),
          column(4,
            div(class = "metric-card",
                h3("📊 Performance"),
                h2(textOutput("performance_text", inline = TRUE))
            )
          )
        ),
        
        # Error Sources Panel (appears on alerts)
        mod_error_sources_ui("error_sources"),
        
        # Real-time Plots (always visible - core functionality)
        div(
          h4("Real-time Biosignal Monitoring",
             tags$sup(
               style = "margin-left: 8px;",
               tags$a(
                 href = "#",
                 onclick = "return false;",
                 `data-toggle` = "popover",
                 `data-trigger` = "hover",
                 `data-placement` = "top",
                 `data-html` = "true",
                 `data-title` = "What are Biosignals?",
                 `data-content` = "Physiological measurements that reflect cognitive state: <br><strong>Pupil:</strong> Reflects arousal via LC-NE system<br><strong>Grip:</strong> Motor control steadiness<br><strong>Tremor:</strong> Fine motor stability",
                 icon("question-circle", style = "color: #3498db; font-size: 0.7em;")
               )
             )
          ),
          fluidRow(
            column(6, plotlyOutput("pupil_plot", height = "300px")),
            column(6, plotlyOutput("grip_plot", height = "300px"))
          ),
          fluidRow(
            column(6, plotlyOutput("tremor_plot", height = "300px")),
            column(6, plotlyOutput("state_prob_plot", height = "350px"))
          )
        ),
        
        # Feature Values Table
        conditionalPanel(
          condition = "input.show_features",
          h4("Real-time Feature Values"),
          DT::dataTableOutput("features_table")
        ),
        
        # Alert Log
        h4("Alert Log"),
        DT::dataTableOutput("alertlog")
      )
    )
  ),
  
  # ========================================================================
  # TAB 2: TRAINING LAB (DISABLED - causes opacity)
  # ========================================================================
  # Training Lab has renderPlot outputs in modules that trigger opacity
  # when data loads. Needs deeper refactoring to work without renderUI/renderPlot.
  # For now, disabled to maintain clean app experience.
  #
  # tabPanel("🧪 Training Lab",
  #   tab_subtitle("Explore alternative threshold control strategies with scenario presets, theory-driven paradigms, and side-by-side comparison"),
  #   
  #   mod_experimental_controls_tab_ui("exp_controls")
  # ),
  
  # ========================================================================
  # TAB 3: DIAGNOSTICS
  # ========================================================================
  tabPanel("📊 Diagnostics",
    mod_diagnostics_progressive_ui("diagnostics")
  )
  ) # Close navbarPage
) # Close tagList

server <- function(input, output, session) {
  # ========================================================================
  # LOAD DIAGNOSTIC DATA (REAL MODEL DIAGNOSTICS)
  # ========================================================================
  
  # Load pre-computed diagnostic artifacts
  diagnostics <- tryCatch({
    # Check if files exist and use correct path
    base_path <- if (dir.exists("../data/diagnostics")) "../data/diagnostics" else "data/diagnostics"
    
    cat("Loading diagnostics from:", base_path, "\n")
    cat("  - calibration.rds exists:", file.exists(file.path(base_path, "calibration.rds")), "\n")
    cat("  - loso_eval.rds exists:", file.exists(file.path(base_path, "loso_eval.rds")), "\n")
    cat("  - model_artifacts.rds exists:", file.exists(file.path(base_path, "model_artifacts.rds")), "\n")
    cat("  - threshold_sandbox.rds exists:", file.exists(file.path(base_path, "threshold_sandbox.rds")), "\n")
    
    list(
      calibration = readRDS(file.path(base_path, "calibration.rds")),
      loso = readRDS(file.path(base_path, "loso_eval.rds")),
      artifacts = readRDS(file.path(base_path, "model_artifacts.rds")),
      threshold_sandbox = readRDS(file.path(base_path, "threshold_sandbox.rds"))
    )
  }, error = function(e) {
    cat("ERROR loading diagnostic data:", e$message, "\n")
    cat("Current working directory:", getwd(), "\n")
    # Return empty structure to prevent crashes
    list(
      calibration = list(calib_plot = NULL, prob_hist_plot = NULL, calib_stats_gt = NULL),
      loso = list(cm_plot = NULL, pr_lapse_plot = NULL, loso_df = data.frame()),
      artifacts = list(xgb_importance_plot = data.frame(), pd_plots = list()),
      threshold_sandbox = list(data = list(lapse_p = NULL, lab_bin = NULL))
    )
  })
  
  # Debug: Print diagnostic data status
  cat("Diagnostic data loaded:\n")
  cat("  - Calibration plots:", !is.null(diagnostics$calibration$calib_plot), "\n")
  cat("  - LOSO plots:", !is.null(diagnostics$loso$cm_plot), "\n")
  cat("  - Feature importance:", nrow(diagnostics$artifacts$xgb_importance_plot), "features\n")
  cat("  - PD plots:", length(diagnostics$artifacts$pd_plots), "plots\n")
  
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
  
  # Track alert status for error sources panel
  alert_active <- reactiveVal(FALSE)
  current_alert_state <- reactiveVal("Normal")
  
  # Mount error sources module
  error_sources <- mod_error_sources_server(
    "error_sources",
    current_state = current_alert_state,
    alert_active = alert_active
  )
  
  # Mount experimental controls module
  # DISABLED - Training Lab modules have renderPlot that cause opacity when data loads
  # experimental <- mod_experimental_controls_tab_server(
  #   "exp_controls",
  #   cfg = list(
  #     current_time = reactive({ 
  #       data <- realtime_data()
  #       if (nrow(data) > 0) tail(data$timestamp, 1) / 60 else 0
  #     }),
  #     # Custom bounds (optional)
  #     high_min = 0.40,
  #     high_max = 0.80,
  #     lapse_min = 0.70,
  #     lapse_max = 0.95
  #   ),
  #   existing_thresholds = reactive({
  #     list(
  #       high_load_threshold = input$theta_high,
  #       lapse_threshold = input$theta_lapse,
  #       source = "current"
  #     )
  #   })
  # )
  experimental <- NULL  # Placeholder
  
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
  
  # Mount banner server (uses threshold adapter as single source of truth) - DISABLED
  # ui_mode_banner_server(
  #   "banner",
  #   active_tab = active_tab,
  #   threshold_source = threshold_adapter$get_thresholds
  # )
  
  # ========================================================================
  # END MODE BANNER INTEGRATION
  # ========================================================================
  
  # ========================================================================
  # COMPARE DRAWER INTEGRATION
  # ========================================================================
  
  # Mount compare drawer (what-if analysis) - DISABLED
  # mod_compare_drawer_server(
  #   "compare",
  #   realtime_data = realtime_data,
  #   threshold_adapter = threshold_adapter
  # )
  
  # ========================================================================
  # END COMPARE DRAWER INTEGRATION
  # ========================================================================
  
  # ========================================================================
  # DIAGNOSTICS PROGRESSIVE DISCLOSURE
  # ========================================================================
  
  # Mount diagnostics module with content generators
  mod_diagnostics_progressive_server(
    "diagnostics",
    content_generators = list(
      threshold_sandbox = function() {
        div(
          h5("Interactive Threshold Tuning"),
          p("Explore precision-recall tradeoffs at different decision boundaries."),
          p(style = "color: #666; font-size: 0.9em;", 
            "Real LOSO cross-validation data showing how threshold choices affect performance metrics."),
          fluidRow(
            column(6,
              plotOutput("threshold_metrics_plot", height = "400px")
            ),
            column(6,
              plotOutput("threshold_f1_plot", height = "400px")
            )
          ),
          hr(),
          p(style = "font-size: 0.9em; color: #7f8c8d;",
            icon("info-circle"), " Current thresholds in Live Monitor: ",
            "High Load = 0.60, Lapse = 0.30 (adjustable in Control Panel)")
        )
      },
      
      calibration = function() {
        div(
          h5("Probability Calibration Analysis"),
          p("Reliability analysis of predicted probabilities from LOSO cross-validation."),
          fluidRow(
            column(6,
              h5("Calibration Plot"),
              plotOutput("calibration_plot_real", height = "350px")
            ),
            column(6,
              h5("Probability Distribution"),
              plotOutput("prob_hist_plot_real", height = "350px")
            )
          ),
          hr(),
          h5("Calibration Statistics"),
          tableOutput("calibration_stats")
        )
      },
      
      overview = function() {
        div(
          h5("Model Overview & Performance"),
          p("XGBoost multi-class classifier trained on leave-one-surgeon-out cross-validation."),
          fluidRow(
            column(6,
              h4("LOSO Confusion Matrix"),
              plotOutput("loso_confusion_matrix", height = "400px")
            ),
            column(6,
              h4("Precision-Recall (Lapse Detection)"),
              plotOutput("loso_pr_curve", height = "400px")
            )
          ),
          hr(),
          h5("Model Hyperparameters"),
          verbatimTextOutput("model_params")
        )
      },
      
      cross_validation = function() {
        div(
          h5("Leave-One-Surgeon-Out (LOSO) Validation"),
          p("Model generalizability: each surgeon held out once as test set, trained on all others."),
          h5("Cross-Validation Summary"),
          tableOutput("loso_summary_table"),
          hr(),
          p(style = "font-size: 0.9em; color: #7f8c8d;",
            icon("info-circle"), " LOSO ensures the model generalizes to unseen surgeons, ",
            "critical for real-world deployment where individual variability is high.")
        )
      },
      
      feature_importance = function() {
        div(
          h5("Feature Contribution Analysis"),
          p("XGBoost feature importance showing which biosignals most influence cognitive state predictions."),
          h5("Feature Importance (Gain)"),
          plotOutput("feature_importance_plot", height = "400px"),
          hr(),
          p(style = "font-size: 0.9em; color: #7f8c8d;",
            icon("lightbulb"), " Gain measures the average improvement in accuracy when using each feature. ",
            "Higher gain = more predictive power for cognitive state classification.")
        )
      },
      
      partial_dependence = function() {
        div(
          h5("Partial Dependence Plots"),
          p("Marginal effect of each feature on cognitive state predictions, holding other features constant."),
          fluidRow(
            column(4, plotOutput("pd_plot_1", height = "300px")),
            column(4, plotOutput("pd_plot_2", height = "300px")),
            column(4, plotOutput("pd_plot_3", height = "300px"))
          ),
          hr(),
          p(style = "font-size: 0.9em; color: #7f8c8d;",
            icon("chart-line"), " PD plots show how each biosignal feature affects lapse probability. ",
            "Steeper curves indicate stronger influence on cognitive state classification.")
        )
      }
    )
  )
  
  # ========================================================================
  # END DIAGNOSTICS PROGRESSIVE DISCLOSURE
  # ========================================================================
  
  # ========================================================================
  # GUIDED TOUR INTEGRATION
  # ========================================================================
  
  # Create guided tour - DISABLED until banner module elements exist
  # tour_guide <- create_guided_tour()
  
  # Start tour when button clicked
  # observeEvent(input$start_tour, {
  #   tour_guide$init()$start()
  # })
  
  # Initialize popovers for help icons
  init_popovers(session)
  
  # ========================================================================
  # END GUIDED TOUR INTEGRATION
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
  
  # Simulation Clock - TEXT ONLY (no renderUI)
  output$simulation_clock <- renderText({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) {
      "00:00 | Starting..."
    } else {
      elapsed_sec <- tail(current_data$timestamp, 1)
      elapsed_min <- floor(elapsed_sec / 60)
      elapsed_sec_remainder <- round(elapsed_sec %% 60)
      total_duration <- 10
      progress_pct <- min(100, round((elapsed_sec / (total_duration * 60)) * 100))
      
      sprintf("%02d:%02d / %d:00 (%d%%)", 
              elapsed_min, elapsed_sec_remainder, total_duration, progress_pct)
    }
  })
  
  # Status Card - TEXT ONLY (no renderUI)
  output$status_text <- renderText({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) return("Initializing...")
    tail(current_data$final_state, 1)
  })
  
  
  # Lapse Probability - TEXT ONLY
  output$lapse_prob_text <- renderText({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) return("0.0%")
      lapse_prob <- tail(current_data$lapse_prob, 1)
    sprintf("%.1f%%", lapse_prob * 100)
  })
  
  
  # Performance - TEXT ONLY  
  output$performance_text <- renderText({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) return("N/A")
      recent_data <- tail(current_data, 100)
      avg_lapse_prob <- mean(recent_data$lapse_prob, na.rm = TRUE)
    sprintf("%.1f%%", (1 - avg_lapse_prob) * 100)
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
                name = paste0(ICONS$optimal, " ", LABELS$normal),
                type = 'scatter',
                mode = 'none',
                fill = 'tozeroy',
                fillcolor = rgba(COLORS$optimal, 0.8),
                line = list(width = 0),
                hovertemplate = paste0(LABELS$normal, ': %{y:.1%}<extra></extra>')) %>%
      # Layer 2 (middle): Normal + High Load (cumulative)
      add_trace(y = ~(state_probs_normal_smooth + state_probs_highload_smooth),
                name = paste0(ICONS$high_load, " ", LABELS$high_load),
                type = 'scatter',
                mode = 'none',
                fill = 'tonexty',
                fillcolor = rgba(COLORS$high_load, 0.8),
                line = list(width = 0),
                hovertemplate = paste0(LABELS$high_load, ': %{customdata:.1%}<extra></extra>'),
                customdata = ~state_probs_highload_smooth) %>%
      # Layer 3 (top): Normal + High Load + Lapse = 100%
      add_trace(y = ~(state_probs_normal_smooth + state_probs_highload_smooth + state_probs_lapse_smooth),
                name = paste0(ICONS$lapse, " ", LABELS$lapse),
                type = 'scatter',
                mode = 'none',
                fill = 'tonexty',
                fillcolor = rgba(COLORS$lapse, 0.8),
                line = list(width = 0),
                hovertemplate = paste0(LABELS$lapse, ': %{customdata:.1%}<extra></extra>'),
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
  output$features_table <- DT::renderDT({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) {
      # Return empty table with proper structure
      return(data.frame(
        Metric = character(0),
        Value = character(0),
        Reference = character(0),
        stringsAsFactors = FALSE
      ))
    }
    req(nrow(current_data) > 0)  # Extra safety
    
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
    
    features_df
  }, options = list(dom = 't', ordering = FALSE, paging = FALSE), 
     rownames = FALSE, server = FALSE)  # Client-side to prevent Ajax errors
  
  # ========================================================================
  # DIAGNOSTIC PLOTS - REAL DATA FROM .RDS FILES
  # ========================================================================
  
  # CALIBRATION SECTION - REAL DATA
  output$calibration_plot_real <- renderPlot({
    req(diagnostics$calibration$calib_plot)
    print(diagnostics$calibration$calib_plot)
  })
  
  output$prob_hist_plot_real <- renderPlot({
    req(diagnostics$calibration$prob_hist_plot)
    print(diagnostics$calibration$prob_hist_plot)
  })
  
  output$calibration_stats <- renderTable({
    req(diagnostics$calibration$calib_stats_gt)
    # Extract data from gt table and format as simple table
    gt_data <- diagnostics$calibration$calib_stats_gt
    data.frame(
      Metric = c("ECE (Expected Calibration Error)", "MCE (Maximum Calibration Error)", "Brier Score"),
      Value = c(
        sprintf("%.6f", gt_data$`_data`$Value[1]),
        sprintf("%.6f", gt_data$`_data`$Value[2]), 
        sprintf("%.6f", gt_data$`_data`$Value[3])
      ),
      Interpretation = c(
        if (gt_data$`_data`$Value[1] < 0.01) "Excellent calibration" else "Good calibration",
        if (gt_data$`_data`$Value[2] < 0.01) "Excellent calibration" else "Good calibration", 
        if (gt_data$`_data`$Value[3] < 0.01) "Very low prediction error" else "Low prediction error"
      ),
      stringsAsFactors = FALSE
    )
  }, striped = TRUE, hover = TRUE, bordered = TRUE)
  
  # MODEL OVERVIEW SECTION - REAL DATA
  output$loso_confusion_matrix <- renderPlot({
    req(diagnostics$loso$cm_plot)
    print(diagnostics$loso$cm_plot)
  })
  
  output$loso_pr_curve <- renderPlot({
    req(diagnostics$loso$pr_lapse_plot)
    print(diagnostics$loso$pr_lapse_plot)
  })
  
  output$model_params <- renderText({
    req(diagnostics$artifacts$params)
    params <- diagnostics$artifacts$params
    paste(
      "Model: XGBoost Multi-Class Classifier\n",
      sprintf("Objective: %s\n", params$objective),
      sprintf("Number of Classes: %d\n", params$num_class),
      sprintf("Evaluation Metric: %s\n", params$eval_metric),
      sprintf("Max Depth: %d\n", params$max_depth),
      sprintf("Learning Rate (eta): %.3f\n", params$eta),
      sprintf("Subsample: %.2f\n", params$subsample),
      sprintf("Column Sample: %.2f\n", params$colsample_bytree),
      sprintf("Min Child Weight: %d", params$min_child_weight),
      sep = ""
    )
  })
  
  # CROSS-VALIDATION SECTION - REAL DATA
  output$loso_summary_table <- renderTable({
    req(diagnostics$loso$loso_df)
    loso_data <- diagnostics$loso$loso_df
    
    # Format for display
    data.frame(
      Surgeon = loso_data$holdout,
      `PR-AUC` = round(loso_data$pr_auc, 4),
      check.names = FALSE,
      stringsAsFactors = FALSE
    )
  }, striped = TRUE, hover = TRUE, bordered = TRUE)
  
  # FEATURE IMPORTANCE SECTION - REAL DATA
  output$feature_importance_plot <- renderPlot({
    req(diagnostics$artifacts$xgb_importance_plot)
    importance_data <- diagnostics$artifacts$xgb_importance_plot
    
    # Create horizontal barplot
    par(mar = c(5, 12, 4, 2))  # Increase left margin for feature names
    barplot(
      importance_data$Gain,
      names.arg = importance_data$Feature,
      horiz = TRUE,
      las = 1,
      main = "XGBoost Feature Importance (Gain)",
      xlab = "Gain",
      col = "#3498db",
      border = NA
    )
  })
  
  # PARTIAL DEPENDENCE SECTION - REAL DATA
  output$pd_plot_1 <- renderPlot({
    req(diagnostics$artifacts$pd_plots)
    req(length(diagnostics$artifacts$pd_plots) >= 1)
    print(diagnostics$artifacts$pd_plots[[1]])
  })
  
  output$pd_plot_2 <- renderPlot({
    req(diagnostics$artifacts$pd_plots)
    req(length(diagnostics$artifacts$pd_plots) >= 2)
    print(diagnostics$artifacts$pd_plots[[2]])
  })
  
  output$pd_plot_3 <- renderPlot({
    req(diagnostics$artifacts$pd_plots)
    req(length(diagnostics$artifacts$pd_plots) >= 3)
    print(diagnostics$artifacts$pd_plots[[3]])
  })
  
  # THRESHOLD SANDBOX SECTION - REAL DATA
  output$threshold_metrics_plot <- renderPlot({
    req(diagnostics$threshold_sandbox$data$lapse_p)
    req(diagnostics$threshold_sandbox$data$lab_bin)
    
    lapse_probs <- diagnostics$threshold_sandbox$data$lapse_p
    labels <- diagnostics$threshold_sandbox$data$lab_bin
    
    # Debug info
    cat("Threshold data loaded:\n")
    cat("  - lapse_probs length:", length(lapse_probs), "\n")
    cat("  - labels length:", length(labels), "\n")
    cat("  - lapse_probs range:", range(lapse_probs), "\n")
    cat("  - labels unique:", unique(labels), "\n")
    
    # Distribution of predicted probabilities
    if (length(lapse_probs) > 0 && all(is.numeric(lapse_probs))) {
      hist(lapse_probs, breaks = 50, 
           main = "Distribution of Lapse Probabilities",
           xlab = "Lapse Probability", ylab = "Frequency",
           col = "#3498db", border = "white")
      
      # Mark current threshold
      abline(v = 0.30, col = "red", lwd = 3, lty = 2)
      text(0.30, par("usr")[4] * 0.9, "Current\nThreshold\n(0.30)", 
           col = "red", pos = 4, cex = 0.9)
    } else {
      plot.new()
      text(0.5, 0.5, "No valid probability data available", cex = 1.2, col = "#666")
    }
  })
  
  output$threshold_f1_plot <- renderPlot({
    req(diagnostics$threshold_sandbox$data$lapse_p)
    req(diagnostics$threshold_sandbox$data$lab_bin)
    
    lapse_probs <- diagnostics$threshold_sandbox$data$lapse_p
    labels <- as.numeric(diagnostics$threshold_sandbox$data$lab_bin)
    
    # Check data validity
    if (length(lapse_probs) == 0 || length(labels) == 0 || 
        !all(is.numeric(lapse_probs)) || !all(is.numeric(labels))) {
      plot.new()
      text(0.5, 0.5, "No valid data for PR curve", cex = 1.2, col = "#666")
      return()
    }
    
    # Calculate metrics across different thresholds (appropriate for this data range)
    max_prob <- max(lapse_probs)
    thresholds <- seq(0.0001, max_prob * 1.5, length.out = 50)
    precision <- numeric(length(thresholds))
    recall <- numeric(length(thresholds))
    
    for (i in seq_along(thresholds)) {
      thresh <- thresholds[i]
      pred <- as.numeric(lapse_probs >= thresh)
      
      tp <- sum(pred == 1 & labels == 1)
      fp <- sum(pred == 1 & labels == 0)
      fn <- sum(pred == 0 & labels == 1)
      
      precision[i] <- if (tp + fp > 0) tp / (tp + fp) else 0
      recall[i] <- if (tp + fn > 0) tp / (tp + fn) else 0
    }
    
    # Plot Precision-Recall tradeoff
    plot(recall, precision, type = "l", lwd = 3, col = "#e74c3c",
         main = "Precision-Recall Tradeoff",
         xlab = "Recall (Sensitivity)", ylab = "Precision (PPV)",
         xlim = c(0, 1), ylim = c(0, 1))
    grid()
    
    # Mark optimal threshold (best F1 score)
    f1_scores <- 2 * precision * recall / (precision + recall)
    f1_scores[is.nan(f1_scores)] <- 0
    best_idx <- which.max(f1_scores)
    
    if (best_idx > 0 && best_idx <= length(thresholds)) {
      points(recall[best_idx], precision[best_idx], 
             pch = 19, col = "darkgreen", cex = 2)
      text(recall[best_idx], precision[best_idx], 
           sprintf("  Optimal\n  (%.4f)", thresholds[best_idx]), 
           pos = 4, col = "darkgreen", cex = 0.9)
    }
    
    # Mark current threshold if it's in range
    current_idx <- which.min(abs(thresholds - 0.30))
    if (current_idx > 0 && current_idx <= length(thresholds) && thresholds[current_idx] <= max_prob * 1.5) {
      points(recall[current_idx], precision[current_idx], 
             pch = 17, col = "orange", cex = 2)
      text(recall[current_idx], precision[current_idx], 
           "  Current\n  (0.30)", pos = 2, col = "orange", cex = 0.9)
    }
  })
  
  # Alert Log
  output$alertlog <- DT::renderDT({
    alert_data <- logdf()
    
    # Return formatted data frame (DT::renderDT handles the rest)
    if (nrow(alert_data) == 0) {
      return(data.frame(
        Time = character(0),
        Alert = character(0),
        Details = character(0),
        `Lapse Prob.` = character(0),
        `High Load Prob.` = character(0),
        check.names = FALSE,
        stringsAsFactors = FALSE
      ))
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
  }, options = list(pageLength = 5, dom = 'tp', ordering = FALSE,
                    paging = TRUE, searching = FALSE), 
     rownames = FALSE, server = FALSE)  # Client-side to prevent Ajax errors
  
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
    is_alert <- (lapse_prob > thresh$lapse_threshold || highload_prob > thresh$high_load_threshold)
    
    if (!isTRUE(input$silent) && is_alert) {
      alert_type <- ifelse(lapse_prob > thresh$lapse_threshold, 
                           LABELS$alert_lapse, 
                           LABELS$alert_high)
      
      # Determine alert state for error sources
      alert_state <- ifelse(lapse_prob > thresh$lapse_threshold, 
                           "Attentional Lapse", 
                           "High Load")
      
      details_text <- if (lapse_prob > thresh$lapse_threshold) {
        sprintf("%s probability (%.1f%%) exceeded threshold (%.1f%%)", 
                LABELS$lapse,
                lapse_prob * 100, thresh$lapse_threshold * 100)
      } else {
        sprintf("%s probability (%.1f%%) exceeded threshold (%.1f%%)", 
                LABELS$high_load,
                highload_prob * 100, thresh$high_load_threshold * 100)
      }
      
      # Get error sources log entry if logging enabled
      error_log_entry <- NULL
      if (isTRUE(input$log_events)) {
        error_log_entry <- error_sources$get_log_entry()
        if (!is.null(error_log_entry)) {
          details_text <- paste0(details_text, " | ", format_error_log(error_log_entry))
        }
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
      
      # Update error sources panel state
      alert_active(TRUE)
      current_alert_state(alert_state)
    } else {
      # No alert - hide error sources panel
      alert_active(FALSE)
      current_alert_state("Normal")
    }
    
    idx(i + 1L)
  })
}

shinyApp(ui, server)
