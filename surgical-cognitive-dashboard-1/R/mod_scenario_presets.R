#' Scenario Presets Module - Training Lab Quick Setup
#'
#' @description
#' Provides one-click scenario configurations for common training situations.
#' Each preset atomically updates all control paradigms (Inverted-U, Sensitivity, Fatigue).
#'
#' @details
#' Presets are designed for surgical training and simulation contexts.

# ============================================================================
# PRESET DEFINITIONS
# ============================================================================

#' Scenario Preset Configurations
#' @export
SCENARIO_PRESETS <- list(
  novice = list(
    name = "👶 Novice",
    description = "Wide optimal zone, lenient thresholds, early fatigue onset",
    tooltip = "For trainees in first 10 cases. Allows more errors before alerting.",
    
    # Inverted-U parameters
    inverted_u = list(
      b_left = 0.25,   # Wide left boundary (more tolerance for low arousal)
      b_right = 0.75   # Wide right boundary (more tolerance for high arousal)
    ),
    
    # Sensitivity parameters
    sensitivity = 0.3,  # Lenient (30% strict)
    
    # Fatigue parameters
    fatigue = list(
      enabled = TRUE,
      t0 = 30,         # Fatigue starts at 30 min (early)
      t1 = 90,         # Full effect by 90 min
      f_shape = "linear",
      k_high = 0.10,   # Moderate gain for high load
      k_lapse = 0.15   # Higher gain for lapse (more sensitive to fatigue)
    ),
    
    rationale = "Novices have wider performance variability and fatigue faster. System is lenient to avoid overwhelming with alerts during learning phase."
  ),
  
  intermediate = list(
    name = "🎓 Intermediate",
    description = "Moderate optimal zone, balanced thresholds, standard fatigue",
    tooltip = "For residents with 10-50 cases. Balanced sensitivity.",
    
    inverted_u = list(
      b_left = 0.30,   # Standard boundaries
      b_right = 0.70
    ),
    
    sensitivity = 0.5,  # Balanced (50% strict)
    
    fatigue = list(
      enabled = TRUE,
      t0 = 60,         # Fatigue starts at 60 min (standard)
      t1 = 120,        # Full effect by 120 min
      f_shape = "linear",
      k_high = 0.08,
      k_lapse = 0.12
    ),
    
    rationale = "Intermediate surgeons have more consistent performance but still developing stamina. Standard monitoring parameters."
  ),
  
  expert = list(
    name = "⭐ Expert",
    description = "Narrow optimal zone, strict thresholds, late fatigue onset",
    tooltip = "For attendings with >50 cases. High performance expectations.",
    
    inverted_u = list(
      b_left = 0.35,   # Narrow boundaries (less tolerance)
      b_right = 0.65
    ),
    
    sensitivity = 0.7,  # Strict (70% strict)
    
    fatigue = list(
      enabled = TRUE,
      t0 = 90,         # Fatigue starts at 90 min (late)
      t1 = 150,        # Full effect by 150 min
      f_shape = "logistic",  # More sudden onset
      k_high = 0.06,
      k_lapse = 0.10
    ),
    
    rationale = "Experts maintain narrow performance bands and resist fatigue longer. System is strict to catch subtle degradation."
  ),
  
  long_case = list(
    name = "⏱️ Long Case",
    description = "Standard zone, moderate thresholds, aggressive fatigue tracking",
    tooltip = "For procedures >2 hours (e.g., complex oncologic cases).",
    
    inverted_u = list(
      b_left = 0.30,
      b_right = 0.70
    ),
    
    sensitivity = 0.5,  # Balanced
    
    fatigue = list(
      enabled = TRUE,
      t0 = 45,         # Early onset for long cases
      t1 = 120,
      f_shape = "logistic",  # Sudden fatigue cliff
      k_high = 0.12,   # Higher gains (fatigue is primary concern)
      k_lapse = 0.18
    ),
    
    rationale = "Long cases prioritize fatigue monitoring. System becomes more sensitive over time to catch cumulative effects."
  ),
  
  high_noise_or = list(
    name = "🔊 High-Noise OR",
    description = "Narrow zone, strict thresholds, standard fatigue",
    tooltip = "For teaching hospitals or high-distraction environments.",
    
    inverted_u = list(
      b_left = 0.32,   # Slightly narrower (distractions reduce optimal zone)
      b_right = 0.68
    ),
    
    sensitivity = 0.65,  # More strict (distractions increase error risk)
    
    fatigue = list(
      enabled = TRUE,
      t0 = 50,         # Slightly earlier (distractions accelerate fatigue)
      t1 = 110,
      f_shape = "linear",
      k_high = 0.10,
      k_lapse = 0.14
    ),
    
    rationale = "High-noise environments increase cognitive load and error risk. System is more sensitive to detect distraction-induced lapses."
  )
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Get Preset Configuration
#'
#' @param preset_name Name of preset (novice, intermediate, expert, long_case, high_noise_or)
#' @return List with preset configuration
#' @export
get_preset_config <- function(preset_name) {
  preset <- SCENARIO_PRESETS[[preset_name]]
  if (is.null(preset)) {
    stop(sprintf("Unknown preset: %s", preset_name))
  }
  preset
}

#' Format Preset Diff Note
#'
#' @param preset_name Name of applied preset
#' @param previous_preset Name of previous preset (optional)
#' @return HTML formatted diff note
#' @export
format_preset_diff <- function(preset_name, previous_preset = NULL) {
  preset <- get_preset_config(preset_name)
  
  # Base message
  msg <- sprintf("✅ <strong>Preset Applied:</strong> %s", preset$name)
  
  # Add key changes
  changes <- c()
  
  # Inverted-U change
  zone_width <- preset$inverted_u$b_right - preset$inverted_u$b_left
  zone_desc <- if (zone_width > 0.45) {
    "Wide optimal zone"
  } else if (zone_width > 0.35) {
    "Standard optimal zone"
  } else {
    "Narrow optimal zone"
  }
  changes <- c(changes, zone_desc)
  
  # Sensitivity change
  sens_desc <- if (preset$sensitivity < 0.4) {
    "Lenient sensitivity"
  } else if (preset$sensitivity < 0.6) {
    "Balanced sensitivity"
  } else {
    "Strict sensitivity"
  }
  changes <- c(changes, sens_desc)
  
  # Fatigue change
  if (preset$fatigue$enabled) {
    fatigue_desc <- sprintf(
      "Fatigue onset at %d min",
      preset$fatigue$t0
    )
    changes <- c(changes, fatigue_desc)
  } else {
    changes <- c(changes, "Fatigue disabled")
  }
  
  # Combine
  changes_text <- paste(changes, collapse = " | ")
  full_msg <- sprintf("%s<br><small style='color: #7f8c8d;'>%s</small>", msg, changes_text)
  
  HTML(full_msg)
}

#' Scenario Presets UI
#'
#' @param id Module namespace ID
#' @return Shiny UI element
#' @export
mod_scenario_presets_ui <- function(id) {
  ns <- NS(id)
  
  div(
    style = "background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%); 
             padding: 15px; 
             margin-bottom: 20px; 
             border-radius: 8px;
             border: 1px solid #dee2e6;",
    
    # Header
    div(
      style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;",
      h5(
        style = "margin: 0; color: #495057;",
        "🎯 Scenario Presets",
        tags$sup(
          style = "margin-left: 8px;",
          tags$a(
            href = "#",
            onclick = "return false;",
            id = ns("preset_help"),
            "❓",
            style = "text-decoration: none; font-size: 0.8em;"
          )
        )
      ),
      actionButton(
        ns("reset_preset"),
        "↺ Reset to Default",
        class = "btn-sm btn-outline-secondary"
      )
    ),
    
    # Preset buttons
    div(
      style = "display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 10px;",
      
      actionButton(
        ns("preset_novice"),
        HTML("👶<br>Novice"),
        class = "btn-primary btn-sm",
        style = "min-width: 100px; height: 60px;"
      ),
      
      actionButton(
        ns("preset_intermediate"),
        HTML("🎓<br>Intermediate"),
        class = "btn-info btn-sm",
        style = "min-width: 100px; height: 60px;"
      ),
      
      actionButton(
        ns("preset_expert"),
        HTML("⭐<br>Expert"),
        class = "btn-success btn-sm",
        style = "min-width: 100px; height: 60px;"
      ),
      
      actionButton(
        ns("preset_long_case"),
        HTML("⏱️<br>Long Case"),
        class = "btn-warning btn-sm",
        style = "min-width: 100px; height: 60px;"
      ),
      
      actionButton(
        ns("preset_high_noise"),
        HTML("🔊<br>High-Noise OR"),
        class = "btn-danger btn-sm",
        style = "min-width: 100px; height: 60px;"
      )
    ),
    
    # Diff note (hidden by default)
    div(
      id = ns("diff_note_container"),
      style = "display: none;",
      div(
        class = "alert alert-success",
        style = "margin: 0; padding: 10px; animation: fadeIn 0.3s;",
        uiOutput(ns("diff_note"))
      )
    ),
    
    # CSS for fade-in animation
    tags$style(HTML("
      @keyframes fadeIn {
        from { opacity: 0; transform: translateY(-10px); }
        to { opacity: 1; transform: translateY(0); }
      }
    "))
  )
}

#' Scenario Presets Server
#'
#' @param id Module namespace ID
#' @return List with reactive preset configuration
#' @export
mod_scenario_presets_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Track active preset
    active_preset <- reactiveVal(NULL)
    preset_config <- reactiveVal(NULL)
    
    # Initialize help popover
    observe({
      shinyjs::delay(500, {
        bsplus::bs_attach_popover(
          id = ns("preset_help"),
          title = "Scenario Presets",
          content = "One-click configurations for common training situations. Each preset adjusts all three control paradigms (Inverted-U, Sensitivity, Fatigue) atomically.",
          placement = "right",
          trigger = "hover"
        )
      })
    })
    
    # Apply preset function
    apply_preset <- function(preset_name) {
      config <- get_preset_config(preset_name)
      
      # Update reactive values
      active_preset(preset_name)
      preset_config(config)
      
      # Show diff note
      shinyjs::show("diff_note_container")
      
      # Auto-hide after 5 seconds
      shinyjs::delay(5000, {
        shinyjs::hide("diff_note_container")
      })
      
      # Show notification
      showNotification(
        sprintf("Applied preset: %s", config$name),
        type = "message",
        duration = 3
      )
    }
    
    # Preset button observers
    observeEvent(input$preset_novice, {
      apply_preset("novice")
    })
    
    observeEvent(input$preset_intermediate, {
      apply_preset("intermediate")
    })
    
    observeEvent(input$preset_expert, {
      apply_preset("expert")
    })
    
    observeEvent(input$preset_long_case, {
      apply_preset("long_case")
    })
    
    observeEvent(input$preset_high_noise, {
      apply_preset("high_noise_or")
    })
    
    # Reset button
    observeEvent(input$reset_preset, {
      active_preset(NULL)
      preset_config(NULL)
      shinyjs::hide("diff_note_container")
      showNotification(
        "Reset to manual control",
        type = "message",
        duration = 2
      )
    })
    
    # Diff note output
    output$diff_note <- renderUI({
      preset_name <- active_preset()
      if (is.null(preset_name)) return(NULL)
      
      format_preset_diff(preset_name)
    })
    
    # Return reactive configuration
    list(
      active_preset = active_preset,
      config = preset_config,
      
      # Helper to check if preset is active
      is_active = reactive({
        !is.null(active_preset())
      }),
      
      # Get specific parameter sets
      get_inverted_u_params = reactive({
        config <- preset_config()
        if (is.null(config)) return(NULL)
        config$inverted_u
      }),
      
      get_sensitivity_param = reactive({
        config <- preset_config()
        if (is.null(config)) return(NULL)
        config$sensitivity
      }),
      
      get_fatigue_params = reactive({
        config <- preset_config()
        if (is.null(config)) return(NULL)
        config$fatigue
      })
    )
  })
}
