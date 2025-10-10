#' Error Sources Module - Human Error Mechanisms & Countermeasures
#'
#' @description
#' Maps cognitive states to likely human error mechanisms and provides
#' evidence-based countermeasures for surgical teams.
#'
#' @details
#' Based on Reason's Human Error Model (1990) and SEIPS 2.0 framework.
#' Provides actionable recommendations tied to cognitive neuroscience.

# ============================================================================
# ERROR TAXONOMY (Reason, 1990; Norman, 1988)
# ============================================================================

#' Error Mechanisms by Cognitive State
#' @export
ERROR_MECHANISMS <- list(
  lapse = list(
    label = "Attentional Lapse",
    error_types = c(
      "Slips: Correct intention, incorrect execution",
      "Omissions: Forgetting critical steps",
      "Capture errors: Reverting to habitual actions",
      "Description errors: Confusing similar objects/steps"
    ),
    mechanisms = c(
      "Reduced working memory capacity",
      "Decreased vigilance and sustained attention",
      "Impaired prospective memory (remembering to do X)",
      "Weakened executive control over automatic processes"
    ),
    examples = c(
      "Skipping a safety check",
      "Forgetting to remove a sponge",
      "Using wrong instrument (habitual choice)",
      "Misidentifying anatomical structures"
    ),
    citations = c(
      "Reason, J. (1990). Human Error. Cambridge University Press.",
      "Gawande et al. (2003). Analysis of errors in surgery. Surgery, 133(6), 614-621.",
      "Catchpole et al. (2007). Patient handover from surgery to ICU. BMJ Quality & Safety, 16(6), 387-394."
    )
  ),
  
  high_load = list(
    label = "High Cognitive Load",
    error_types = c(
      "Mistakes: Incorrect planning or decision-making",
      "Mis-sequencing: Steps performed out of order",
      "Tunnel vision: Missing peripheral cues",
      "Communication breakdowns: Team coordination failures"
    ),
    mechanisms = c(
      "Working memory overload (>7±2 items)",
      "Reduced situational awareness",
      "Impaired decision-making under pressure",
      "Decreased ability to integrate information"
    ),
    examples = c(
      "Choosing suboptimal surgical approach",
      "Performing steps in wrong order",
      "Missing bleeding from secondary site",
      "Failing to communicate critical info to team"
    ),
    citations = c(
      "Sweller, J. (1988). Cognitive load during problem solving. Cognitive Science, 12(2), 257-285.",
      "Yurko et al. (2010). Higher mental workload is associated with poorer performance. American Journal of Surgery, 199(4), 566-571.",
      "Arora et al. (2010). Mental practice enhances surgical skills. Annals of Surgery, 253(2), 265-270."
    )
  ),
  
  optimal = list(
    label = "Optimal State",
    error_types = c(
      "Minimal error risk",
      "Vigilance maintained",
      "Good situational awareness"
    ),
    mechanisms = c(
      "Balanced arousal (inverted-U peak)",
      "Adequate cognitive resources",
      "Effective executive control"
    ),
    examples = c(
      "Smooth procedure progression",
      "Proactive problem anticipation",
      "Effective team communication"
    ),
    citations = c(
      "Csikszentmihalyi, M. (1990). Flow: The Psychology of Optimal Experience. Harper & Row.",
      "Yerkes, R.M., & Dodson, J.D. (1908). The relation of strength of stimulus to rapidity of habit-formation. Journal of Comparative Neurology and Psychology, 18, 459-482.",
      "Endsley, M.R. (1995). Toward a theory of situation awareness in dynamic systems. Human Factors, 37(1), 32-64."
    )
  )
)

# ============================================================================
# COUNTERMEASURES (Evidence-Based)
# ============================================================================

