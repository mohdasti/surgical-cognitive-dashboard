# Evidence-Based Biosignal Parameters Summary

## 📚 Literature-Validated Simulation Parameters

This document summarizes the peer-reviewed evidence used to simulate realistic surgical biosignal data in the Surgical Cognitive Dashboard.

---

## 1️⃣ Pupil Diameter (Pupillometry)

### Parameters
- **Baseline**: 3.5 mm (SD ±0.2 mm) under photopic lighting
- **Task-Evoked Pupillary Response (TEPR)**: +0.2–0.4 mm peak dilation
- **Hippus (fatigue oscillation)**: 0.25 Hz, amplitude 0.12 mm
- **Time constants**: Rise τ=1.2s, Decay τ=2.5s

### Evidence
- **Wu et al. 2019** (PMC7672675): Eye-tracking metrics predict workload in robotic surgery
- **TEPR literature**: Klingner 2008 - dilations < 0.5mm under controlled luminance
- **Device**: Tobii Pro Glasses 2 at 50 Hz sampling

### Cognitive State Relationships
- **High Load**: Baseline + 0.2–0.4 mm dilation (1–2s after demand spike)
- **Fatigue/Lapse**: Slow hippus oscillations, potential constriction

---

## 2️⃣ Grip Force (Laparoscopic Instruments)

### Parameters
- **Baseline**: 4.5 N (device-dependent)
- **Coefficient of Variation (CV)**:
  - Fresh: 6–8%
  - Fatigued (30min): 10–12%
- **Tremor component**: 8–12 Hz band at 2.5% RMS of mean
- **Low-frequency drift**: < 1 Hz (task variations)

### Evidence
- **Araki et al. 2021** (PMID 27572059): Mean gripping force 3.4–7.0 N depending on forceps design
- **Olig et al. 2023** (PMID 37201694): Device mechanics vary widely across laparoscopic tools
- **Ergonomics literature**: Stress increases co-contraction (+5–15% mean force)

### Cognitive State Relationships
- **High Load**: +10% mean force, modest CV increase
- **Fatigue**: Decreasing peak force, +30–50% CV increase

---

## 3️⃣ Tremor Amplitude (Hand/Tool-Tip)

### Parameters
- **Baseline RMS**: 60–120 µm at tool tip
- **Dominant frequency**: 8–12 Hz (physiological tremor)
- **Time-on-task effect**: +7–12% per hour
- **Wrist support effect**: −20–40% amplitude reduction

### Evidence
- **Wells 2013** (PMC3989364): ~50–200 µm RMS in microsurgical conditions
- **Becker 2008** (PMC3032442): 96.6 ± 84.5 µm (1 kHz sampling, vitreoretinal surgery)
- **Coulson 2010** (PMID 20853330): Wrist support significantly reduces tremor
- **Time effect**: 8.4× increase vs. desk work (PMID 18509664)

### Cognitive State Relationships
- **High Load/Stress**: Increased amplitude in 8–12 Hz band
- **Fatigue**: Sustained high tremor with time-on-task

---

## 4️⃣ Heart Rate Variability (HRV) - For Future Implementation

### Parameters
- **Baseline** (standing/quiet):
  - SDNN: 30–50 ms
  - RMSSD: 25–45 ms
  - LF/HF: ~1.0–2.0
- **High-stress steps**:
  - SDNN: −10–30%
  - RMSSD: −10–30%
  - LF/HF: +50–200%
- **Window sizes**: 120s for frequency domain, 30–60s for RMSSD

### Evidence
- **De Louche et al. 2024** (BJS Open): HRV as dynamic stress marker in vascular surgery
  - LF/HF ratio rises 100–240% above baseline at key steps
  - SDNN drops 10–14%
  - **120-s windows** validated for intra-operative detection
- **Böhm et al. 2001** (JAMA Surgery): Randomized trial showing HRV differences lap vs. open
- **Task Force 1996** (PMID 8598068): ECG ≥250 Hz recommended for HRV analysis

### Cognitive State Relationships
- **High Load**: ↓SDNN, ↓RMSSD, ↑LF/HF (inverse correlation with pupil)
- **Recovery**: Partial recovery over 3–5 minutes

---

## 5️⃣ Temporal Dynamics & Event Timing

