# Prompt for ChatGPT: Design Evidence-Based HRV Cognitive State Model

## Context

I'm building a surgical cognitive monitoring dashboard that predicts surgeon cognitive state (Normal, High Load, Attentional Lapse) from biosignals. The app needs an XGBoost model stored in `data/processed/xgb_loso_models.rds`.

## Current Biosignal Features

The app already simulates and displays:

1. **Pupil Diameter** (mm)
   - Baseline: 4.0 mm
   - TEPR (task-evoked pupillary response): +0.3-0.5 mm under load
   - Range: 2.5-6.5 mm

2. **HRV (RMSSD)** (ms) - NEW, just added to UI
   - Baseline: 40 ms
   - High Load: -35% reduction (De Louche et al. 2024)
   - Lapse: -20% reduction
   - Range: 20-60 ms

3. **Grip Force** (N)
   - Baseline: 4.5 N
   - CV: 8-12% (increases with fatigue)

4. **Tremor RMS** (μm)
   - Baseline: 88 μm at 8-12 Hz
   - Increases with time-on-task and stress

5. **Blink Rate** (blinks/min)
   - Baseline: 17 blinks/min
   - High Load: -30%, Lapse: +40%

6. **Ambient Noise** (dB)
   - Baseline: 60 dB with task variation

## Model Requirements

The missing file `xgb_loso_models.rds` should contain:

```r
# Expected structure:
models <- list(
  list(
    feat_cols = c("feature1", "feature2", ...),  # Feature names
    bst = xgboost_model_object,                   # Trained XGBoost model
    glm_cal = glm_calibration_object,             # Platt scaling for calibration
    feat_names = c("feature1", "feature2", ...)   # Same as feat_cols
  )
)
```

### Model Specifications

1. **Task**: Multi-class classification (3 states: Normal, High Load, Attentional Lapse)
2. **Features**: Derived from the 6 biosignals above (rolling windows, statistics)
3. **Algorithm**: XGBoost with `objective = "multi:softprob"`
4. **Calibration**: Platt scaling (logistic regression) for Lapse probability
5. **Validation**: Leave-One-Surgeon-Out (LOSO) cross-validation preferred
6. **Evidence**: Should reference peer-reviewed studies for feature engineering

## Your Task

Please design an **evidence-based XGBoost model** for cognitive state classification that:

### 1. Feature Engineering

Based on **literature-validated relationships**, what features should we compute from the raw biosignals?

Examples:
- Tonic pupil level (30s mean)
- Phasic pupil change (5s delta from baseline)
- Grip force variability (15s SD)
- HRV RMSSD (60s window) ← **Focus here**
- Tremor trend (10s mean)
- Blink rate (60s count)

**Key Question:** What HRV-related features are most predictive of cognitive load and attentional lapses? Include:
- Time-domain metrics (RMSSD, SDNN)
- Window sizes (30s? 60s? 120s?)
- Derived features (rate of change, trends)
- Interaction features (HRV × Pupil, HRV × Grip CV)

### 2. Evidence Base

For each feature you propose, cite **peer-reviewed studies** showing:
- Normal ranges during surgical tasks
- Changes under cognitive load
- Changes during attentional lapses/fatigue
- Sensitivity/specificity for state detection

**Particularly needed:**
- HRV thresholds for high cognitive load (De Louche et al. 2024 found -35% RMSSD reduction)
- HRV patterns during attentional lapses
- Optimal window sizes for HRV computation
- Feature importance rankings from prior work

### 3. Model Hyperparameters

Suggest **XGBoost hyperparameters** with justification:
- `max_depth`: Tree depth (default 6)
- `eta`: Learning rate (default 0.3)
- `nrounds`: Number of boosting rounds
- `subsample`: Row subsampling (prevent overfitting)
- `colsample_bytree`: Feature subsampling
- Any other parameters

Why these values for cognitive state classification with imbalanced classes (lapses are rare)?

### 4. Class Imbalance Handling

Attentional lapses are **rare** (~0.2-2% of time). How should we:
- Weight the classes in XGBoost (`scale_pos_weight`)?
- Handle evaluation metrics (precision-recall vs accuracy)?
- Set decision thresholds (different thresholds for High Load vs Lapse)?

### 5. Platt Scaling (Calibration)

The model uses Platt scaling to calibrate Lapse probabilities:
```r
glm_cal <- glm(lapse_true ~ lapse_prob_raw, family = binomial)
```

Should we:
- Use isotonic regression instead?
- Calibrate all three classes separately?
- Any other calibration approaches for rare event detection?

## Output Format

Please provide:

### A. Feature List
```
Feature Name | Window | Computation | Evidence (Study + Finding)
----------------------------------------------------------------
rmssd_60s    | 60s    | RMSSD       | De Louche 2024: -35% under load
...
```

### B. Model Parameters
```r
xgb_params <- list(
  objective = "multi:softprob",
  num_class = 3,
  max_depth = X,
  eta = Y,
  # ... with justification
)
```

### C. Training Procedure
- How to compute features from raw signals
- How to handle missing data
- How to split train/test (LOSO preferred)
- How to calibrate probabilities

### D. Expected Performance
- What metrics to track (PR-AUC for Lapse, accuracy for others)?
- What are reasonable performance targets?
- How to validate the model?

## Additional Context

The dashboard is for **research/education**, not clinical use. However, it should use **evidence-based parameters** and **interpretable features** to demonstrate proof-of-concept.

**Key Studies to Reference:**
- De Louche et al. (2024) - HRV in surgery (BJS Open)
- Marquart et al. (2015) - Blink rate and cognitive load
- Wu et al. (2019) - Pupillometry (PMC7672675)
- Kahneman & Beatty (1966) - TEPR and cognitive effort
- Wells (2013) - Surgical tremor (PMC3989364)

Please provide a **scientifically rigorous design** with full citations and implementation details I can use to create `scripts/03_train_model.R`.

Thank you!

