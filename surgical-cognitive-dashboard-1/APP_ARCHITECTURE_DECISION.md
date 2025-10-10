# App Architecture Decision - October 10, 2025

## 🎯 **Decision: Split Into Two Separate Apps**

### **Rationale:**
- **Live Monitor** will be embedded in Quarto website or shown as GIFs
- **Training Lab** is for researchers exploring control paradigms
- Separating them eliminates Training Lab opacity issues
- Each app can be optimized for its specific use case

---

## 📊 **App 1: Live Monitor (Production)**

**File**: `shiny_app/app_working.R`  
**Purpose**: Real-time surgical cognitive monitoring  
**Status**: ✅ WORKING PERFECTLY

### **Features:**
- Real-time biosignal monitoring (5 Hz)
  - Pupil diameter
  - Grip force
  - Tremor amplitude
  - State probabilities
- Cognitive state classification
- Status cards (Current Status, Lapse %, Performance)
- Error sources & countermeasures (on alerts)
- Alert logging
- Feature table with literature references
- Threshold sliders (basic controls)

### **For:**
- Clinical demonstrations
- Embedding in papers/websites
- Screen recordings/GIFs
- Real-time monitoring scenarios

### **Technical:**
- ✅ No renderUI (all textOutput/renderPlotly)
- ✅ No opacity issues
- ✅ Clean, fast loading
- ✅ Production-ready

---

## 🧪 **App 2: Training Lab (Research Tool)**

**File**: `shiny_app/app_training_lab.R` (to be created)  
**Purpose**: Explore threshold control paradigms  
**Status**: 🔄 TO BE CREATED

### **Features:**
- All Live Monitor features (base functionality)
- 🎯 Scenario Presets
  - Routine Procedure
  - Emergency Response
  - Learning Curve
  - Fatigue Accumulation
- 🎛️ Control Paradigms
  - Inverted-U Zone Adjuster (with visualization)
  - Unified Sensitivity Slider (with threshold viz)
  - Fatigue-Adaptive Thresholds (with timeline plot)
- 📊 Compare Threshold Drawer
  - Side-by-side comparison
  - What-if analysis
- 🎓 Guided Tour
- 📚 Mode Banner

### **For:**
- Researchers exploring control strategies
- Training surgical teams
- Validating threshold approaches
- Comparing paradigms

### **Technical:**
- Can use renderUI/renderPlot freely
- Opacity is acceptable in research context
- Or: Apply more aggressive CSS specifically here
- Not embedded, so performance less critical

---

## 🏗️ **Implementation Plan**

### **Phase 1: Finalize Live Monitor** ✅ DONE
- [x] Eliminate all opacity sources
- [x] Fix DataTables warnings
- [x] Remove Training Lab references
- [x] Test thoroughly
- [x] Document stable state

### **Phase 2: Create Training Lab App** 🔄 NEXT
1. Copy `app_working.R` → `app_training_lab.R`
2. Re-enable all Training Lab modules
3. Add back experimental controls
4. Apply Training Lab-specific CSS overrides
5. Test independently
6. Document usage

### **Phase 3: Documentation & Deployment** 📝
1. Update README with two app descriptions
2. Create separate embedding instructions
3. Add GIF recording guides
4. Deployment scripts for each app

---

## 📂 **File Structure**

```
shiny_app/
├── app_working.R          # LIVE MONITOR (production, embed-ready)
├── app_training_lab.R     # TRAINING LAB (research tool) [TO CREATE]
├── app.R                  # Original simple version
├── test_minimal.R         # Diagnostic tool
└── www/                   # Shared assets
    └── (CSS, JS if needed)
```

---

## ✅ **Benefits of This Architecture**

### **Live Monitor:**
- ✅ Fast, lightweight
- ✅ No opacity issues
- ✅ Embed-friendly
- ✅ GIF-ready
- ✅ Production stable

### **Training Lab:**
- ✅ Full functionality
- ✅ All visualizations
- ✅ Can tolerate renderUI/renderPlot
- ✅ Independent development
- ✅ Research-focused

### **Overall:**
- ✅ Separation of concerns
- ✅ Each optimized for its purpose
- ✅ No compromises needed
- ✅ Easier maintenance

---

## 🚀 **Current Stable State**

**Commit**: `dbd2632`  
**App**: Live Monitor only  
**Status**: Production-ready ✅

**Working features:**
- All core monitoring functionality
- No opacity at any time
- No errors or warnings
- Clean, professional interface
- Ready for embedding/screenshots

---

## 📋 **Next Steps**

1. ✅ **Use Live Monitor for embedding** - It's ready now!
2. 🔄 **Create Training Lab later** - When needed for research
3. 📝 **Update documentation** - Describe two-app architecture

---

**This architectural decision solves the opacity issue permanently while preserving all functionality!** 🎉

