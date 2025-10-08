#' UI Constants - Colors, Labels, and Tooltips
#'
#' @description
#' Centralized definitions for colors, labels, and help text.
#' Ensures consistency across all plots, badges, and UI elements.
#'
#' @details
#' Uses Okabe-Ito color palette for accessibility (colorblind-safe).
#' All UI elements should reference these constants to prevent taxonomy drift.

# ============================================================================
# COLOR PALETTE (Okabe-Ito - Colorblind Safe)
# ============================================================================

#' Cognitive State Colors
#' @export
COLORS <- list(
  # Primary cognitive states
  optimal = "#009E73",      # Green - Normal/Optimal state
  high_load = "#E69F00",    # Amber - High cognitive load
  lapse = "#D55E00",        # Red-Orange - Attentional lapse
  fatigue = "#0072B2",      # Blue - Fatigue indicator
  
  # UI elements
  background_dark = "#2c3e50",
  background_light = "#ecf0f1",
  text_primary = "#2c3e50",
  text_secondary = "#7f8c8d",
  text_muted = "#95a5a6",
  
  # Threshold sources
  baseline = "#95a5a6",     # Gray - Baseline controls
  inverted_u = "#E67E22",   # Orange - Inverted-U
  sensitivity = "#3498DB",  # Blue - Sensitivity
  fatigue_adaptive = "#E74C3C", # Red - Fatigue-adaptive
  
  # Alerts and status
  success = "#27ae60",
  warning = "#f39c12",
  danger = "#e74c3c",
  info = "#3498db"
)

# ============================================================================
# STATE LABELS (Canonical Names)
# ============================================================================

#' Cognitive State Labels
#' @export
LABELS <- list(
  # Primary states
  optimal = "Optimal",
  normal = "Normal",  # Alias for optimal
  high_load = "High Load",
  lapse = "Attentional Lapse",
  fatigue = "Fatigued",
  
  # Alert types
  alert_lapse = "🚨 LAPSE",
  alert_high = "⚠️ HIGH LOAD",
  alert_normal = "✅ NORMAL",
  
  # Threshold sources
  source_baseline = "Baseline Sliders",
  source_inverted_u = "Inverted-U Zones",
  source_sensitivity = "Unified Sensitivity",
  source_fatigue = "Fatigue-Adaptive",
  source_fatigue_disabled = "Fatigue (Disabled)"
)

# ============================================================================
# TOOLTIPS AND HELP TEXT
# ============================================================================

#' Help Text and Tooltips
#' @export
TOOLTIPS <- list(
  # Cognitive states
  optimal = "Normal cognitive state with stable biosignals and optimal performance. The surgeon is operating within their comfort zone.",
  
  high_load = "Elevated cognitive demand. The surgeon is working hard but performance remains good. This is the productive effort zone on the inverted-U curve.",
  
  lapse = "Attentional lapse detected. Biosignals indicate potential inattention or cognitive overload. This state warrants immediate attention.",
  
  fatigue = "Cognitive fatigue accumulating over time-on-task. Performance may degrade due to resource depletion.",
  
  # Biosignals
  pupil = "Pupil diameter reflects arousal via the LC-NE system. Dilation indicates cognitive load; constriction may indicate inattention.",
  
  grip = "Grip force variability measures motor control steadiness. Increased variability suggests attentional lapses or fatigue.",
  
  tremor = "Instrument tremor at 8-12 Hz. Amplitude increases with stress and fatigue. Physiological tremor is normal; excessive tremor indicates overload.",
  
  # Theories
  agt = "Adaptive Gain Theory: The brain's LC-NE arousal system adjusts neural gain like a 'volume knob.' Optimal arousal enhances performance; excessive arousal causes dysregulation.",
  
  inverted_u = "The inverted-U relationship: Performance is optimal at moderate arousal levels and degrades when arousal is too low (inattention) or too high (overload).",
  
  resource_competition = "Resource Competition Theory: Physical and cognitive tasks compete for finite mental resources. Sustained effort depletes these resources over time.",
  
  # Controls
  threshold_baseline = "Independent sliders for High Load and Lapse thresholds. Allows flexible adjustment but doesn't enforce theoretical constraints.",
  
  threshold_inverted_u = "Visual manipulation of arousal-performance zones. Enforces interdependent logic based on the inverted-U curve.",
  
  threshold_sensitivity = "Single slider that intelligently adjusts both thresholds together. Strict = more alerts, Lenient = fewer alerts.",
  
  threshold_fatigue = "Time-based threshold adaptation. System becomes more sensitive as time-on-task increases to account for cognitive fatigue."
)

