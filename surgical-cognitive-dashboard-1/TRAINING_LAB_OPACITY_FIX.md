# Training Lab Opacity Issue - Diagnosis & Fix Plan

**Date**: October 10, 2025  
**Status**: 🔍 ISOLATED  
**Commit**: `7e55bf4`

---

## ✅ **Confirmed via Isolation Testing**

**Test Results:**
- App WITHOUT Training Lab: ✅ CLEAR (stays clear even after data loads)
- App WITH Training Lab: ❌ OPAQUE (turns opaque when data populates)

**Conclusion**: One or more Training Lab modules cause opacity.

---

## 🔍 **Culprit Analysis**

### **Modules with renderUI** (Suspects):

1. **`mod_controls_router.R`** (line 61)
   - `output$active_module_ui <- renderUI({`
   - Switches between control paradigm UIs
   - Triggers on `input$control_source` changes
   - **HIGH SUSPICION**: Large UI swap via renderUI

2. **`mod_scenario_presets.R`** (line 396)
   - `output$diff_note <- renderUI({`
   - Shows preset comparison note
   - Triggers on `active_preset()` changes
   - **MEDIUM SUSPICION**: Small UI component

3. **`mod_experimental_controls_tab.R`**
   - Wraps the above modules
   - May have additional logic

---

## 🔧 **Solution Strategy**

### **Option A: Convert renderUI to conditionalPanel** (Preferred)

Replace the `renderUI` in `mod_controls_router.R` with static UI:

```r
# BEFORE (causes opacity):
output$active_module_ui <- renderUI({
  switch(input$control_source,
    "current" = div(...),
    "inverted_u" = mod_inverted_u_adjuster_ui(ns("inverted_u")),
    "sensitivity" = mod_unified_sensitivity_ui(ns("sensitivity")),
    "fatigue" = mod_fatigue_adaptive_ui(ns("fatigue"))
  )
})

# AFTER (no opacity):
# In UI:
div(
  conditionalPanel("input.control_source == 'current'", div(...)),
  conditionalPanel("input.control_source == 'inverted_u'", mod_inverted_u_adjuster_ui(...)),
  conditionalPanel("input.control_source == 'sensitivity'", mod_unified_sensitivity_ui(...)),
  conditionalPanel("input.control_source == 'fatigue'", mod_fatigue_adaptive_ui(...))
)

# In server: Remove the renderUI entirely
```

### **Option B: Apply CSS Override to Training Lab Only**

Scope the opacity fix to Training Lab tab:

```css
#training-lab-content .recalculating { opacity: 1 !important; }
```

### **Option C: Keep Training Lab Disabled**

Simple but loses functionality.

---

## 🎯 **Recommended Fix**

**Convert `mod_controls_router` renderUI to conditionalPanel:**

1. Modify `R/mod_controls_router.R`:
   - Remove `output$active_module_ui <- renderUI({...})`
   - Return static UI with conditionalPanels

2. Update `R/mod_experimental_controls_tab.R`:
   - Call the static UI function instead of `uiOutput`

3. Test that opacity stays gone

---

## ✅ **Current Stable State**

**What works**:
- ✅ Live Monitor (fully functional, no opacity)
- ✅ Diagnostics tab (working)
- ✅ All biosignal plots
- ✅ Status cards, alerts, features
- ⏸️ Training Lab (disabled to prevent opacity)

**Next action**: Fix Training Lab modules to eliminate renderUI

---

## 📊 **Complete Opacity Sources Eliminated**

| Source | Location | Solution | Status |
|--------|----------|----------|--------|
| `.recalculating` fade | Shiny core | CSS override | ✅ FIXED |
| DataTables modals | Ajax errors | server=FALSE + JS cleanup | ✅ FIXED |
| Error panel renderUI | 5 outputs | Hide by default | ✅ FIXED |
| Status cards renderUI | Live Monitor | Converted to renderText | ✅ FIXED |
| **Training Lab renderUI** | **controls_router** | **Disable for now** | 🔄 IN PROGRESS |

---

**Next Step**: Refactor `mod_controls_router` to eliminate renderUI while preserving functionality.

