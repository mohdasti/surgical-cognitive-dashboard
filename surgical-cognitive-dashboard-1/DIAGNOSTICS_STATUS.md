# ML Model Diagnostics - Current Status

**Date**: October 10, 2025  
**App**: `shiny_app/app_working.R`  
**Status**: ✅ App Running on http://localhost:4162

---

## 📊 Section Status Summary

| Section | Priority | Status | Implementation |
|---------|----------|--------|----------------|
| 🎯 Threshold Sandbox | HIGH | ❌ Placeholder | Coming Soon message only |
| 📊 Probability Calibration | HIGH | ✅ **WORKING** | Simulated calibration plot + confusion matrix |
| 📋 Model Overview | MEDIUM | ✅ **WORKING** | Simulated LOSO bar chart + PR curve |
| 🔄 Cross-Validation Results | MEDIUM | ❌ Placeholder | Coming Soon message only |
| ⚖️ Feature Importance | MEDIUM | ❌ Placeholder | Coming Soon message only |
| 📈 Partial Dependence | LOW | ❌ Placeholder | Coming Soon message only |

**Working**: 2 out of 6 sections (33%)  
**Placeholders**: 4 sections need real implementation

---

## ✅ **What Currently Works**

### 1. **📊 Probability Calibration** (HIGH Priority)
**Status**: ✅ Fully Functional  
**Location**: Lines 415-430, 782-810 in `app_working.R`

**Features**:
- ✅ Calibration Plot - Perfect calibration line vs observed
- ✅ Confusion Matrix - 3×3 heatmap (Normal, High Load, Lapse)
- ✅ Uses simulated data (normal distribution around expected values)

**Implementation**:
```r
output$calibration_plot <- renderPlotly({
  expected <- seq(0, 1, 0.1)
  observed <- expected + rnorm(length(expected), 0, 0.05)
  # Perfect calibration line + noisy observations
})

output$confusion_matrix <- renderPlotly({
  categories <- c("Normal", "High Load", "Attentional Lapse")
  values <- c(45, 8, 2, 5, 12, 3, 1, 2, 8)
  # 3×3 heatmap
})
```

---

### 2. **📋 Model Overview** (MEDIUM Priority)
**Status**: ✅ Fully Functional  
**Location**: Lines 432-447, 758-780 in `app_working.R`

**Features**:
- ✅ LOSO Performance Bar Chart - 8 surgeons, PR-AUC values 0.75-0.92
- ✅ Precision-Recall Curve - Simulated curve for lapse detection
- ✅ Uses realistic simulated values

**Implementation**:
```r
output$performance_metrics <- renderPlotly({
  surgeons <- paste0("Surgeon_", LETTERS[1:8])
  pr_auc <- c(0.85, 0.78, 0.92, 0.81, 0.88, 0.75, 0.89, 0.83)
  # Bar chart
})

output$pr_curves <- renderPlotly({
  recall <- seq(0, 1, 0.1)
  precision <- 0.8 + 0.2 * recall - 0.1 * recall^2
  # PR curve
})
```

---

## ❌ **What Needs Implementation**

### 1. **🎯 Threshold Sandbox** (HIGH Priority) ⚠️
**Status**: ❌ Placeholder Only  
**Location**: Lines 398-413 in `app_working.R`

**Current**: Just a "Coming Soon" message

**What It Should Have**:
- Interactive sliders for threshold tuning
- Live precision/recall/F1 curves vs threshold
- Confusion matrix that updates with threshold changes
- ROC curves with adjustable operating point
- Cost-sensitive decision analysis

**Why It's Important**: HIGH priority - directly informs alert configuration

---

### 2. **🔄 Cross-Validation Results** (MEDIUM Priority)
**Status**: ❌ Placeholder Only  
**Location**: Lines 449-464 in `app_working.R`

**Current**: Just a "Coming Soon" message

**What It Should Have**:
- Per-surgeon holdout performance table
- Confusion matrices for each fold
- PR-AUC curves across surgeons
- Feature stability analysis

**Data Available**: `data/diagnostics/loso_eval.rds` exists in the project

---

### 3. **⚖️ Feature Importance** (MEDIUM Priority)
**Status**: ❌ Placeholder Only  
**Location**: Lines 466-481 in `app_working.R`

**Current**: Just a "Coming Soon" message

**What It Should Have**:
- XGBoost gain/cover/frequency importance bar charts
- SHAP summary plots (beeswarm)
- Per-class feature contributions
- Feature interaction effects

**Data Available**: `data/diagnostics/model_artifacts.rds` likely contains feature importance

---

### 4. **📈 Partial Dependence** (LOW Priority)
**Status**: ❌ Placeholder Only  
**Location**: Lines 483-498 in `app_working.R`

**Current**: Just a "Coming Soon" message

**What It Should Have**:
- PD plots for all engineered features
- ICE (Individual Conditional Expectation) curves
- 2D interaction plots
- Feature effect summaries

---

## 📂 **Available Data Files**

These files exist in `data/diagnostics/` and may contain real data:

```
data/diagnostics/
├── calibration.rds          # Could contain real calibration data
├── loso_eval.rds            # LOSO cross-validation results
├── model_artifacts.rds      # Feature importance, hyperparameters
└── threshold_sandbox.rds    # Threshold sweep results
```

**Question**: Should we load REAL data from these `.rds` files, or keep simulated data?

---

## 🔧 **Recommendations**

### **Priority 1: Threshold Sandbox (HIGH)**
This is marked HIGH priority and is critical for alert configuration. Should implement:
1. Load `threshold_sandbox.rds` (if it has real data)
2. Create interactive sliders for both thresholds
3. Show precision/recall/F1 curves
4. Update confusion matrix in real-time

### **Priority 2: Use Real Data (if available)**
Currently using simulated data for the 2 working sections. Should we:
1. Check if `.rds` files contain real LOSO results
2. Replace simulated data with actual model diagnostics
3. Add data validation checks

### **Priority 3: Complete Remaining Sections**
- Cross-Validation (MEDIUM) - likely has real data in `loso_eval.rds`
- Feature Importance (MEDIUM) - XGBoost provides this automatically
- Partial Dependence (LOW) - can be computed from model

---

## 🎯 **Next Steps**

1. **Verify**: Check if the 2 working sections display correctly in the dashboard
2. **Decide**: Real data vs simulated data?
3. **Implement**: Start with Threshold Sandbox (HIGH priority)
4. **Test**: Ensure no opacity issues from new visualizations

**Would you like me to**:
- ✅ Check what's in the `.rds` diagnostic files?
- ✅ Implement the Threshold Sandbox (HIGH priority)?
- ✅ Replace simulated data with real data (if available)?
- ✅ Add more visualizations to existing sections?

Let me know which direction you'd like to go!