# ============================================================================
# ICONS
# ============================================================================

#' State Icons
#' @export
ICONS <- list(
  optimal = "✅",
  high_load = "⚠️",
  lapse = "🚨",
  fatigue = "⏱️",
  
  # UI elements
  help = "❓",
  info = "ℹ️",
  warning = "⚠️",
  error = "❌",
  success = "✓"
)

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Get Color for Cognitive State
#'
#' @param state State name (optimal, high_load, lapse, normal)
#' @return Hex color code
#' @export
get_state_color <- function(state) {
  state_lower <- tolower(gsub(" ", "_", state))
  
  # Map common variations
  color <- switch(
    state_lower,
    "optimal" = COLORS$optimal,
    "normal" = COLORS$optimal,
    "high_load" = COLORS$high_load,
    "high load" = COLORS$high_load,
    "attentional_lapse" = COLORS$lapse,
    "attentional lapse" = COLORS$lapse,
    "lapse" = COLORS$lapse,
    "fatigued" = COLORS$fatigue,
    "fatigue" = COLORS$fatigue,
    COLORS$text_muted  # Default
  )
  
  color
}

#' Get Icon for Cognitive State
#'
#' @param state State name
#' @return Icon character
#' @export
get_state_icon <- function(state) {
  state_lower <- tolower(gsub(" ", "_", state))
  
  icon <- switch(
    state_lower,
    "optimal" = ICONS$optimal,
    "normal" = ICONS$optimal,
    "high_load" = ICONS$high_load,
    "high load" = ICONS$high_load,
    "attentional_lapse" = ICONS$lapse,
    "attentional lapse" = ICONS$lapse,
    "lapse" = ICONS$lapse,
    "fatigued" = ICONS$fatigue,
    "fatigue" = ICONS$fatigue,
    ICONS$help  # Default
  )
  
  icon
}

#' Get Label for Cognitive State
#'
#' @param state State name (any variation)
#' @return Canonical label
#' @export
get_state_label <- function(state) {
  state_lower <- tolower(gsub(" ", "_", state))
  
  label <- switch(
    state_lower,
    "optimal" = LABELS$optimal,
    "normal" = LABELS$normal,
    "high_load" = LABELS$high_load,
    "high load" = LABELS$high_load,
    "attentional_lapse" = LABELS$lapse,
    "attentional lapse" = LABELS$lapse,
    "lapse" = LABELS$lapse,
    "fatigued" = LABELS$fatigue,
    "fatigue" = LABELS$fatigue,
    state  # Return as-is if not recognized
  )
  
  label
}

#' Create Styled State Badge
#'
#' @param state State name
#' @param include_icon Whether to include icon
#' @return HTML span with styled badge
#' @export
create_state_badge <- function(state, include_icon = TRUE) {
  color <- get_state_color(state)
  label <- get_state_label(state)
  icon <- if (include_icon) paste0(get_state_icon(state), " ") else ""
  
  tags$span(
    style = sprintf(
      "background: %s; color: white; padding: 4px 12px; border-radius: 12px; font-weight: bold; display: inline-block;",
      color
    ),
    HTML(paste0(icon, label))
  )
}

#' Get RGBA Color with Alpha
#'
#' @param color Hex color code
#' @param alpha Alpha value (0-1)
#' @return RGBA color string
#' @export
rgba <- function(color, alpha = 0.8) {
  # Convert hex to RGB
  rgb_vals <- col2rgb(color)
  sprintf("rgba(%d, %d, %d, %.2f)", 
          rgb_vals[1], rgb_vals[2], rgb_vals[3], alpha)
}
