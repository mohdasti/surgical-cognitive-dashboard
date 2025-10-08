#' Experimental Controls Tab Module
#'
#' @description
#' Top-level tab that presents all experimental control paradigms
#' with educational context.

#' UI for Experimental Controls Tab
#'
#' @param id Module namespace ID
#' @return Shiny UI element
#' @export
mod_experimental_controls_tab_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      column(12,
        div(
          style = "background: linear-gradient(135deg, #34495e 0%, #2c3e50 100%); color: white; padding: 20px; border-radius: 10px; margin-bottom: 20px;",
          h2("🧪 Experimental Control Panels", style = "margin-top: 0; color: white; font-weight: 600;"),
          p(style = "font-size: 1.1em; line-height: 1.6; color: rgba(255, 255, 255, 0.95);",
            "Welcome to the experimental control interface. This tab showcases three ",
            "alternative paradigms for setting cognitive state thresholds, each grounded ",
            "in cognitive neuroscience theory."
          ),
          tags$ul(
            style = "font-size: 0.95em; line-height: 1.8; color: rgba(255, 255, 255, 0.95);",
            tags$li(tags$strong(style = "color: white;", "Inverted-U Zone Adjuster:"), 
                    " Visualizes the arousal-performance relationship with draggable zone boundaries"),
            tags$li(tags$strong(style = "color: white;", "Unified Sensitivity Slider:"), 
                    " Single control that intelligently adjusts both thresholds together"),
            tags$li(tags$strong(style = "color: white;", "Fatigue-Adaptive Thresholds:"), 
                    " Time-based adaptation that accounts for cognitive fatigue accumulation")
          ),
          p(style = "font-size: 0.9em; color: rgba(255, 255, 255, 0.85); margin-bottom: 0;",
            "💡 These controls enforce ", em(style = "color: white;", "interdependent logic"), 
            " — the system prevents illogical threshold configurations ",
            "that would violate the theoretical progression of cognitive states."
          )
        )
      )
    ),
    
    fluidRow(
      column(12,
        wellPanel(
          h4("📚 Theoretical Background"),
          p("These experimental controls are implementations of key theories in cognitive neuroscience:"),
          fluidRow(
            column(4,
              div(style = "padding: 15px; background: #ecf0f1; border-radius: 8px; height: 100%;",
                h5("🧠 Adaptive Gain Theory (AGT)"),
                p(style = "font-size: 0.9em;",
                  "The brain's LC-NE arousal system acts like a 'volume knob,' ",
                  "adjusting neural gain to enhance signals. Optimal arousal improves ",
                  "performance; excessive arousal causes dysregulation.")
              )
            ),
            column(4,
              div(style = "padding: 15px; background: #ecf0f1; border-radius: 8px; height: 100%;",
                h5("📊 Inverted-U Relationship"),
                p(style = "font-size: 0.9em;",
                  "Performance is optimal at moderate arousal levels and degrades ",
                  "when arousal is too low (inattention) or too high (overload). ",
                  "This creates a predictable, non-linear relationship.")
              )
            ),
            column(4,
              div(style = "padding: 15px; background: #ecf0f1; border-radius: 8px; height: 100%;",
                h5("⏱️ Resource Competition Theory"),
                p(style = "font-size: 0.9em;",
                  "Physical and cognitive tasks compete for finite mental resources. ",
                  "Over time, sustained effort depletes these resources, necessitating ",
                  "adaptive threshold adjustment.")
              )
            )
          )
        )
      )
    ),
    
    fluidRow(
      column(12,
        # Scenario presets bar
        mod_scenario_presets_ui(ns("presets")),
        
        # Controls router
        mod_controls_router_ui(ns("router"))
      )
    )
  )
}

#' Server for Experimental Controls Tab
#'
#' @param id Module namespace ID
#' @param cfg Configuration list
#' @param existing_thresholds Reactive returning current baseline thresholds
#' @return List of reactives from router (active_source, thresholds, extras)
#' @export
mod_experimental_controls_tab_server <- function(id, cfg = list(), existing_thresholds = NULL) {
  moduleServer(id, function(input, output, session) {
    # Mount scenario presets module
    presets <- mod_scenario_presets_server("presets")
    
    # Wire through to router with preset overrides
    router <- mod_controls_router_server(
      "router",
      cfg = cfg,
      existing_thresholds = existing_thresholds,
      preset_overrides = presets  # Pass preset configuration
    )
    
    # Return router's interface plus preset info
    list(
      active_source = router$active_source,
      thresholds = router$thresholds,
      extras = router$extras,
      preset_active = presets$is_active,
      preset_name = presets$active_preset
    )
  })
}

