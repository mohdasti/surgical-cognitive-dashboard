library(shiny)
library(bslib)
library(plotly)
library(DT)
library(sparkline)
library(zoo)
library(scales)
library(glue)
# library(shinyjs)  # DISABLED - not currently used, avoiding dependency
# library(cicerone)  # DISABLED - causes opacity overlay

# Load the setup
source("../scripts/00_setup.R")

# Load theme and MSI helpers
source("../R/theme_md.R")
source("../R/feature_hrv.R")

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
source("../R/gt_table_utils.R")
source("../R/mod_gt_live_table.R")

ui <- tagList(
  # Initialize shinyjs (DISABLED - not currently used)
  # shinyjs::useShinyjs(),
  
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
      
      /* ============================================
         CSS ICON ENHANCEMENTS
         ============================================ */
      
      /* 1. Status Indicator Dots */
      .status-dot {
        display: inline-block;
        width: 10px;
        height: 10px;
        border-radius: 50%;
        margin-right: 8px;
        vertical-align: middle;
      }
      
      .status-dot-normal {
        background: #27ae60;
        box-shadow: 0 0 8px rgba(39, 174, 96, 0.6);
        animation: pulse-slow 3s infinite;
      }
      
      .status-dot-highload {
        background: #f39c12;
        box-shadow: 0 0 8px rgba(243, 156, 18, 0.6);
        animation: warning-flash 1.5s infinite;
      }
      
      .status-dot-lapse {
        background: #e74c3c;
        box-shadow: 0 0 10px rgba(231, 76, 60, 0.8);
        animation: urgent-pulse 0.8s infinite;
      }
      
      @keyframes pulse-slow {
        0%, 100% { transform: scale(1); opacity: 1; }
        50% { transform: scale(1.1); opacity: 0.8; }
      }
      
      @keyframes warning-flash {
        0%, 100% { opacity: 1; }
        50% { opacity: 0.6; }
      }
      
      @keyframes urgent-pulse {
        0%, 100% { transform: scale(1); box-shadow: 0 0 10px rgba(231, 76, 60, 0.8); }
        50% { transform: scale(1.2); box-shadow: 0 0 15px rgba(231, 76, 60, 1); }
      }
      
      /* 2. Connection Heartbeat Indicator */
      .connection-status {
        display: inline-flex;
        align-items: center;
        gap: 8px;
      }
      
      .connection-dot {
        width: 8px;
        height: 8px;
        background: #27ae60;
        border-radius: 50%;
        box-shadow: 0 0 6px rgba(39, 174, 96, 0.8);
        animation: heartbeat 2s infinite;
      }
      
      @keyframes heartbeat {
        0%, 100% { transform: scale(1); opacity: 1; }
        10% { transform: scale(1.3); opacity: 1; }
        20% { transform: scale(1); opacity: 1; }
        30% { transform: scale(1.3); opacity: 1; }
        40% { transform: scale(1); opacity: 0.8; }
      }
      
      /* 3. Slider Visual Enhancements */
      .slider-container {
        position: relative;
      }
      
      .slider-danger-hint {
        position: absolute;
        right: 0;
        top: -5px;
        font-size: 0.75em;
        color: #e74c3c;
        opacity: 0.7;
        animation: fade-pulse 2s infinite;
      }
      
      @keyframes fade-pulse {
        0%, 100% { opacity: 0.7; }
        50% { opacity: 0.4; }
      }
      
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
      
      // Handler for status pill updates
      Shiny.addCustomMessageHandler('evaljs', function(message) {
        eval(message.code);
      });
    "))
  ),
  
  # ========================================================================
  # TAB 1: LIVE MONITOR
  # ========================================================================
  tabPanel("Live Monitor",
    
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
                h2(uiOutput("status_display"))
            )
          ),
          column(4,
            div(class = "metric-card",
                h3("Lapse Probability"),
                h2(textOutput("lapse_prob_text", inline = TRUE))
            )
          ),
          column(4,
            div(class = "metric-card",
                h3("Performance"),
                h2(textOutput("performance_text", inline = TRUE))
            )
          )
        ),
        
        # Error Sources Panel (appears on alerts) - DISABLED (requires shinyjs)
        # mod_error_sources_ui("error_sources"),
        
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
            column(6, 
              # Cognitive Load Index Card
              div(style = "background: white; border: 1px solid #e5e7eb; border-radius: 12px; padding: 16px; height: 300px; display: flex; flex-direction: column;",
                div(style = "display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;",
                  tags$strong("Cognitive Load Index", style = "font-size: 1.1em;"),
                  span(id = "load-status-pill",
                       style = "padding: 0.2rem 0.6rem; border-radius: 999px; font-size: 0.75rem; font-weight: 500; border: 1px solid #e5e7eb;")
                ),
                div(style = "display: flex; align-items: baseline; gap: 10px; margin-bottom: 16px;",
                  tags$h2(textOutput("load_index", inline = TRUE), style = "margin: 0; font-size: 2.5em; font-weight: 600;"),
                  span("/100", style = "color: #6b7280; font-size: 0.9em;")
                ),
                div(style = "flex: 1; overflow: hidden;",
                  div(style = "display: grid; grid-template-columns: 90px 1fr; gap: 8px; align-items: center; margin-bottom: 8px;",
                    span("Pupil Dilation", style = "color: #6b7280; font-size: 0.85em; font-weight: 500;"),
                    sparklineOutput("spark_pupil", width = "100%", height = "35px")
                  ),
                  div(style = "display: grid; grid-template-columns: 90px 1fr; gap: 8px; align-items: center;",
                    span("HRV Drop", style = "color: #6b7280; font-size: 0.85em; font-weight: 500;"),
                    sparklineOutput("spark_hrv_drop", width = "100%", height = "35px")
                  )
                ),
                tags$details(style = "margin-top: 12px; font-size: 0.85em;",
                  tags$summary(style = "cursor: pointer; color: #1f9bb6; font-weight: 500;", "Show Details"),
                  div(style = "margin-top: 12px; padding-top: 12px; border-top: 1px solid #e5e7eb; max-height: 200px; overflow-y: auto;",
                    div(style = "margin-bottom: 12px;",
                      plotOutput("pupil_plot_small", height = "120px")
                    ),
                    div(
                      plotOutput("hrv_plot_small", height = "120px")
                    )
                  )
                )
              )
            ),
            column(6, 
              # Motor Steadiness Index (MSI) Card
              div(style = "background: white; border: 1px solid #e5e7eb; border-radius: 12px; padding: 16px; height: 300px; display: flex; flex-direction: column;",
                div(style = "display: flex; align-items: center; justify-content: space-between; margin-bottom: 12px;",
                  tags$strong("Motor Steadiness Index", style = "font-size: 1.1em;"),
                  span(id = "msi-status-pill",
                       style = "padding: 0.2rem 0.6rem; border-radius: 999px; font-size: 0.75rem; font-weight: 500; border: 1px solid #e5e7eb;")
                ),
                div(style = "display: flex; align-items: baseline; gap: 10px; margin-bottom: 16px;",
                  tags$h2(textOutput("msi_value", inline = TRUE), style = "margin: 0; font-size: 2.5em; font-weight: 600;"),
                  span("/100", style = "color: #6b7280; font-size: 0.9em;")
                ),
                div(style = "flex: 1; overflow: hidden;",
                  div(style = "display: grid; grid-template-columns: 90px 1fr; gap: 8px; align-items: center; margin-bottom: 8px;",
                    span("Tremor", style = "color: #6b7280; font-size: 0.85em; font-weight: 500;"),
                    sparklineOutput("spark_tremor", width = "100%", height = "35px")
                  ),
                  div(style = "display: grid; grid-template-columns: 90px 1fr; gap: 8px; align-items: center;",
                    span("Grip CV%", style = "color: #6b7280; font-size: 0.85em; font-weight: 500;"),
                    sparklineOutput("spark_gripcv", width = "100%", height = "35px")
                  )
                ),
                tags$details(style = "margin-top: 12px; font-size: 0.85em;",
                  tags$summary(style = "cursor: pointer; color: #1f9bb6; font-weight: 500;", "Show Details"),
                  div(style = "margin-top: 12px; padding-top: 12px; border-top: 1px solid #e5e7eb; max-height: 200px; overflow-y: auto;",
                    div(style = "margin-bottom: 12px;",
                      plotOutput("tremor_plot_small", height = "120px")
                    ),
                    div(
                      plotOutput("gripcv_plot_small", height = "120px")
                    )
                  )
                )
              )
            )
          ),
          fluidRow(
            column(12, plotlyOutput("state_prob_plot", height = "350px"))
          )
        ),
        
        # Feature Values Table (GT version with literature ranges)
        # Toggle visibility based on checkbox using conditionalPanel
        conditionalPanel(
          condition = "input.show_features",
          gt_live_table_ui("gtlive", title = "Real-time Feature Values")
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
  tabPanel("ML Model Diagnostics",
    mod_diagnostics_progressive_ui("diagnostics")
  )
  ) # Close navbarPage
) # Close tagList

