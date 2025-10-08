#' Guided Tour Module
#'
#' @description
#' 60-second interactive tour of the dashboard using cicerone.
#' Walks users through key features and cognitive neuroscience concepts.

#' Initialize Guided Tour
#'
#' @return Cicerone guide object
#' @export
create_guided_tour <- function() {
  guide <- cicerone::Cicerone$
    new()$
    step(
      el = "banner-mode_badge",
      title = "Welcome to the Surgical Cognitive Dashboard!",
      description = "This 60-second tour will show you how to monitor surgeon cognitive states in real-time. Let's start with the Mode Banner at the top."
    )$
    step(
      el = "banner-threshold_pill",
      title = "Threshold Source",
      description = "This pill shows which control paradigm is currently driving the classifier. It updates instantly when you switch between Baseline and Experimental controls."
    )$
    step(
      el = "main_navbar",
      title = "Three Operational Modes",
      description = "The dashboard has three main modes: Live Monitor (real-time HUD), Training Lab (experimental controls), and Diagnostics (model performance)."
    )$
    step(
      el = "status_card",
      title = "Current Cognitive State",
      description = "This card shows the surgeon's current cognitive state: Normal (green), High Load (yellow), or Attentional Lapse (red). It updates every 200ms (5 Hz)."
    )$
    step(
      el = "pupil_plot",
      title = "Biosignal Monitoring",
      description = "Real-time pupil diameter tracking. Pupil dilation indicates cognitive load based on Adaptive Gain Theory. Parameters are from 16 peer-reviewed studies."
    )$
    step(
      el = "state_prob_plot",
      title = "Cognitive State Distribution",
      description = "This stacked probability chart shows how the model distributes confidence across three states. The areas always sum to 100%."
    )$
    step(
      el = "use_experimental",
      title = "Experimental Controls Toggle",
      description = "Enable this to switch from baseline sliders to theory-driven experimental controls. This lets you explore different threshold paradigms."
    )$
    step(
      el = "main_navbar",
      title = "Training Lab",
      description = "Click 'Training Lab' to explore three experimental control paradigms: Inverted-U Zone Adjuster, Unified Sensitivity, and Fatigue-Adaptive Thresholds."
    )$
    step(
      el = "exp_controls-router-control_source",
      title = "Control Paradigm Selection",
      description = "Choose which control paradigm to use. Each is grounded in cognitive neuroscience theory and enforces interdependent threshold logic."
    )$
    step(
      el = "main_navbar",
      title = "Diagnostics",
      description = "The Diagnostics dropdown menu provides access to model performance metrics, calibration analysis, and feature importance (some tabs are placeholders for future expansion)."
    )$
    step(
      el = "compare-toggle_drawer",
      title = "Compare Thresholds",
      description = "Click this button to open a side-by-side comparison drawer. See how different threshold settings affect classification without changing the actual classifier."
    )$
    step(
      el = "banner-mode_badge",
      title = "Tour Complete!",
      description = "You're now ready to explore the dashboard. Try adjusting thresholds in the Training Lab and watch the effects in real-time. Enjoy!"
    )
  
  guide
}

#' Add Help Popovers to UI Elements
#'
#' @param element UI element to wrap with popover
#' @param title Popover title
#' @param content Popover content (HTML allowed)
#' @return UI element with popover
#' @export
add_help_popover <- function(element, title, content) {
  tagList(
    element,
    tags$sup(
      style = "margin-left: 5px; cursor: help;",
      tags$a(
        href = "#",
        onclick = "return false;",
        `data-toggle` = "popover",
        `data-trigger` = "hover",
        `data-placement` = "top",
        `data-html` = "true",
        `data-title` = title,
        `data-content` = content,
        icon("question-circle", style = "color: #3498db; font-size: 0.8em;")
      )
    )
  )
}

#' Theory Card Component
#'
#' @param id Unique ID for the card
#' @param title Card title
#' @param svg_path Path to SVG file (optional)
#' @param description Short description (2-3 lines)
#' @param expanded Whether card starts expanded
#' @return Collapsible theory card UI
#' @export
theory_card_ui <- function(id, title, svg_path = NULL, description, expanded = FALSE) {
  ns <- NS(id)
  
  div(
    class = "theory-card",
    style = "border: 1px solid #ddd; border-radius: 8px; margin-bottom: 15px; overflow: hidden;",
    
    # Header (clickable)
    div(
      id = paste0(id, "_header"),
      style = "background: linear-gradient(135deg, #ecf0f1 0%, #bdc3c7 100%); padding: 10px 15px; cursor: pointer; display: flex; justify-content: space-between; align-items: center;",
      onclick = sprintf("$('#%s_body').slideToggle();", id),
      
      h5(style = "margin: 0; color: #2c3e50;", icon("brain"), " ", title),
      icon("chevron-down", style = "color: #7f8c8d;")
    ),
    
    # Body (collapsible)
    div(
      id = paste0(id, "_body"),
      style = sprintf("padding: 15px; background: white; %s", 
                     if (!expanded) "display: none;" else ""),
      
      if (!is.null(svg_path)) {
        div(style = "text-align: center; margin-bottom: 10px;",
          tags$img(src = svg_path, style = "max-width: 200px; height: auto;")
        )
      },
      
      p(style = "margin: 0; font-size: 0.9em; line-height: 1.6; color: #555;",
        HTML(description))
    )
  )
}

#' Initialize Popovers (call in server)
#'
#' @export
init_popovers <- function(session) {
  shinyjs::runjs("
    $(function () {
      $('[data-toggle=\"popover\"]').popover({
        container: 'body',
        html: true
      });
    });
  ")
}
