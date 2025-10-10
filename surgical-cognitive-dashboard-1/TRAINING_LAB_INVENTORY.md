# Training Lab - Complete Code Inventory & Restoration Guide

**Status**: ✅ ALL CODE PRESERVED  
**Date**: October 10, 2025

---

## 📂 **All Training Lab Files (Preserved in Repository)**

### **Core Modules** (in `/R/` directory):

1. **`mod_experimental_controls_tab.R`** (4.9 KB)
   - Main container for Training Lab
   - Wraps all sub-modules
   - Commit: `336a588`

2. **`mod_controls_router.R`** (4.8 KB)  
   - Radio button selector for control paradigms
   - Routes between Baseline/Inverted-U/Sensitivity/Fatigue
   - **Recently refactored**: renderUI → conditionalPanel
   - Commit: `04b705e`

3. **`mod_inverted_u_adjuster.R`** (7.3 KB)
   - Interactive inverted-U curve editor
   - Zone-based threshold setting
   - Includes `renderPlotly` for curve visualization
   - Commit: `0b20e6e`

4. **`mod_unified_sensitivity.R`** (5.2 KB)
   - Single slider controlling both thresholds
   - Strict ↔ Lenient scale
   - Includes `renderPlot` for threshold visualization
   - Commit: `0b20e6e`

5. **`mod_fatigue_adaptive.R`** (7.8 KB)
   - Time-on-task based threshold adaptation
   - Fatigue profiles (Linear, Exponential, Step)
   - Includes `renderPlot` for timeline visualization
   - Commit: `0b20e6e`

6. **`mod_scenario_presets.R`** (12 KB)
   - Pre-configured scenarios (Routine, Emergency, Learning, Fatigue)
   - One-click threshold configuration
   - Includes `renderUI` for diff notes
   - Commit: `d27a1d2`

7. **`threshold_adapter.R`** (utils)
   - Single source of truth for threshold routing
   - Commit: `336a588`

8. **`utils_thresholds.R`** (helper functions)
   - Threshold calculation utilities

---

### **Supporting Modules** (also preserved):

9. **`mod_compare_drawer.R`** (16 KB)
   - Side-by-side threshold comparison
   - What-if analysis
   - Includes renderPlotly
   - Commit: `a41ec26`

10. **`mod_guided_tour.R`** (5.7 KB)
    - 60-second interactive tour
    - Uses Cicerone library
    - Commit: `2ac812a`

11. **`ui_banner.R`**
    - Mode indicator banner
    - Shows active threshold source
    - Has renderUI

12. **`mod_diagnostics_progressive.R`** (16 KB)
    - Progressive disclosure for ML diagnostics
    - Accordion-style interface
    - Currently enabled in app

---

## 📜 **Complete Feature Set (Preserved)**

### **Control Paradigms:**
1. ✅ **Baseline** - Independent threshold sliders
2. ✅ **Inverted-U** - Zone-based adjustment with curve visualization
3. ✅ **Unified Sensitivity** - Single slider (Strict ↔ Lenient)
4. ✅ **Fatigue-Adaptive** - Time-based adaptation with profiles

### **Scenario Presets:**
- ✅ Routine Procedure
- ✅ Emergency Response
- ✅ Learning Curve (New Surgeon)
- ✅ Fatigue Accumulation

### **Visualization & Analysis:**
- ✅ Inverted-U curve (interactive)
- ✅ Threshold timeline plots
- ✅ Sensitivity visualization
- ✅ Compare drawer (side-by-side)
- ✅ Scenario diff notes

### **Documentation:**
- ✅ Inline help text
- ✅ Theory explanations
- ✅ Guided tour script
- ✅ 17 peer-reviewed citations

---

## 🔄 **How to Restore Training Lab**

### **Option 1: In Current App (with opacity)** ⚠️

In `shiny_app/app_working.R`:

```r
# Line 261: Uncomment the Training Lab tab
tabPanel("🧪 Training Lab",
  tab_subtitle("Explore alternative threshold control strategies..."),
  mod_experimental_controls_tab_ui("exp_controls")
),

# Line 302: Uncomment the server mount
experimental <- mod_experimental_controls_tab_server(
  "exp_controls",
  cfg = list(
    current_time = reactive({ 
      data <- realtime_data()
      if (nrow(data) > 0) tail(data$timestamp, 1) / 60 else 0
    }),
    high_min = 0.40, high_max = 0.80,
    lapse_min = 0.70, lapse_max = 0.95
  ),
  existing_thresholds = reactive({
    list(
      high_load_threshold = input$theta_high,
      lapse_threshold = input$theta_lapse,
      source = "current"
    )
  })
)

# Line 331: Update threshold adapter
threshold_adapter <- create_threshold_adapter(input, experimental)
```

**Note**: This WILL cause opacity when data loads (renderPlot issue).

---

### **Option 2: Create Separate Training Lab App** ✅ RECOMMENDED

Create `shiny_app/app_training_lab.R`:

1. **Copy base from** `app_working.R`
2. **Uncomment** all Training Lab code
3. **Add** this CSS at the top:
```css
/* Training Lab-specific: Accept some opacity for visualizations */
.recalculating { opacity: 0.85 !important; }  /* Slight fade OK */
```
4. **Run separately** on different port (e.g., 4163)

---

### **Option 3: Git Branch with Full Features**

Create a branch with everything enabled:
```bash
git checkout -b training-lab-full
# Uncomment Training Lab in app_working.R
git commit -m "Full feature branch with Training Lab"
```

Switch branches as needed:
- `main` - Production (no opacity)
- `training-lab-full` - Research (with opacity but all features)

---

## 📦 **Training Lab Code Backup**

### **If You Want a Standalone Backup:**

I can create `shiny_app/app_training_lab_BACKUP.R` right now with:
- All modules enabled
- All features activated
- Full Training Lab functionality
- Documented with "will have opacity" warning

This gives you a complete working version you can reference or use later.

---

## 🔍 **Git History**

Training Lab was developed across these commits:
- `336a588` - Threshold adapter (central routing)
- `0b20e6e` - Cognitive controls implementation
- `a41ec26` - Compare drawer
- `2ac812a` - Guided tour
- `d27a1d2` - Scenario presets
- `622ed79` - Progressive disclosure diagnostics
- `1cd9983` - Typography improvements

**All commits are in git history** and can be cherry-picked or referenced.

---

## ✅ **Nothing is Lost!**

- ✅ All module files exist in `R/` directory
- ✅ All commits in git history
- ✅ All features documented
- ✅ Can be restored at any time

**Would you like me to:**
1. Create `app_training_lab.R` with all features enabled?
2. Create a git branch with full features?
3. Just leave it as documentation (current state)?

The code is safe - we can always bring it back! 🔒