### Flow Disruptions (FDs)
- **Frequency**: ~15–16 FDs/hour (λ ≈ 0.3/min Poisson)
- **Duration**: High-load states last 60–180 seconds (1–5 min for critical steps)
- **Evidence**: Weigl 2018, Dru 2017 (ScienceDirect) - robotic OR observational studies

### State Transitions
- **Pupil response latency**: 200–500 ms, peak at 1–2 s
- **HRV stabilization**: 60–120 s windows
- **Fatigue accumulation**: Gradual over 20–30 minute intervals

---

## 6️⃣ Multimodal Signal Relationships

### Cross-Modal Correlations
- **Pupil ↔ HRV**: Negative correlation (pupil ↑, SDNN ↓)
- **Grip ↔ Tremor**: Shared 8–12 Hz power (R² ~0.1–0.2)
- **Fusion strategy**: Early fusion on standardized rolling windows
  - 30–60s for RMSSD + z-scored pupil
  - Force CV + tremor RMS as secondary features

### Evidence
- **MDPI 2024** (Sensors): Multimodal fusion improves cognitive-load prediction
- **Surgical workload studies**: Pupil + HR/HRV + GSR outperform single-channel

---

## 🎯 Implementation in Dashboard

### Sampling Rates (Simulated)
- **Pupil**: 60–120 Hz (real devices: 50–120 Hz)
- **Grip Force**: 200 Hz (captures steadiness + tremor)
- **Tremor**: 500 Hz (resolves 8–12 Hz + harmonics; research tools: 1 kHz)
- **HRV**: 250–500 Hz ECG (future implementation)

### State Detection Logic
**High Cognitive Load:**
- Pupil dilation > +0.2 mm (50% weight)
- Grip force elevation > +0.5 N (20% weight)
- Tremor elevation > +30 µm (30% weight)

**Attentional Lapse:**
- Pupil constriction < baseline (40% weight)
- Grip CV > 10% (30% weight)
- Sustained tremor from fatigue (30% weight)

### Default Thresholds (Adjustable in UI)
- **Lapse alert**: P(lapse) > 0.3 (default, adjustable 0–1)
- **High-load alert**: P(high-load) > 0.6 (default, adjustable 0–1)

---

## 📖 Key Citations

### Primary Load-Bearing Studies
1. **Wu et al. 2019** - Eye-tracking workload in robotic tasks (PMC7672675)
2. **De Louche et al. 2024** - HRV step-wise stress in surgery (BJS Open)
3. **Araki et al. 2021** - Grip forces in laparoscopic surgery (PMID 27572059)
4. **Wells 2013** - Tremor in microsurgery (PMC3989364)
5. **Becker 2008** - Tremor modeling (PMC3032442)
6. **Böhm et al. 2001** - HRV randomized trial (JAMA Surgery)

### Methodological Standards
- **Task Force 1996** - HRV measurement standards (PMID 8598068)
- **Klingner 2008** - TEPR magnitude limits
- **Coulson 2010** - Wrist support effects on tremor (PMID 20853330)

### Contextual/Environmental
- **Weigl 2018** - Flow disruptions in robotic OR (ScienceDirect)
- **MDPI 2024** - Multimodal physiological sensors for workload (Sensors)

---

## ⚠️ Important Caveats

1. **Pupil diameter**: Absolute mm values are lighting-sensitive; use relative (% of baseline) for generalization
2. **HRV LF/HF interpretation**: Report both time-domain (RMSSD/SDNN) and frequency-domain; anchor to % change from baseline
3. **Tremor values**: Task and support-dependent; expose these parameters in UI
4. **Device variation**: Grip force depends heavily on instrument mechanics (3.4–7.0 N range across devices)
5. **Simulation vs. Reality**: This is a demonstration tool with evidence-based parameters, not a validated clinical system

---

## 🔄 Future Enhancements

### Planned Additions
1. **Real HRV integration**: RMSSD (30–60s), SDNN & LF/HF (120s windows)
2. **Blink rate**: From eye-tracking (60s windows)
3. **Tool switch rate**: Task segmentation features (120s windows)
4. **Ambient noise**: Environmental stressors (60s windows)

### Validation Opportunities
- Compare simulated patterns to real surgical data
- Adjust weights based on ROC/PR curves from validation cohort
- Implement leave-one-surgeon-out (LOSO) cross-validation
- Calibrate probability outputs (Platt scaling)

---

**Last Updated**: October 2025  
**Version**: 1.0 - Evidence-Based Simulation  
**License**: Apache 2.0

