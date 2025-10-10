#' Controls Router Module
#'
#' @description
#' Central hub for switching between different threshold control paradigms.
#' Provides a unified interface regardless of which control panel is active.

#' UI for Controls Router
#'
#' @param id Module namespace ID
#' @return Shiny UI element
#' @export
mod_controls_router_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    wellPanel(
      style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 15px;",
      h4("🎛️ Control Source Selection", style = "margin-top: 0; color: white; font-weight: 600;"),
      p("Select which control paradigm should drive the cognitive state thresholds.", 
        style = "margin-bottom: 10px; color: rgba(255, 255, 255, 0.95);")
    ),
    
    radioButtons(
      ns("control_source"),
      label = "Active Control Paradigm:",
      choices = c(
        "Current (Baseline - Independent Sliders)" = "current",
        "Inverted-U Zone Adjuster" = "inverted_u",
        "Unified Sensitivity Slider" = "sensitivity",
        "Fatigue-Adaptive Thresholds" = "fatigue"
      ),
      selected = "current",
      width = "100%"
    ),
    
    hr(),
    
    # Static UI with conditionalPanel (replaces renderUI to prevent opacity)
    conditionalPanel(
      condition = "input.control_source == 'current'",
      ns = ns,
      div(
        style = "padding: 20px; background: #f8f9fa; border-radius: 8px;",
        h5("ℹ️ Using Baseline Controls"),
        p("The system is using the standard independent threshold sliders ",
          "from the main control panel. These controls allow independent ",
          "adjustment of High Load and Lapse thresholds."),
        p(strong("Note:"), " This mode does not enforce interdependent logic.")
      )
    ),
    
    conditionalPanel(
      condition = "input.control_source == 'inverted_u'",
      ns = ns,
      mod_inverted_u_adjuster_ui(ns("inverted_u"))
    ),
    
    conditionalPanel(
      condition = "input.control_source == 'sensitivity'",
      ns = ns,
      mod_unified_sensitivity_ui(ns("sensitivity"))
    ),
    
    conditionalPanel(
      condition = "input.control_source == 'fatigue'",
      ns = ns,
      mod_fatigue_adaptive_ui(ns("fatigue"))
    )
  )
}

#' Server for Controls Router
#'
#' @param id Module namespace ID
#' @param cfg Configuration list
#' @param existing_thresholds Reactive returning current thresholds from baseline controls
#' @param preset_overrides Reactive list from scenario presets module (optional)
#' @return List of reactives: active_source(), thresholds(), extras()
#' @export
mod_controls_router_server <- function(id, cfg = list(), existing_thresholds = NULL, preset_overrides = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Initialize all experimental modules
    inverted_u <- mod_inverted_u_adjuster_server("inverted_u", cfg)
    sensitivity <- mod_unified_sensitivity_server("sensitivity", cfg)
    fatigue <- mod_fatigue_adaptive_server("fatigue", cfg)
    
    # renderUI REMOVED - now using conditionalPanel in UI (prevents opacity)
    # UI switching is handled by conditionalPanel in mod_controls_router_ui()
    
    # Route thresholds based on active source
    thresholds_routed <- reactive({
      source <- input$control_source
      
      if (source == "current") {
        # Use existing thresholds from baseline controls
        if (!is.null(existing_thresholds) && is.reactive(existing_thresholds)) {
          existing_thresholds()
        } else {
          # Fallback if not provided
          list(
            high_load_threshold = 0.60,
            lapse_threshold = 0.85,
            source = "current_fallback"
          )
        }
      } else if (source == "inverted_u") {
        inverted_u$thresholds()
      } else if (source == "sensitivity") {
        sensitivity$thresholds()
      } else if (source == "fatigue") {
        fatigue$thresholds()
      } else {
        # Default fallback
        list(
          high_load_threshold = 0.60,
          lapse_threshold = 0.85,
          source = "error_fallback"
        )
      }
    })
    
    # Collect extras for logging
    extras_reactive <- reactive({
      source <- input$control_source
      
      extras <- list(
        timestamp = Sys.time(),
        source = source
      )
      
      if (source == "inverted_u") {
        extras$zone_bounds <- inverted_u$zone_bounds()
      } else if (source == "sensitivity") {
        extras$sensitivity <- sensitivity$sensitivity()
      } else if (source == "fatigue") {
        extras$profile <- fatigue$profile()
      }
      
      extras
    })
    
    # Return unified interface
    list(
      active_source = reactive({ input$control_source }),
      thresholds = thresholds_routed,
      extras = extras_reactive
    )
  })
}