#' Countermeasures by Error Type
#' @export
COUNTERMEASURES <- list(
  lapse = list(
    immediate = c(
      "🛑 Pause & Reset: 30-second micro-break to restore attention",
      "✅ Checklist Review: Verify critical steps not omitted",
      "👥 Team Cross-Check: Ask assistant to verify next 2-3 steps",
      "🔊 Verbalize Intent: Speak actions aloud to engage working memory"
    ),
    preventive = c(
      "⏸️ Scheduled Breaks: 5-min break every 60-90 minutes",
      "🎯 Pre-Step Verification: \"What am I about to do?\" before each action",
      "📋 Cognitive Aids: Use visual checklists for multi-step sequences",
      "💧 Hydration & Glucose: Maintain physiological homeostasis"
    ),
    citations = c(
      "Taffinder et al. (1998). Effect of sleep deprivation on surgeons' dexterity. Lancet, 352(9135), 1191.",
      "Haynes et al. (2009). Surgical safety checklist reduces complications. NEJM, 360(5), 491-499.",
      "Gaba et al. (1994). Crisis management in anesthesiology. Churchill Livingstone."
    )
  ),
  
  high_load = list(
    immediate = c(
      "🐌 Slow Down: Reduce camera/instrument speed by 30%",
      "🗣️ Verbalize Plan: State next 3 steps aloud to team",
      "👁️ Widen View: Zoom out to restore situational awareness",
      "🤝 Delegate: Offload non-critical tasks to assistant"
    ),
    preventive = c(
      "📝 Pre-Op Planning: Mental rehearsal of complex steps",
      "🎮 Simulation Training: Practice high-load scenarios",
      "🧘 Stress Inoculation: Breathing exercises (4-7-8 technique)",
      "📊 Workload Monitoring: Real-time feedback (this dashboard!)"
    ),
    citations = c(
      "Arora et al. (2011). Stress impairs psychomotor performance. Annals of Surgery, 253(4), 805-812.",
      "Wetzel et al. (2011). The effects of stress on surgical performance. American Journal of Surgery, 201(1), 101-107.",
      "Moorthy et al. (2003). Objective assessment of technical skills. BMJ, 327(7422), 1032-1037."
    )
  ),
  
  optimal = list(
    immediate = c(
      "✅ Maintain Current State: Continue current approach",
      "🎯 Stay Vigilant: Don't become complacent",
      "📢 Communicate: Keep team informed of status"
    ),
    preventive = c(
      "🔄 Sustain Practices: Continue effective strategies",
      "📊 Monitor Trends: Watch for early warning signs",
      "🎓 Reflect: Note what's working for future cases"
    ),
    citations = c(
      "Moulton et al. (2010). Slowing down when you should: Expertise and surgical performance. Annals of Surgery, 252(1), 223-226.",
      "Yule et al. (2006). Surgeons' non-technical skills in the operating room. Annals of Surgery, 244(1), 139-148."
    )
  )
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Get Error Mechanisms for State
#'
#' @param state Cognitive state (lapse, high_load, optimal)
#' @return List with error types, mechanisms, examples, citations
#' @export
get_error_mechanisms <- function(state) {
  state_lower <- tolower(gsub(" ", "_", state))
  
  # Map variations
  mechanisms <- switch(
    state_lower,
    "attentional_lapse" = ERROR_MECHANISMS$lapse,
    "attentional lapse" = ERROR_MECHANISMS$lapse,
    "lapse" = ERROR_MECHANISMS$lapse,
    "high_load" = ERROR_MECHANISMS$high_load,
    "high load" = ERROR_MECHANISMS$high_load,
    "high cognitive load" = ERROR_MECHANISMS$high_load,
    "optimal" = ERROR_MECHANISMS$optimal,
    "normal" = ERROR_MECHANISMS$optimal,
    ERROR_MECHANISMS$optimal  # Default
  )
  
  mechanisms
}

#' Get Countermeasures for State
#'
#' @param state Cognitive state
#' @return List with immediate and preventive countermeasures
#' @export
get_countermeasures <- function(state) {
  state_lower <- tolower(gsub(" ", "_", state))
  
  countermeasures <- switch(
    state_lower,
    "attentional_lapse" = COUNTERMEASURES$lapse,
    "attentional lapse" = COUNTERMEASURES$lapse,
    "lapse" = COUNTERMEASURES$lapse,
    "high_load" = COUNTERMEASURES$high_load,
    "high load" = COUNTERMEASURES$high_load,
    "high cognitive load" = COUNTERMEASURES$high_load,
    "optimal" = COUNTERMEASURES$optimal,
    "normal" = COUNTERMEASURES$optimal,
    COUNTERMEASURES$optimal  # Default
  )
  
  countermeasures
}

#' Create Error Sources Panel UI
#'
#' @param id Module namespace ID
#' @return Shiny UI element
#' @export
mod_error_sources_ui <- function(id) {
  ns <- NS(id)
  
  div(
    id = ns("error_panel_container"),
    style = "display: block; transition: opacity 0.3s ease;",  # Always visible for testing
    
    div(
      class = "error-sources-panel",
      style = "background: linear-gradient(135deg, #fff5f5 0%, #ffe5e5 100%); 
               border-left: 4px solid #e74c3c; 
               padding: 15px; 
               margin: 10px 0; 
               border-radius: 8px;
               box-shadow: 0 2px 8px rgba(231, 76, 60, 0.15);",
      
      # Header with collapse toggle
      div(
        style = "display: flex; justify-content: space-between; align-items: center; cursor: pointer;",
        onclick = sprintf("Shiny.setInputValue('%s', Math.random())", ns("toggle_collapse")),
        
        h4(
          style = "margin: 0; color: #c0392b; font-weight: bold;",
          "⚠️ Error Risk Analysis & Countermeasures"
        ),
        
        tags$span(
          id = ns("collapse_icon"),
          style = "font-size: 20px; color: #c0392b;",
          "▼"
        )
      ),
      
      # Collapsible content
      div(
        id = ns("error_content"),
        style = "margin-top: 15px;",
        
        # Current state indicator
        div(
          style = "background: white; padding: 10px; border-radius: 6px; margin-bottom: 15px;",
          strong("Detected State: "),
          uiOutput(ns("current_state_badge"), inline = TRUE)
        ),
        
        # Error mechanisms
        div(
          style = "background: white; padding: 12px; border-radius: 6px; margin-bottom: 15px;",
          h5(style = "margin-top: 0; color: #e74c3c;", "🧠 Likely Error Mechanisms"),
          uiOutput(ns("error_mechanisms"))
        ),
        
        # Immediate countermeasures
        div(
          style = "background: #e8f8f5; padding: 12px; border-radius: 6px; margin-bottom: 15px; border-left: 3px solid #27ae60;",
          h5(style = "margin-top: 0; color: #27ae60;", "⚡ Immediate Actions"),
          uiOutput(ns("immediate_actions"))
        ),
        
        # Preventive countermeasures
        div(
          style = "background: #ebf5fb; padding: 12px; border-radius: 6px; margin-bottom: 10px; border-left: 3px solid #3498db;",
          h5(style = "margin-top: 0; color: #3498db;", "🛡️ Preventive Strategies"),
          uiOutput(ns("preventive_actions"))
        ),
        
        # Citations (collapsible)
        tags$details(
          style = "margin-top: 10px; font-size: 0.9em;",
          tags$summary(
            style = "cursor: pointer; color: #7f8c8d; font-weight: bold;",
            "📚 Evidence Base"
          ),
          uiOutput(ns("citations"))
        )
      )
    )
  )
}

#' Error Sources Panel Server
#'
#' @param id Module namespace ID
#' @param current_state Reactive returning current cognitive state
#' @param alert_active Reactive returning TRUE when alert is active
#' @return List with logging data
#' @export
mod_error_sources_server <- function(id, current_state, alert_active) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Track collapse state
    collapsed <- reactiveVal(FALSE)
    
    observeEvent(input$toggle_collapse, {
      collapsed(!collapsed())
      
      # Toggle icon and content visibility
      shinyjs::toggle("error_content")
      
      if (collapsed()) {
        shinyjs::html("collapse_icon", "▶")
      } else {
        shinyjs::html("collapse_icon", "▼")
      }
    })
    
    # Show/hide panel based on alert status
    # DISABLED FOR TESTING - Panel is always visible now
    # observe({
    #   if (alert_active()) {
    #     shinyjs::show("error_panel_container")
    #   } else {
    #     shinyjs::hide("error_panel_container")
    #   }
    # })
    
    # Current state badge
    output$current_state_badge <- renderUI({
      state <- current_state()
      create_state_badge(state, include_icon = TRUE)
    })
    
    # Error mechanisms
    output$error_mechanisms <- renderUI({
      state <- current_state()
      mechanisms <- get_error_mechanisms(state)
      
      tagList(
        tags$ul(
          style = "margin: 5px 0; padding-left: 20px;",
          lapply(mechanisms$error_types, function(err) {
            tags$li(style = "margin: 5px 0;", err)
          })
        ),
        
        if (length(mechanisms$examples) > 0) {
          tagList(
            tags$strong("Examples in Surgery:"),
            tags$ul(
              style = "margin: 5px 0; padding-left: 20px; color: #7f8c8d; font-size: 0.95em;",
              lapply(mechanisms$examples, function(ex) {
                tags$li(style = "margin: 3px 0;", ex)
              })
            )
          )
        }
      )
    })
    
    # Immediate actions
    output$immediate_actions <- renderUI({
      state <- current_state()
      countermeasures <- get_countermeasures(state)
      
      tags$ul(
        style = "margin: 5px 0; padding-left: 20px; font-weight: 500;",
        lapply(countermeasures$immediate, function(action) {
          tags$li(style = "margin: 8px 0;", action)
        })
      )
    })
    
    # Preventive actions
    output$preventive_actions <- renderUI({
      state <- current_state()
      countermeasures <- get_countermeasures(state)
      
      tags$ul(
        style = "margin: 5px 0; padding-left: 20px;",
        lapply(countermeasures$preventive, function(action) {
          tags$li(style = "margin: 8px 0;", action)
        })
      )
    })
    
    # Citations
    output$citations <- renderUI({
      state <- current_state()
      mechanisms <- get_error_mechanisms(state)
      countermeasures <- get_countermeasures(state)
      
      all_citations <- unique(c(mechanisms$citations, countermeasures$citations))
      
      if (length(all_citations) == 0) {
        return(tags$p(style = "color: #95a5a6; font-style: italic;", "No citations available."))
      }
      
      tags$ol(
        style = "margin: 10px 0; padding-left: 20px; color: #7f8c8d;",
        lapply(all_citations, function(cite) {
          tags$li(style = "margin: 5px 0;", cite)
        })
      )
    })
    
    # Return logging data
    list(
      get_log_entry = reactive({
        if (!alert_active()) return(NULL)
        
        state <- current_state()
        mechanisms <- get_error_mechanisms(state)
        countermeasures <- get_countermeasures(state)
        
        list(
          state = state,
          error_types = paste(mechanisms$error_types, collapse = "; "),
          immediate_actions = paste(countermeasures$immediate, collapse = "; "),
          preventive_actions = paste(countermeasures$preventive, collapse = "; ")
        )
      })
    )
  })
}

#' Format Error Log Entry
#'
#' @param log_entry List from mod_error_sources_server
#' @return Character string for CSV logging
#' @export
format_error_log <- function(log_entry) {
  if (is.null(log_entry)) return("")
  
  sprintf(
    "State: %s | Errors: %s | Actions: %s",
    log_entry$state,
    substr(log_entry$error_types, 1, 100),  # Truncate for readability
    substr(log_entry$immediate_actions, 1, 100)
  )
}
