# MSI Card Design Template

## 🎨 Design You Like - Reusable Pattern

The Motor Steadiness Index card uses a clean, compact design that can be applied to other biosignals.

---

## 📐 Card Structure

```
┌─ Title ────────────────────────[Status Badge]─┐
│                                                │
│  BIG NUMBER  /scale                            │
│                                                │
│  Component 1  ▁▂▃▄▅▆▇█ (sparkline)            │
│  Component 2  ▃▄▅▄▃▄▅▆ (sparkline)            │
│                                                │
│  ▸ Show Details                                │
│    └─ [Full Plot 1]                            │
│    └─ [Full Plot 2]                            │
└────────────────────────────────────────────────┘
```

---

## 🔧 HTML/CSS Template

### Basic Structure

```r
div(
  style = "background: white; border: 1px solid #e5e7eb; border-radius: 12px; 
           padding: 16px; height: 300px; display: flex; flex-direction: column;",
  
  # Header: Title + Status Badge
  div(
    style = "display: flex; align-items: center; justify-content: space-between; 
             margin-bottom: 12px;",
    tags$strong("Metric Name", style = "font-size: 1.1em;"),
    span(
      id = "status-pill",
      style = "padding: 0.2rem 0.6rem; border-radius: 999px; 
               font-size: 0.75rem; font-weight: 500; border: 1px solid #e5e7eb;"
    )
  ),
  
  # KPI: Big Number
  div(
    style = "display: flex; align-items: baseline; gap: 10px; margin-bottom: 16px;",
    tags$h2(textOutput("kpi_value", inline = TRUE), 
            style = "margin: 0; font-size: 2.5em; font-weight: 600;"),
    span("/scale", style = "color: #6b7280; font-size: 0.9em;")
  ),
  
  # Sparklines Section
  div(
    style = "flex: 1; overflow: hidden;",
    div(
      style = "display: grid; grid-template-columns: 90px 1fr; gap: 8px; 
               align-items: center; margin-bottom: 8px;",
      span("Component 1", style = "color: #6b7280; font-size: 0.85em; font-weight: 500;"),
      sparklineOutput("spark_1", width = "100%", height = "35px")
    ),
    div(
      style = "display: grid; grid-template-columns: 90px 1fr; gap: 8px; 
               align-items: center;",
      span("Component 2", style = "color: #6b7280; font-size: 0.85em; font-weight: 500;"),
      sparklineOutput("spark_2", width = "100%", height = "35px")
    )
  ),
  
  # Details Toggle
  tags$details(
    style = "margin-top: 12px; font-size: 0.85em;",
    tags$summary(
      style = "cursor: pointer; color: #1f9bb6; font-weight: 500;", 
      "Show Details"
    ),
    div(
      style = "margin-top: 12px; padding-top: 12px; border-top: 1px solid #e5e7eb; 
               max-height: 400px; overflow-y: auto;",
      div(style = "margin-bottom: 12px;",
        plotOutput("detail_plot_1", height = "160px")
      ),
      div(
        plotOutput("detail_plot_2", height = "160px")
      )
    )
  )
)
```

---

## 🎨 Color Scheme (MD Theme)

### Status Badge Colors

```r
# Status mapping
status_colors <- list(
  Normal    = "#27ae60",  # Green
  Elevated  = "#f39c12",  # Amber
  Critical  = "#e74c3c",  # Red
  Unknown   = "#6b7280"   # Gray
)

# Badge styling (JavaScript)
badge_style <- function(status, color) {
  sprintf("
    pill.textContent = '%s';
    pill.style.background = '%s20';  // 20% opacity
    pill.style.borderColor = '%s';
    pill.style.color = '%s';
  ", status, color, color, color)
}
```

### Sparkline Colors

```r
# Sparkline configurations
sparkline_config <- list(
  primary   = list(lineColor = "#e74c3c", lineWidth = 2),  # Red
  secondary = list(lineColor = "#f39c12", lineWidth = 2),  # Amber
  tertiary  = list(lineColor = "#3498db", lineWidth = 2)   # Blue
)

# Usage
sparkline(data, type = "line", 
          lineColor = sparkline_config$primary$lineColor,
          fillColor = FALSE, 
          lineWidth = sparkline_config$primary$lineWidth,
          width = "100%", 
          height = "35px")
```

---

## 📊 Example: Cognitive Load Index

Here's how to adapt this for a "Cognitive Load Index" combining pupil + HRV:

