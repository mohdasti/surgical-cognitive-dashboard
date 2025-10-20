# DEMO Mode and Showcase Implementation

## Overview

This implementation provides a **DEMO mode** for lightweight testing and a **showcase script** that generates publication-ready screenshots using the exact same plotting code as the live app.

## Architecture

### Zero Code Duplication
All plotting logic is extracted into reusable functions:
- `R/plots_live_monitor.R` - Live monitor plots (TEPR+HRV, features)
- `R/plots_diagnostics.R` - Diagnostics plots (calibration, distributions, stability)

Both the Shiny app and showcase script use these **identical functions**.

## Files Created

### 1. Demo Data
```
inst/demo/demo_data_10min.csv (311K)
├─ 3000 rows (10 min at 5 Hz)
├─ Columns: time_s, time_min, cognitive_state
│           pupil_mm, rmssd_ms, grip_cv_pct, tremor_rms_um
└─ Self-contained, no heavy dependencies
```

### 2. Plotting Functions

**R/plots_live_monitor.R:**
- `plot_tepr_hrv_demo(data)` - TEPR + HRV 2-panel
- `plot_feat_by_state_demo(data)` - Feature comparison by state

**R/plots_diagnostics.R:**
- `plot_calibration_lapse_demo(p_hat, y, bins)` - Reliability diagram
- `plot_prob_dists_demo(data, bins)` - Probability distributions
- `plot_stability_lapse_demo(data)` - Stability 2-panel

### 3. Showcase Script

**scripts/render_showcase.R:**
- Generates 5 showcase images
- Uses demo data from `inst/demo/`
- Calls the same plotting functions as the app
- All images use `theme_md()` and MD color palette

## DEMO Mode Integration

### App Integration

```r
# In shiny_app/app_working.R (line 383)
DEMO_MODE <- isTRUE(getOption("surgdash.demo", FALSE)) || 
             identical(Sys.getenv("DEMO_MODE"), "1")

if (DEMO_MODE) {
  cat("🎬 Running in DEMO MODE\n")
  cat("  Using lightweight demo data from inst/demo/\n")
}
```

### Activation Methods

**Option 1: R Option**
```r
options(surgdash.demo = TRUE)
shiny::runApp("shiny_app/app_working.R")
```

**Option 2: Environment Variable**
```bash
DEMO_MODE=1 Rscript shiny_app/app_working.R
```

**Option 3: Showcase Script**
```bash
Rscript scripts/render_showcase.R  # Automatically sets demo mode
```

## Generated Showcase Assets

### Output Directory: `showcase/`

| File | Size | Dimensions | Description |
|------|------|------------|-------------|
| `live_tepr_hrv.png` | 113K | 1280×780 @ 144 DPI | TEPR + HRV time series |
| `feat_by_state.png` | 43K | 1280×780 @ 144 DPI | Feature comparison |
| `calibration_lapse.png` | 47K | 1000×760 @ 144 DPI | Reliability diagram |
| `prob_dists.png` | 39K | 800×1000 @ 144 DPI | Probability distributions |
| `stability_lapse.png` | 103K | 1280×780 @ 144 DPI | Prediction stability |

### Visual Consistency

✅ All plots use `theme_md()`  
✅ State colors via `scale_state_fill()`/`scale_state_color()`  
✅ MD color palette (accent, warn, muted)  
✅ Exact match with live app visuals  

## Usage Examples

### Generate Showcase Images

```bash
cd /path/to/surgical-cognitive-dashboard-1
Rscript scripts/render_showcase.R
```

Output:
```
🎬 Render Showcase Screenshots
================================
✓ Output directory: showcase/
📂 Loading demo data...
  ✓ Loaded 3000 rows (10.0 min at 5 Hz)
📈 Generating live_tepr_hrv.png...
  ✓ Saved showcase/live_tepr_hrv.png
...
✅ Showcase generation complete!
```

### Run App in Demo Mode

```r
# Set option before launching
options(surgdash.demo = TRUE)
shiny::runApp("shiny_app/app_working.R")
```

Or from terminal:
```bash
DEMO_MODE=1 Rscript -e "shiny::runApp('shiny_app/app_working.R')"
```

## Benefits

### 1. Zero Code Duplication
- Plotting functions defined once in `R/plots_*.R`
- Used by both app and screenshot script
- Single source of truth for visuals

### 2. Exact Visual Match
- Screenshots **guaranteed** to match live app
- Same theme, colors, fonts, layout
- No manual synchronization needed

### 3. Lightweight Testing
- Demo data is only 311K (vs full dataset)
- Fast startup for development/testing
- No heavy model loading required

### 4. Portfolio Ready
- High-resolution images (144 DPI)
- Consistent branding and styling
- Production-quality screenshots

## Key Features

✅ **DEMO_MODE flag** - Enable with option or env var  
✅ **Self-contained demo data** - No external dependencies  
✅ **Reusable plotting functions** - No code duplication  
✅ **Theme consistency** - All plots use `theme_md()`  
✅ **Color standardization** - MD palette throughout  
✅ **Production quality** - 144 DPI, proper sizing  

## Maintenance

To update showcase images:

1. **Update plotting functions** in `R/plots_*.R`
2. **Run showcase script**: `Rscript scripts/render_showcase.R`
3. **Images automatically updated** with exact app visuals

No need to manually recreate screenshots or keep code in sync!

---

**Last Updated:** October 18, 2025  
**Author:** Automated via Cursor AI  
**Status:** ✅ Production Ready
