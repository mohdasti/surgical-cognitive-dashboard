# Experimental Controls Integration Guide

This guide shows how to integrate the new experimental control paradigms into `app_working.R`.

## Files Created

1. `R/utils_thresholds.R` - Core threshold mapping functions
2. `R/mod_inverted_u_adjuster.R` - Inverted-U zone adjuster module
3. `R/mod_unified_sensitivity.R` - Unified sensitivity slider module
4. `R/mod_fatigue_adaptive.R` - Fatigue-adaptive thresholds module
5. `R/mod_controls_router.R` - Router to switch between control paradigms
6. `R/mod_experimental_controls_tab.R` - Top-level tab wrapper

## Integration Steps

### Step 1: Source the new modules

Add these lines near the top of `app_working.R` (after `library()` calls):

```r
# Source experimental control modules
source("../R/utils_thresholds.R")
source("../R/mod_inverted_u_adjuster.R")
source("../R/mod_unified_sensitivity.R")
source("../R/mod_fatigue_adaptive.R")
source("../R/mod_controls_router.R")
source("../R/mod_experimental_controls_tab.R")
```

### Step 2: Add the new tab to the UI

In the `ui <- navbarPage(...)` section, add a new tab:

```r
ui <- navbarPage(
  "🧠 Surgical Cognitive Dashboard",
  
  # ... existing tabs ...
  
  # Add this new tab
  tabPanel("🧪 Experimental Controls",
    mod_experimental_controls_tab_ui("exp_controls")
  ),
  
  # ... Model Performance tab ...
)
```

### Step 3: Add feature toggle to Control Panel

In the existing Control Panel wellPanel, add:

```r
wellPanel(
  h4("🎛️ Control Panel"),
  
  # Add this toggle at the top
  checkboxInput("use_experimental", "🧪 Use Experimental Controls", FALSE),
  helpText("When enabled, thresholds come from the Experimental Controls tab"),
  
  conditionalPanel(
    condition = "!input.use_experimental",
    # Existing controls
    checkboxInput("silent", "🔇 Silent mode", FALSE),
    checkboxInput("enable_logging", "📝 Enable logging", TRUE),
    hr(),
    h5("⚙️ Alert Thresholds"),
    sliderInput("theta_lapse", "🚨 Lapse threshold", 0, 1, 0.3, 0.01),
    sliderInput("theta_high", "⚠️ High-load threshold", 0, 1, 0.6, 0.01)
  ),
  
  # ... rest of controls ...
)
```

### Step 4: Wrap existing thresholds in reactive

In the `server` function, create a reactive for existing thresholds:

```r
server <- function(input, output, session) {
  # ... existing code ...
  
  # Wrap existing thresholds
  existing_thresholds <- reactive({
    list(
      high_load_threshold = input$theta_high,
      lapse_threshold = input$theta_lapse,
      source = "current"
    )
  })
  
  # Mount experimental controls module
  experimental <- mod_experimental_controls_tab_server(
    "exp_controls",
    cfg = list(
      current_time = reactive({ tail(realtime_data()$timestamp, 1) / 60 }),  # minutes
      # Optional: add custom bounds
      high_min = 0.40,
      high_max = 0.80,
      lapse_min = 0.70,
      lapse_max = 0.95
    ),
    existing_thresholds = existing_thresholds
  )
  
  # Create unified threshold adapter
  get_thresholds <- reactive({
    if (isTRUE(input$use_experimental)) {
      experimental$thresholds()
    } else {
      existing_thresholds()
    }
  })
  
  # ... rest of server code ...
}
```

### Step 5: Update classifier to use get_thresholds()

Find all places where `input$theta_lapse` and `input$theta_high` are used and replace with:

```r
# OLD:
final_state <- if (lapse_prob > input$theta_lapse) {
  "Attentional Lapse"
} else if (highload_prob > input$theta_high) {
  "High Load"
} else {
  "Normal"
}

# NEW:
thresh <- get_thresholds()
final_state <- if (lapse_prob > thresh$lapse_threshold) {
  "Attentional Lapse"
} else if (highload_prob > thresh$high_load_threshold) {
  "High Load"
} else {
  "Normal"
}
```

Do the same for:
- Line 230 (lapse probability card)
- Line 583 (state classification)
- Line 613 (alert log condition)
- Line 614-621 (alert details)

### Step 6: Optional - Add threshold display

Add a display panel to show active thresholds:

```r
# In UI, add to status row:
column(12,
  wellPanel(
    style = "background: #ecf0f1; padding: 10px; margin-top: 10px;",
    h5("📊 Active Thresholds"),
    fluidRow(
      column(3, textOutput("active_source_display")),
      column(3, textOutput("high_threshold_display")),
      column(3, textOutput("lapse_threshold_display")),
      column(3, textOutput("threshold_info"))
    )
  )
)

# In server:
output$active_source_display <- renderText({
  paste("Source:", get_thresholds()$source)
})

output$high_threshold_display <- renderText({
  sprintf("High Load: %.2f", get_thresholds()$high_load_threshold)
})

output$lapse_threshold_display <- renderText({
  sprintf("Lapse: %.2f", get_thresholds()$lapse_threshold)
})
```

## Testing Checklist

- [ ] App launches without errors
- [ ] Toggle between experimental and baseline controls
- [ ] Each experimental paradigm displays correctly
- [ ] Thresholds update in real-time when controls change
- [ ] Classifier responds to threshold changes
- [ ] Alert log reflects correct thresholds
- [ ] No errors in R console

## Advanced: Logging Threshold Changes

Add this observer to log threshold changes:

```r
# Log threshold changes for analysis
observe({
  if (isTRUE(input$use_experimental)) {
    thresh <- get_thresholds()
    extras <- experimental$extras()
    
    # Log to file or reactive value
    log_line <- data.frame(
      timestamp = Sys.time(),
      source = thresh$source,
      high_threshold = thresh$high_load_threshold,
      lapse_threshold = thresh$lapse_threshold,
      # Add source-specific data
      zone_left = ifelse(!is.null(extras$zone_bounds), extras$zone_bounds[1], NA),
      zone_right = ifelse(!is.null(extras$zone_bounds), extras$zone_bounds[2], NA),
      sensitivity = ifelse(!is.null(extras$sensitivity), extras$sensitivity, NA),
      stringsAsFactors = FALSE
    )
    
    # Append to log file
    # write.table(log_line, "data/logs/threshold_changes.csv", 
    #             append = TRUE, row.names = FALSE, col.names = !file.exists("..."))
  }
})
```

## Troubleshooting

### Issue: Modules not found
**Solution:** Ensure all `source()` paths are correct. If running from `shiny_app/`, use `../R/` prefix.

### Issue: Plotly not loading
**Solution:** Add `library(plotly)` at the top of `app_working.R`.

### Issue: Thresholds not updating
**Solution:** Check that `get_thresholds()` is used everywhere, not `input$theta_*`.

### Issue: Expert mode sliders don't respect constraints
**Solution:** Constraints are enforced in the `observeEvent` handlers. Check console for errors.

## Future Enhancements

1. **Preset Profiles**: Save/load threshold configurations
2. **Phase-Based Adaptation**: Different thresholds for different surgical phases
3. **Multi-Surgeon Profiles**: Per-surgeon baseline calibration
4. **Real-Time Recommendations**: Suggest optimal control paradigm based on procedure type
5. **A/B Testing Framework**: Compare performance across control paradigms

## References

- Adaptive Gain Theory: Aston-Jones & Cohen (2005)
- Inverted-U: Yerkes & Dodson (1908)
- Resource Competition: Kahneman (1973)

