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
      h4("🎛️ Control Source Selection", style = "margin-top: 0;"),
      p("Select which control paradigm should drive the cognitive state thresholds.", 
        style = "margin-bottom: 10px; opacity: 0.9;")
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
    
    # Dynamic UI for selected module
    uiOutput(ns("active_module_ui"))
  )
}

#' Server for Controls Router
#'
#' @param id Module namespace ID
#' @param cfg Configuration list
#' @param existing_thresholds Reactive returning current thresholds from baseline controls
#' @return List of reactives: active_source(), thresholds(), extras()
#' @export
mod_controls_router_server <- function(id, cfg = list(), existing_thresholds = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Initialize all experimental modules
    inverted_u <- mod_inverted_u_adjuster_server("inverted_u", cfg)
    sensitivity <- mod_unified_sensitivity_server("sensitivity", cfg)
    fatigue <- mod_fatigue_adaptive_server("fatigue", cfg)
    
    # Render appropriate UI based on selection
    output$active_module_ui <- renderUI({
      switch(input$control_source,
        "current" = div(
          style = "padding: 20px; background: #f8f9fa; border-radius: 8px;",
          h5("ℹ️ Using Baseline Controls"),
          p("The system is using the standard independent threshold sliders ",
            "from the main control panel. These controls allow independent ",
            "adjustment of High Load and Lapse thresholds."),
          p(strong("Note:"), " This mode does not enforce interdependent logic.")
        ),
        "inverted_u" = mod_inverted_u_adjuster_ui(ns("inverted_u")),
        "sensitivity" = mod_unified_sensitivity_ui(ns("sensitivity")),
        "fatigue" = mod_fatigue_adaptive_ui(ns("fatigue"))
      )
    })
    
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

