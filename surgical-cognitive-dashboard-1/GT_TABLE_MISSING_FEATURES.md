# GT Table - Missing Features Analysis

## Current Status: ✅ Working with 9 Features

Your GT table is successfully showing:

### ✅ Currently Included (9 features)

| Feature | Source | Status |
|---------|--------|--------|
| Pupil Diameter | Live simulation | ✅ Working |
| Grip Force | Live simulation | ✅ Working |
| Tremor RMS (8–12Hz) | Live simulation | ✅ Working |
| HRV (RMSSD) | **Placeholder** | ⚠️ Static (40ms) |
| Grip CV% | Derived from grip | ✅ Working |
| Time-on-Task | Derived from time | ✅ Working |
| Normal Prob | Model prediction | ✅ Working |
| High Load Prob | Model prediction | ✅ Working |
| Lapse Prob | Model prediction | ✅ Working |

---

## ❌ Missing from Live Simulation (5 features)

These features exist in the **full offline pipeline** (`scripts/02_feature_engineering.R`) but are **NOT** in the live simulation:

### 1. **Blink Rate** 🔴 High Priority
```r
blink_rate_60s = Rsum(blink, CFG$windows$blink_rate_s)
```

**Why it matters:**
- Strong indicator of cognitive load (Marquart et al. 2015)
- Blink rate decreases under high workload
- Increases during fatigue/inattention
- Easy to add to simulation

**Literature support:** Yes - well-documented in surgical literature

---

### 2. **Phasic Pupil Change** 🟡 Medium Priority
```r
phasic_pupil_change_5s = pupil_diameter_mm - local_baseline
```

**Why it matters:**
- Task-evoked pupillary response (TEPR)
- Distinguishes tonic (arousal) from phasic (task load)
- More specific than raw pupil diameter
- You're already showing TEPR in the current simulation comments

**Literature support:** Yes - Wu et al. 2019 extensively discusses phasic vs tonic

**Note:** Your simulation already computes this (line 1210: `pupil_tepr`) but doesn't show it separately in the table!

---

### 3. **Tool Switch Rate** 🟡 Medium Priority
```r
tool_switch_rate_120s = Rsum(tool_switch, CFG$windows$tool_switch_rate_s)
```

**Why it matters:**
- Workflow efficiency indicator
- High switch rate = disorganization/hesitation
- Surgical performance metric
- Would need tool state in simulation

**Literature support:** Limited - more of an operational metric

---

### 4. **Ambient Noise** 🟢 Low Priority
```r
noise_mean_60s = Rmean(ambient_noise_db, CFG$windows$noise_rate_s)
noise_spike_count_60s = Rsum(noise_spike, CFG$windows$noise_rate_s)
```

**Why it matters:**
- Environmental stressor
- OR noise levels affect performance
- Interesting contextual factor
- Low priority for cognitive monitoring

**Literature support:** Some - OR acoustics studies

---

### 5. **Heart Rate Variability (Real)** 🔴 High Priority
```r
# Currently: hrv_rmssd_ms <- 40  # Placeholder
```

**Why it matters:**
- Gold standard for autonomic nervous system activity
- Strong cognitive load indicator (De Louche et al. 2024)
- Your table shows it but with static placeholder value
- Should be derived from simulated heart rate

**Literature support:** Extensive - multiple surgical studies

**Current issue:** Line 862-863 in app_working.R:
```r
# Note: HRV not in simulation yet, using placeholder
hrv_rmssd_ms <- 40  # Placeholder until HRV added to simulation
```

---

## 🎯 Recommendations

### Quick Wins (High Impact, Low Effort)

#### 1. **Show Phasic Pupil Response**
You're **already computing this** but not showing it!

```r
# In app_working.R around line 1210, you have:
pupil_tepr <- 0.30 * exp(-((t %% 60) - 15)^2 / (2 * 1.2^2))

# Add to features_reactive:
Feature = c(..., "Phasic Pupil (TEPR)", ...),
Value = c(..., pupil_tepr, ...),  # or extract from current calculation
Unit = c(..., "mm", ...)
```

**Benefit:** Shows task-evoked response separately from baseline pupil size. More interpretable!

---

#### 2. **Add Blink Rate Simulation**
```r
# In simulation loop (around line 1204):
# Blink rate: ~15-20 blinks/min baseline, decreases under load
blink_rate_baseline <- 17  # blinks per minute
blink_rate_current <- blink_rate_baseline * (1 - 0.3 * highload_prob)  # -30% under load
blink_rate_current <- blink_rate_current * (1 + 0.4 * lapse_prob)      # +40% during fatigue

# Add to features_reactive:
Feature = c(..., "Blink Rate", ...),
Value = c(..., blink_rate_current, ...),
Unit = c(..., "bpm", ...)
```

**Benefit:** Adds validated cognitive load indicator with minimal code.

---

#### 3. **Simulate HRV (Real Values)**
```r
# In simulation loop:
# HRV RMSSD: ~40ms baseline, decreases under load (De Louche 2024)
hrv_baseline <- 40  # ms
hrv_load_factor <- 1 - (0.35 * highload_prob)  # -35% under high load
hrv_fatigue_factor <- 1 - (0.20 * lapse_prob)  # -20% during fatigue
hrv_rmssd_ms <- hrv_baseline * hrv_load_factor * hrv_fatigue_factor + rnorm(1, 0, 3)
hrv_rmssd_ms <- max(20, min(60, hrv_rmssd_ms))  # Physiological bounds

# Replace placeholder in features_reactive with:
hrv_rmssd_ms  # computed value instead of static 40
```

**Benefit:** Makes HRV column actually informative instead of static.

---

### Maybe Later (Lower Priority)

#### 4. **Tool Switch Rate**
Requires more simulation infrastructure (tool states, switch events). Skip unless you want operational metrics.

#### 5. **Ambient Noise**
Interesting but not critical for core cognitive monitoring. Could add as environmental context.

---

## 📊 Proposed Enhanced Table

If you add the 3 quick wins, your table would have **12 features**:

### Primary Biosignals (6)
- Pupil Diameter (tonic)
- **Phasic Pupil (TEPR)** ⭐ NEW
- **Blink Rate** ⭐ NEW  
- Grip Force
- Tremor RMS (8–12Hz)
- **HRV (RMSSD)** ⭐ REAL VALUES

### Derived Metrics (3)
- Grip CV%
- Time-on-Task
- (Optional: Phasic/Tonic Ratio)

### Model Predictions (3)
- Normal Prob
- High Load Prob
- Lapse Prob

---

## 🚀 Implementation Priority

**HIGH PRIORITY** (do these):
1. ✅ Simulate real HRV values (currently placeholder)
2. ✅ Add blink rate simulation  
3. ✅ Show phasic pupil response (already computed!)

**LOW PRIORITY** (skip for now):
4. ❌ Tool switch rate (needs workflow simulation)
5. ❌ Ambient noise (environmental, not core)

---

## Summary

Your table is **working perfectly** with 9 features! ✅

You can enhance it significantly by:
1. Making HRV dynamic (currently static)
2. Adding blink rate (strong literature support)
3. Showing phasic pupil separately (you already compute it!)

These would make your biosignal panel even more comprehensive and aligned with the surgical monitoring literature. All three are **quick additions** to the existing simulation code.

Want me to implement these enhancements? 🚀