```r
# UI
div(
  style = "...",  # Same card styling
  
  # Header
  div(...,
    tags$strong("Cognitive Load Index"),
    span(id = "load-status-pill", ...)
  ),
  
  # KPI
  div(...,
    tags$h2(textOutput("load_index", inline = TRUE), ...),
    span("/100", ...)
  ),
  
  # Sparklines
  div(...,
    div(...,
      span("Pupil Dilation", ...),
      sparklineOutput("spark_pupil", ...)
    ),
    div(...,
      span("HRV Decrease", ...),
      sparklineOutput("spark_hrv_drop", ...)
    )
  ),
  
  # Details
  tags$details(...,
    plotOutput("pupil_detail_plot", ...),
    plotOutput("hrv_detail_plot", ...)
  )
)

# Server
output$load_index <- renderText({
  sprintf("%.0f", compute_load_index())
})

output$spark_pupil <- renderSparkline({
  sparkline(pupil_data(), type = "line", lineColor = "#3498db", ...)
})

# Status badge update
observe({
  status <- if (load > 70) "High Load" else if (load > 40) "Moderate" else "Normal"
  color <- if (load > 70) "#e74c3c" else if (load > 40) "#f39c12" else "#27ae60"
  js <- sprintf("
    const pill = document.getElementById('load-status-pill');
    if (pill) {
      pill.textContent = '%s';
      pill.style.background = '%s20';
      pill.style.borderColor = '%s';
      pill.style.color = '%s';
    }
  ", status, color, color, color)
  session$sendCustomMessage("evaljs", list(code = js))
})
```

---

## 🎯 Design Principles

### 1. **Hierarchy**
- **Big number first** - instant understanding
- **Status badge** - quick severity check
- **Sparklines** - trend at a glance
- **Details hidden** - reduce clutter

### 2. **Visual Consistency**
- **Fixed height** (300px) - predictable layout
- **White background** - clean separation
- **Rounded corners** (12px) - modern feel
- **Subtle borders** (#e5e7eb) - definition without heaviness

### 3. **Color Strategy**
- **Muted labels** (#6b7280) - don't compete with data
- **Bold KPI** - largest element, dark text
- **Status colors** - semantic (green/amber/red)
- **Sparkline colors** - distinct but harmonious

### 4. **Interaction**
- **Expandable details** - progressive disclosure
- **No unnecessary clicks** - key info always visible
- **Dynamic badge** - live status updates

---

## 📦 Ready-to-Use Cards

### Fatigue Index (Blink + Tremor Slope)

```r
# Composite: Blink rate increase + tremor drift
fatigue_index <- 0.5 * z(blink_rate) + 0.5 * z(tremor_slope)
```

### Arousal Index (Pupil Tonic + HRV LF/HF)

```r
# Composite: Tonic pupil level + LF/HF ratio
arousal_index <- 0.6 * z(pupil_tonic) + 0.4 * z(lf_hf_ratio)
```

### Precision Index (Grip Steadiness + Low Tremor)

```r
# Composite: Low grip CV + low tremor
precision_index <- -0.5 * z(grip_cv) - 0.5 * z(tremor_rms)
```

---

## 🔧 Sparkline Tips

### Data Windows
- **60-120 seconds** of history for sparklines
- **Update every 200ms** (5Hz) for smooth animation
- **Tail the last N samples**: `tail(data, 600)` for 2 min at 5Hz

### Visual Tuning
```r
sparkline(
  data,
  type = "line",
  lineColor = "#e74c3c",
  fillColor = FALSE,        # No area fill (cleaner)
  lineWidth = 2,            # Bold enough to see
  spotRadius = 0,           # No endpoint dots
  minSpotColor = FALSE,     # No min/max markers
  maxSpotColor = FALSE,
  spotColor = FALSE,
  width = "100%",
  height = "35px"           # Compact but readable
)
```

---

## 📋 Checklist for New Cards

- [ ] Define composite metric (weights, z-scores)
- [ ] Create status thresholds (Normal/Elevated/Critical)
- [ ] Choose sparkline colors (distinct from existing)
- [ ] Implement KPI reactive
- [ ] Implement sparkline reactives
- [ ] Add badge color update observer
- [ ] Create detail plots (optional, in `<details>`)
- [ ] Test with simulation data
- [ ] Document formula in help tooltip

---

## 🎨 Full Card Gallery (Future)

Potential cards using this design:

1. **Motor Steadiness Index** ✅ (Tremor + Grip CV)
2. **Cognitive Load Index** (Pupil + HRV)
3. **Fatigue Index** (Blink + Tremor Slope)
4. **Arousal Index** (Pupil Tonic + LF/HF)
5. **Precision Index** (Grip + Low Tremor)
6. **Attention Index** (Pupil Variance + Blink Regularity)

---

**This design pattern makes complex biosignals instantly understandable!** 🚀