server <- function(input, output, session) {
  
  # ============================================================================
  # MSI (Motor Steadiness Index) Helpers
  # ============================================================================
  
  # Safe z-score with capping
  zscore_series <- function(x, ref_mu = NULL, ref_sd = NULL) {
    x <- as.numeric(x)
    mu <- if (is.null(ref_mu)) mean(x, na.rm = TRUE) else ref_mu
    sd_val <- if (is.null(ref_sd)) stats::sd(x, na.rm = TRUE) else ref_sd
    if (!is.finite(sd_val) || sd_val == 0) sd_val <- 1
    (x - mu) / sd_val
  }
  
  # Cap z-scores to prevent outliers
  scale_cap <- function(x, cap = 3) {
    x <- as.numeric(x)
    x[x >  cap] <-  cap
    x[x < -cap] <- -cap
    x
  }
  
  # Coefficient of variation (%)
  cv_percent <- function(x) {
    x <- as.numeric(x)
    m <- mean(x, na.rm = TRUE)
    s <- stats::sd(x, na.rm = TRUE)
    if (!is.finite(m) || m == 0) return(NA_real_)
    100 * s / m
  }
  
  # Map MSI z-score to 0-100 scale (higher is better)
  msi_to_100 <- function(msi_z, span = 2.5) {
    scales::rescale(msi_z, to = c(0, 100), from = c(-span, span))
  }
  
  # MSI status thresholds
  msi_status <- function(msi100, warn = 40, crit = 25) {
    if (is.na(msi100)) return("Unknown")
    if (msi100 <= crit) "Critical" else if (msi100 <= warn) "Elevated" else "Normal"
  }
  
  # Status colors matching md_colors
  status_color <- function(s) {
    switch(s, 
      "Normal" = "#27ae60",    # md_colors$ok
      "Elevated" = "#f39c12",  # md_colors$warn
      "Critical" = "#e74c3c",  # md_colors$crit
      "#6b7280"                # md_colors$muted
    )
  }
  
  # ============================================================================
  # LOAD DIAGNOSTIC DATA (REAL MODEL DIAGNOSTICS)
  # ============================================================================
  
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
  
  # Mount error sources module (DISABLED - requires shinyjs)
  # error_sources <- mod_error_sources_server(
  #   "error_sources",
  #   current_state = current_alert_state,
  #   alert_active = alert_active
  # )
  
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
  
  # Initialize popovers for help icons (DISABLED - requires shinyjs)
  # init_popovers(session)
  
  # ========================================================================
  # END GUIDED TOUR INTEGRATION
  # ========================================================================
  
  # Real-time data storage for plots
  realtime_data <- reactiveVal(tibble::tibble(
    timestamp = numeric(),
    pupil_diameter = numeric(),
    pupil_tepr = numeric(),
    blink_rate = numeric(),
    grip_force = numeric(),
    tremor_amplitude = numeric(),
    hrv_rmssd = numeric(),
    ambient_noise = numeric(),
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
      pupil_tepr = numeric(),
      blink_rate = numeric(),
      grip_force = numeric(),
      tremor_amplitude = numeric(),
      hrv_rmssd = numeric(),
      ambient_noise = numeric(),
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
  
  # Status Display with animated dot indicator
  output$status_display <- renderUI({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) return(tagList(tags$span(class = "status-dot status-dot-normal"), "Initializing..."))
    
    status <- tail(current_data$final_state, 1)
    
    # Choose dot class based on status
    dot_class <- switch(status,
      "Normal" = "status-dot status-dot-normal",
      "High Load" = "status-dot status-dot-highload",
      "Attentional Lapse" = "status-dot status-dot-lapse",
      "status-dot status-dot-normal"  # default
    )
    
    tagList(
      tags$span(class = dot_class),
      status
    )
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
      layout(title = "Pupil Diameter (photopic, TEPR)",
             xaxis = list(title = "Time (minutes)"),
             yaxis = list(title = "Diameter (mm)", range = c(2.5, 5.0)))
  })
  
  output$grip_plot <- renderPlotly({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) return(plotly_empty())
    
    plot_ly(current_data, x = ~(timestamp/60), y = ~grip_force,
            type = 'scatter', mode = 'lines',
            line = list(color = '#e74c3c', width = 2)) %>%
      layout(title = "Grip Force (da Vinci robotic instruments)",
             xaxis = list(title = "Time (minutes)"),
             yaxis = list(title = "Force (N)", range = c(0, 10)))
  })
  
  output$tremor_plot <- renderPlotly({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) return(plotly_empty())
    
    plot_ly(current_data, x = ~(timestamp/60), y = ~tremor_amplitude,
            type = 'scatter', mode = 'lines',
            line = list(color = '#f39c12', width = 2)) %>%
      layout(title = "Tremor Amplitude (8-12 Hz, μm)",
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
      layout(title = "Cognitive State Distribution (Stacked Probabilities)",
             xaxis = list(title = "Time (minutes)"),
             yaxis = list(title = "Probability", range = c(0, 1), tickformat = ',.0%'),
             hovermode = 'x unified',
             showlegend = TRUE,
             legend = list(orientation = 'h', y = -0.35, x = 0.5, xanchor = 'center'),
             margin = list(b = 100, t = 50, l = 50, r = 50))
  })
  
  # HRV (RMSSD) plot
  output$plot_hrv_rmssd <- renderPlot({
    req(realtime_data())
    df <- realtime_data()
    if (nrow(df) == 0) return(NULL)
    
    # Compute rolling RMSSD if available
    if ("hrv_rmssd" %in% names(df) && !all(is.na(df$hrv_rmssd))) {
      ggplot2::ggplot(df, ggplot2::aes(x = timestamp / 60, y = hrv_rmssd)) +
        ggplot2::geom_line(color = "#0ea5b7", linewidth = 0.8) +
        ggplot2::labs(
          title = "Heart Rate Variability (RMSSD)",
          subtitle = "Lower RMSSD ↘ typically accompanies sustained cognitive load",
          x = "Time (min)",
          y = "RMSSD (ms)"
        ) +
        ggplot2::theme_minimal() +
        theme_md()
    } else {
      # Fallback if no HRV data
      ggplot2::ggplot(data.frame(x = 0, y = 0), ggplot2::aes(x, y)) +
        ggplot2::geom_blank() +
        ggplot2::labs(
          title = "Heart Rate Variability (RMSSD)",
          subtitle = "HRV data not available in current simulation",
          x = "Time (min)",
          y = "RMSSD (ms)"
        ) +
        ggplot2::theme_minimal() +
        theme_md()
    }
  }, bg = "white")
  
  # ============================================================================
  # MSI (Motor Steadiness Index) Calculation and Outputs
  # ============================================================================
  
  # MSI weights (can be made user-tunable via sliders)
  msi_weights <- reactiveVal(list(w_tremor = 0.6, w_gripcv = 0.4))
  
  # MSI data with z-scores and composite index
  msi_data <- reactive({
    req(realtime_data())
    df <- realtime_data()
    
    if (nrow(df) < 2) {
      return(df %>% 
        mutate(
          grip_cv = NA_real_,
          tremor_z = NA_real_,
          gripcv_z = NA_real_,
          msi_z = NA_real_,
          msi_100 = 50,
          msi_state = "Normal",
          msi_color = "#27ae60"
        ))
    }
    
    # Compute rolling grip CV% (15s window ~= 75 samples at 5Hz)
    window_size <- 75L
    if (nrow(df) >= window_size) {
      df$grip_cv <- zoo::rollapply(
        df$grip_force, 
        width = window_size, 
        FUN = cv_percent, 
        by = 1, 
        partial = TRUE, 
        align = "right",
        fill = NA
      )
    } else {
      df$grip_cv <- cv_percent(df$grip_force)
    }
    
    # Reference window for z-scoring (first 120s ~= 600 samples at 5Hz)
    ref_n <- min(600, nrow(df))
    ref_idx <- seq_len(ref_n)
    
    # Z-scores using reference window
    tremor_mu <- mean(df$tremor_amplitude[ref_idx], na.rm = TRUE)
    tremor_sd <- stats::sd(df$tremor_amplitude[ref_idx], na.rm = TRUE)
    gripcv_mu <- mean(df$grip_cv[ref_idx], na.rm = TRUE)
    gripcv_sd <- stats::sd(df$grip_cv[ref_idx], na.rm = TRUE)
    
    df$tremor_z <- zscore_series(df$tremor_amplitude, tremor_mu, tremor_sd)
    df$gripcv_z <- zscore_series(df$grip_cv, gripcv_mu, gripcv_sd)
    
    # Composite MSI (lower tremor/gripcv is better, so negate)
    w <- msi_weights()
    df$msi_z <- scale_cap(-df$tremor_z, cap = 3) * w$w_tremor + 
                scale_cap(-df$gripcv_z, cap = 3) * w$w_gripcv
    
    # Map to 0-100 scale for display
    df$msi_100 <- msi_to_100(df$msi_z)
    df$msi_state <- vapply(df$msi_100, msi_status, character(1), USE.NAMES = FALSE)
    df$msi_color <- vapply(df$msi_state, status_color, character(1), USE.NAMES = FALSE)
    
    df
  })
  
  # Current MSI value
  current_msi <- reactive({
    req(msi_data())
    df <- msi_data()
    if (nrow(df) == 0) return(NULL)
    tail(df, 1)
  })
  
  # MSI KPI value
  output$msi_value <- renderText({
    req(current_msi())
    sprintf("%.0f", current_msi()$msi_100)
  })
  
  # Update MSI status pill color
  observe({
    req(current_msi())
    s  <- current_msi()$msi_state
    bg <- current_msi()$msi_color
    js <- sprintf("
      const pill = document.getElementById('msi-status-pill');
      if (pill) {
        pill.textContent = '%s';
        pill.style.background = '%s20';
        pill.style.borderColor = '%s';
        pill.style.color = '%s';
      }
    ", s, bg, bg, bg)
    session$sendCustomMessage("evaljs", list(code = js))
  })
  
  # Tremor sparkline
  output$spark_tremor <- renderSparkline({
    req(msi_data())
    df <- tail(msi_data(), 600)  # Last ~2 minutes at 5Hz
    if (nrow(df) < 2) return(NULL)
    sparkline(df$tremor_amplitude, type = "line", lineColor = "#e74c3c", 
              fillColor = FALSE, lineWidth = 2, width = "100%", height = "35px")
  })
  
  # Grip CV sparkline
  output$spark_gripcv <- renderSparkline({
    req(msi_data())
    df <- tail(msi_data(), 600)  # Last ~2 minutes at 5Hz
    if (nrow(df) < 2) return(NULL)
    sparkline(df$grip_cv, type = "line", lineColor = "#f39c12", 
              fillColor = FALSE, lineWidth = 2, width = "100%", height = "35px")
  })
  
  # Small tremor plot for details section
  output$tremor_plot_small <- renderPlot({
    req(msi_data())
    df <- tail(msi_data(), 900)  # Last ~3 minutes
    if (nrow(df) < 2) return(NULL)
    
    ggplot2::ggplot(df, ggplot2::aes(x = timestamp / 60, y = tremor_amplitude)) +
      ggplot2::geom_line(color = "#e74c3c", linewidth = 0.8) +
      ggplot2::labs(
        title = "Tremor Amplitude (8–12 Hz)",
        x = "Time (min)",
        y = "RMS (μm)"
      ) +
      ggplot2::theme_minimal(base_size = 10) +
      theme_md()
  }, bg = "white")
  
  # Small grip CV plot for details section
  output$gripcv_plot_small <- renderPlot({
    req(msi_data())
    df <- tail(msi_data(), 900)  # Last ~3 minutes
    if (nrow(df) < 2 || all(is.na(df$grip_cv))) return(NULL)
    
    ggplot2::ggplot(df, ggplot2::aes(x = timestamp / 60, y = grip_cv)) +
      ggplot2::geom_line(color = "#f39c12", linewidth = 0.8) +
      ggplot2::labs(
        title = "Grip Force Variability",
        x = "Time (min)",
        y = "CV%"
      ) +
      ggplot2::theme_minimal(base_size = 10) +
      theme_md()
  }, bg = "white")
  
  # ============================================================================
  # Cognitive Load Index Calculation and Outputs
  # ============================================================================
  
  # Cognitive Load Index (Pupil + HRV)
  load_weights <- reactiveVal(list(w_pupil = 0.6, w_hrv = 0.4))
  
  load_data <- reactive({
    req(realtime_data())
    df <- realtime_data()
    
    if (nrow(df) < 2) {
      return(df %>% mutate(
        pupil_z = NA_real_,
        hrv_drop_z = NA_real_,
        load_z = NA_real_,
        load_100 = 50,
        load_state = "Normal",
        load_color = "#27ae60"
      ))
    }
    
    # Reference window for z-scoring (first 120s ~= 600 samples at 5Hz)
    ref_n <- min(600, nrow(df))
    ref_idx <- seq_len(ref_n)
    
    # Z-scores
    pupil_mu <- mean(df$pupil_diameter[ref_idx], na.rm = TRUE)
    pupil_sd <- stats::sd(df$pupil_diameter[ref_idx], na.rm = TRUE)
    hrv_mu <- mean(df$hrv_rmssd[ref_idx], na.rm = TRUE)
    hrv_sd <- stats::sd(df$hrv_rmssd[ref_idx], na.rm = TRUE)
    
    df$pupil_z <- zscore_series(df$pupil_diameter, pupil_mu, pupil_sd)
    df$hrv_drop_z <- -zscore_series(df$hrv_rmssd, hrv_mu, hrv_sd)  # Negative because HRV drops with load
    
    # Composite Load Index (higher pupil + lower HRV = higher load)
    w <- load_weights()
    df$load_z <- scale_cap(df$pupil_z, cap = 3) * w$w_pupil + 
                 scale_cap(df$hrv_drop_z, cap = 3) * w$w_hrv
    
    # Map to 0-100 scale
    df$load_100 <- msi_to_100(df$load_z)
    df$load_state <- vapply(df$load_100, function(x) {
      if (is.na(x)) "Unknown"
      else if (x >= 60) "High Load" else if (x >= 40) "Moderate" else "Low"
    }, character(1), USE.NAMES = FALSE)
    df$load_color <- vapply(df$load_state, function(s) {
      switch(s, 
        "High Load" = "#e74c3c",
        "Moderate" = "#f39c12",
        "Low" = "#27ae60",
        "#6b7280"
      )
    }, character(1), USE.NAMES = FALSE)
    
    df
  })
  
  current_load <- reactive({
    req(load_data())
    df <- load_data()
    if (nrow(df) == 0) return(NULL)
    tail(df, 1)
  })
  
  output$load_index <- renderText({
    req(current_load())
    sprintf("%.0f", current_load()$load_100)
  })
  
  observe({
    req(current_load())
    s  <- current_load()$load_state
    bg <- current_load()$load_color
    js <- sprintf("
      const pill = document.getElementById('load-status-pill');
      if (pill) {
        pill.textContent = '%s';
        pill.style.background = '%s20';
        pill.style.borderColor = '%s';
        pill.style.color = '%s';
      }
    ", s, bg, bg, bg)
    session$sendCustomMessage("evaljs", list(code = js))
  })
  
  output$spark_pupil <- renderSparkline({
    req(load_data())
    df <- tail(load_data(), 600)  # Last ~2 minutes at 5Hz
    if (nrow(df) < 2) return(NULL)
    sparkline(df$pupil_diameter, type = "line", lineColor = "#3498db", 
              fillColor = FALSE, lineWidth = 2, width = "100%", height = "35px")
  })
  
  output$spark_hrv_drop <- renderSparkline({
    req(load_data())
    df <- tail(load_data(), 600)
    if (nrow(df) < 2) return(NULL)
    # Show inverted HRV (drop = higher values)
    sparkline(-df$hrv_rmssd, type = "line", lineColor = "#e67e22", 
              fillColor = FALSE, lineWidth = 2, width = "100%", height = "35px")
  })
  
  # Small pupil plot for Cognitive Load Index details section
  output$pupil_plot_small <- renderPlot({
    req(load_data())
    df <- tail(load_data(), 900)  # Last ~3 minutes
    if (nrow(df) < 2) return(NULL)
    
    ggplot2::ggplot(df, ggplot2::aes(x = timestamp / 60, y = pupil_diameter)) +
      ggplot2::geom_line(color = "#3498db", linewidth = 0.8) +
      ggplot2::labs(
        title = "Pupil Diameter (TEPR)",
        x = "Time (min)",
        y = "Diameter (mm)"
      ) +
      ggplot2::theme_minimal(base_size = 10) +
      theme_md()
  }, bg = "white")
  
  # Small HRV plot for Cognitive Load Index details section
  output$hrv_plot_small <- renderPlot({
    req(load_data())
    df <- tail(load_data(), 900)  # Last ~3 minutes
    if (nrow(df) < 2 || !"hrv_rmssd" %in% names(df) || all(is.na(df$hrv_rmssd))) return(NULL)
    
    ggplot2::ggplot(df, ggplot2::aes(x = timestamp / 60, y = hrv_rmssd)) +
      ggplot2::geom_line(color = "#0ea5b7", linewidth = 0.8) +
      ggplot2::labs(
        title = "Heart Rate Variability (RMSSD)",
        x = "Time (min)",
        y = "RMSSD (ms)"
      ) +
      ggplot2::theme_minimal(base_size = 10) +
      theme_md()
  }, bg = "white")
  
  # ========================================================================
  # GT LIVE TABLE INTEGRATION
  # ========================================================================
  
  # Build features_reactive for current window
  features_reactive <- reactive({
    current_data <- realtime_data()
    
    # If no data yet, show baseline values from literature
    if (nrow(current_data) == 0) {
      return(tibble::tibble(
        Feature = c("Pupil Diameter", "Grip Force", "Tremor RMS (8–12Hz)", 
                    "HRV (RMSSD)", "Grip CV%", "Time-on-Task",
                    "Normal Prob", "High Load Prob", "Lapse Prob"),
        Value = c(
          3.5,   # Baseline pupil (literature)
          3.0,   # Baseline grip (literature)
          100,   # Baseline tremor (literature)
          40,    # Baseline HRV RMSSD
          8,     # Fresh grip CV%
          0,     # Starting time
          100,   # Normal state initially
          0,     # No high load initially
          0      # No lapse initially
        ),
        Unit = c("mm", "N", "μm", "ms", "%", "min", "%", "%", "%")
      ))
    }
    
    # Live data available - extract current values
    latest <- tail(current_data, 1)
    t_current <- latest$timestamp
    fatigue_min <- t_current / 60
    grip_cv_pct <- (0.08 + (0.04 * min(1, fatigue_min / 30))) * 100
    
    tibble::tibble(
      Feature = c("Pupil Diameter", "Phasic Pupil (TEPR)", "Blink Rate",
                  "Grip Force", "Tremor RMS (8–12Hz)", 
                  "HRV (RMSSD)", "Grip CV%", "Time-on-Task", "Ambient Noise",
                  "Normal Prob", "High Load Prob", "Lapse Prob"),
      Value = c(
        latest$pupil_diameter,
        latest$pupil_tepr,
        latest$blink_rate,
        latest$grip_force,
        latest$tremor_amplitude,
        latest$hrv_rmssd,
        grip_cv_pct,
        fatigue_min,
        latest$ambient_noise,
        latest$state_probs_normal * 100,
        latest$state_probs_highload * 100,
        latest$state_probs_lapse * 100
      ),
      Unit = c("mm", "mm", "bpm", "N", "μm", "ms", "%", "min", "dB", "%", "%", "%")
    )
  })
  
  # Build trends_reactive over last N windows for sparklines
  trends_reactive <- reactive({
    current_data <- realtime_data()
    if (nrow(current_data) == 0) {
      # Return empty trends for initial display
      return(tibble::tibble(
        Feature = c("Pupil Diameter", "Grip Force", "Tremor RMS (8–12Hz)", 
                    "HRV (RMSSD)", "Grip CV%", "Time-on-Task",
                    "Normal Prob", "High Load Prob", "Lapse Prob"),
        Trend = replicate(9, numeric(0), simplify = FALSE)
      ))
    }
    
    # Last 60 data points (12 seconds at 5Hz) for sparklines
    hf <- current_data %>%
      dplyr::arrange(timestamp) %>%
      tail(60)
    
    # Calculate grip CV for each row
    grip_cv_vec <- sapply(hf$timestamp, function(t) {
      fatigue_min <- t / 60
      (0.08 + (0.04 * min(1, fatigue_min / 30))) * 100
    })
    
    tibble::tibble(
      Feature = c("Pupil Diameter", "Phasic Pupil (TEPR)", "Blink Rate",
                  "Grip Force", "Tremor RMS (8–12Hz)", 
                  "HRV (RMSSD)", "Grip CV%", "Time-on-Task", "Ambient Noise",
                  "Normal Prob", "High Load Prob", "Lapse Prob"),
      Trend = list(
        hf$pupil_diameter,
        hf$pupil_tepr,
        hf$blink_rate,
        hf$grip_force,
        hf$tremor_amplitude,
        hf$hrv_rmssd,
        grip_cv_vec,
        hf$timestamp / 60,
        hf$ambient_noise,
        hf$state_probs_normal * 100,
        hf$state_probs_highload * 100,
        hf$state_probs_lapse * 100
      )
    )
  })
  
  # Mount GT live table module
  gt_live_table_server(
    "gtlive",
    features_reactive = features_reactive,
    trends_reactive = trends_reactive,
    params_reactive = reactive({ CFG }),  # Use config for params
    personal_reactive = reactive({ NULL }),  # Can add personal baselines later
    refs_path = "../data/reference_ranges.csv"
  )
  
  # Toggle GT table visibility based on checkbox (DISABLED - shinyjs not loaded)
  # observeEvent(input$show_features, {
  #   shinyjs::toggle("gt_features_container", condition = input$show_features)
  # }, ignoreNULL = FALSE, ignoreInit = FALSE)
  
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
    
    # ==== HRV RMSSD (milliseconds) - Evidence from De Louche et al. 2024 ====
    # Baseline: 40ms, decreases ~20-35% under high cognitive load
    # HRV reflects parasympathetic (vagal) activity - complementary to pupil
    hrv_baseline <- 40                                           # 40ms baseline RMSSD
    hrv_load_reduction <- 0.35 * highload_prob                   # -35% max under high load
    hrv_fatigue_reduction <- 0.20 * lapse_prob                   # -20% during fatigue
    hrv_rmssd <- hrv_baseline * (1 - hrv_load_reduction) * (1 - hrv_fatigue_reduction)
    hrv_rmssd <- hrv_rmssd + rnorm(1, 0, 3)                     # Biological variability (±3ms)
    hrv_rmssd <- max(20, min(60, hrv_rmssd))                    # Physiological bounds: 20-60ms
    
    # ==== BLINK RATE (blinks per minute) - Evidence from Marquart et al. 2015 ====
    # Baseline: 15-20 blinks/min, decreases ~30% under load, increases ~40% with fatigue
    blink_baseline <- 17                                         # 17 blinks/min baseline
    blink_load_suppression <- 0.30 * highload_prob              # -30% under cognitive load
    blink_fatigue_increase <- 0.40 * lapse_prob                 # +40% during inattention/fatigue
    blink_rate <- blink_baseline * (1 - blink_load_suppression) * (1 + blink_fatigue_increase)
    blink_rate <- blink_rate + rnorm(1, 0, 2)                   # Natural variability (±2 blinks)
    blink_rate <- max(5, min(30, blink_rate))                   # Physiological range: 5-30 blinks/min
    
    # ==== AMBIENT NOISE (decibels) - OR environmental stressor ====
    # Baseline: 55-65 dB in typical OR, spikes during critical moments or equipment alarms
    # Correlates with stress and may contribute to cognitive load
    noise_baseline <- 60                                         # 60 dB baseline
    noise_task_related <- 8 * sin(t/30)                         # Task-related variation (±8 dB)
    noise_random_spike <- ifelse(runif(1) < 0.05, rnorm(1, 15, 5), 0)  # 5% chance of +15dB spike
    ambient_noise <- noise_baseline + noise_task_related + noise_random_spike + rnorm(1, 0, 2)
    ambient_noise <- max(45, min(85, ambient_noise))            # Range: 45-85 dB
    
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
      pupil_tepr = pupil_tepr,
      blink_rate = blink_rate,
      grip_force = grip_force,
      tremor_amplitude = tremor_amplitude,
      hrv_rmssd = hrv_rmssd,
      ambient_noise = ambient_noise,
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
      
      # Get error sources log entry if logging enabled (DISABLED - error_sources module disabled)
      # error_log_entry <- NULL
      # if (isTRUE(input$log_events)) {
      #   error_log_entry <- error_sources$get_log_entry()
      #   if (!is.null(error_log_entry)) {
      #     details_text <- paste0(details_text, " | ", format_error_log(error_log_entry))
      #   }
      # }
      
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
