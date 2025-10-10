# 🎉 Opacity Issue - RESOLVED

**Date**: October 10, 2025  
**Status**: ✅ FIXED  
**Commit**: `d1ea3d0`

---

## ✅ **Issues Resolved**

### 1. **Opacity/Fade Problem** ✅
**Symptom**: App appeared faded/opaque with semi-transparent overlay  
**Root Cause**: Shiny's `.recalculating` class applied to large containers at 5Hz  
**Solution**: Aggressive CSS override forcing `opacity: 1 !important`

### 2. **Panel Flickering** ✅  
**Symptom**: Countermeasure panel flickered rapidly on startup  
**Root Cause**: `observe()` reacting to initial `alert_active()` value  
**Solution**: `observeEvent(..., ignoreInit = TRUE)`

### 3. **Blank Header Space** ✅
**Symptom**: 60px blank space above navbar  
**Root Cause**: Padding for disabled banner module  
**Solution**: Removed `padding-top: 60px`

### 4. **Missing Citations** ✅
**Symptom**: "No citations available" for Normal state  
**Root Cause**: Empty `citations = c()` in optimal state data  
**Solution**: Added 5 peer-reviewed citations

---

## 🔧 **Technical Solutions Applied**

### **A. CSS Kill Switch** (Lines 94-98 in `app_working.R`)
```css
/* KILL OPACITY - Disable Shiny's recalculating fade */
body, .container-fluid, * { opacity: 1 !important; }
.recalculating { opacity: 1 !important; }
.recalculating::after { display: none !important; }
.shiny-busy { opacity: 1 !important; }
```

### **B. Anti-Flicker Event Handler** (`mod_error_sources.R`)
```r
observeEvent(alert_active(), {
  if (isTRUE(alert_active())) {
    shinyjs::show("error_panel_container")
  } else {
    shinyjs::hide("error_panel_container")
  }
}, ignoreNULL = TRUE, ignoreInit = TRUE)
```

### **C. Evidence Base Completion** 
Added citations for optimal state (5 studies):
- Csikszentmihalyi (1990) - Flow theory
- Yerkes & Dodson (1908) - Inverted-U
- Endsley (1995) - Situation awareness
- Moulton et al. (2010) - Expertise
- Yule et al. (2006) - Non-technical skills

**Total citations**: 17 peer-reviewed studies across all states

---

## 🧪 **Diagnostic Process**

### **What We Tried (That Didn't Work):**
1. ❌ Disabling Cicerone only
2. ❌ CSS hard resets in ui_theme.R
3. ❌ JavaScript opacity killers
4. ❌ Disabling individual modules
5. ❌ Replacing some renderUI (missed critical ones)
6. ❌ Debouncing reactive updates

### **What Actually Worked:**
1. ✅ **Isolation testing** - Created minimal app to prove concept
2. ✅ **Aggressive CSS** - `* { opacity: 1 !important; }`
3. ✅ **ignoreInit** - Prevent startup reactive storms

### **Key Insight:**
The `.recalculating` class is applied at element level, but when large containers have it, the fade appears global. The aggressive `* { opacity: 1 !important; }` overrides ALL opacity sources.

---

## 📊 **Current App State**

**URL**: http://127.0.0.1:4162  
**Branch**: main  
**Commit**: d1ea3d0

### **Working Features** ✅:
- Real-time biosignal monitoring (5 Hz updates)
- Cognitive state classification
- State probability charts
- Error sources & countermeasures (on alerts)
- Feature tables with literature references
- Alert logging
- Training Lab controls
- No opacity, no flickering

### **Known Issues** ⚠️:
- Biosignal plots take 60-90 seconds to fully populate (normal - accumulating data)
- Scenario preset buttons not responding (needs investigation)
- Help icon popovers disabled (to prevent conflicts)

### **Intentionally Disabled** ⏸️:
- Cicerone guided tour (causes overlay)
- Mode banner (incomplete dependencies)
- Compare drawer (incomplete)
- Always-visible countermeasure panel (shows on alerts only)

---

## 🚀 **Future Improvements**

### **If You Want Faster Plot Loading:**
1. Seed with initial data points (current: empty)
2. Reduce validation delay
3. Use `plotlyProxy()` for smoother updates

### **If You Want Always-Visible Countermeasures:**
Need to refactor the 5 `renderUI()` calls to static UI + `renderText()`:
- `current_state_badge`
- `error_mechanisms`
- `immediate_actions`
- `preventive_actions`
- `citations`

### **To Re-enable Features:**
1. Test each in isolation
2. Ensure no `renderUI()` at high frequency
3. Add CSS overrides if needed

---

## 📝 **Lessons Learned**

### **What Causes Opacity in Shiny:**
1. **High-frequency `renderUI()`** - Repaints large DOM structures
2. **`.recalculating` class** - Applied during output updates
3. **Cicerone/overlay libraries** - Create literal overlays
4. **Module errors** - Can leave app in busy state

### **How to Fix:**
1. **Replace `renderUI` with `renderText`** - Minimal DOM mutation
2. **Aggressive CSS overrides** - `* { opacity: 1 !important; }`
3. **Disable problematic modules** - Test incrementally
4. **Use isolation testing** - Minimal apps to prove concepts

### **How to Prevent:**
1. **Avoid `renderUI` for frequently-updating outputs**
2. **Use static UI + reactive text/values**
3. **Test in incognito mode** - Rules out browser extensions
4. **Monitor `.recalculating` class** - Use browser DevTools

---

## ✅ **Resolution Confirmation**

**Tested in**:
- ✅ Chrome (clear)
- ✅ Firefox (clear)
- ✅ Opera (clear)
- ✅ Incognito mode (clear)

**User Confirmation**: "the opacity is gone, for now!"

---

## 📖 **References**

- Shiny `.recalculating` behavior: https://rstudio.github.io/shiny/news/
- Busy indicators: https://shiny.posit.co/r/reference/shiny/latest/busyindicatoroptions.html
- Performance best practices: Avoid high-frequency `renderUI()`

---

**This document serves as the definitive record of how the opacity issue was identified, diagnosed, and resolved.** 🎓

