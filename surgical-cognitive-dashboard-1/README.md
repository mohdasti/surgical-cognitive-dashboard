# Surgical Cognitive Dashboard 🧠

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Status: Proof of Concept](https://img.shields.io/badge/Status-Proof_of_Concept-blue.svg)](https://github.com/mohdasti/surgical-cognitive-dashboard)
[![R Version: 4.x](https://img.shields.io/badge/R-4.x-blue?logo=r)](https://www.r-project.org/)
[![Shiny App](https://img.shields.io/badge/Shiny-App-blue?logo=rstudio)](https://shiny.rstudio.com/)

A comprehensive machine learning pipeline for monitoring surgical cognitive states using causal feature engineering, Leave-One-Surgeon-Out (LOSO) cross-validation, and real-time anomaly detection.

**➡️ [View the Live Interactive Dashboard](http://127.0.0.1:3838)** *(when running locally)*

---

## 🚀 The Vision

This project addresses a critical challenge in patient safety: how can we proactively monitor a surgeon's cognitive state to mitigate the risks of fatigue and overload? The system implements a comprehensive machine learning pipeline with strict causal feature engineering to ensure real-time applicability.

**Key Innovations:**
- **Causal Feature Engineering**: Strictly causal features with no future data leakage
- **LOSO Cross-Validation**: Leave-One-Surgeon-Out validation for generalizability
- **Anomaly Fusion**: Isolation Forest for detecting rare attentional lapses
- **Real-time Calibration**: Platt scaling for reliable probability estimates
- **Comprehensive Diagnostics**: Full model explainability and threshold tuning

![A mockup of a surgical console screen displaying a time-series plot of the surgeon's pupil dilation and grip force variability, indicating their cognitive state during a procedure.](case_study/images/surgical_console_enhanced.png)

---

## ✨ Key Features

* **Real-Time Streaming:** Live data stream simulation with 5Hz updates and configurable thresholds
* **Causal Feature Engineering:** 8 strictly causal features with segment-aware baselines
* **Multi-Model Architecture:** 
    * **XGBoost Classifier**: Multi-class cognitive state prediction with class weighting
    * **Isolation Forest**: Anomaly detection for rare attentional lapses
    * **Platt Scaling**: Probability calibration for reliable estimates
* **Comprehensive Diagnostics:** 6-tab diagnostic interface with calibration analysis and threshold tuning
* **Event Logging:** Optional CSV logging for post-hoc analysis and debugging
* **LOSO Validation:** Leave-One-Surgeon-Out cross-validation for generalizability

---

## 🛠️ Tech Stack

* **Language:** R 4.x
* **Core Packages:** `shiny`, `tidyverse`, `xgboost`, `yardstick`, `slider`, `solitude`, `fastshap`, `pdp`
* **Development:** `renv` for package management, `testthat` for testing
* **Build System:** `Makefile` for automated pipeline execution

---

## 📂 Project Structure

```
/ (project root)
├── config/
│   └── config.yml                  # Centralized configuration
├── data/
│   ├── processed/                  # Generated datasets
│   ├── diagnostics/                # Model artifacts and plots
│   └── logs/                       # Event logs (optional)
├── scripts/
│   ├── 00_setup.R                  # Environment setup
│   ├── 01_simulate_data.R          # Data simulation
│   ├── 02_feature_engineering.R    # Causal feature computation
│   ├── 03_train_model.R            # XGBoost training
│   ├── 03b_lapse_detector.R        # Isolation Forest
│   ├── 03c_explain_and_pd.R        # SHAP and PD plots
│   ├── 04_eval_LOSO.R              # LOSO evaluation
│   ├── 05_diagnostics_export.R     # Calibration artifacts
│   └── utils_logging.R             # Logging utilities
├── shiny_app/
│   ├── app.R                       # Main Shiny application
│   └── modules/
│       ├── streaming_inference.R   # CogEngine class
│       └── diagnostics_module.R    # Diagnostics UI/Server
├── tests/
│   ├── test_windowing.R            # Feature engineering tests
│   └── test_features_and_fusion.R  # Integration tests
├── case_study/
│   └── images/                     # Generated plots
├── Makefile                        # Build automation
└── renv.lock                       # Package versions
```

---

## 🧪 Data & Features

### **Raw Sensor Data:**
- **Pupil Diameter (mm):** Continuous pupillometry measurements
- **Grip Force (Newtons):** Surgical instrument grip pressure  
- **Instrument Tremor (Hz):** High-frequency tremor measurements
- **Ambient Noise (dB):** Operating room noise levels
- **Blink Events:** Eye blink detection
- **Tool Usage:** Surgical instrument tracking

### **Causal Engineered Features (8 total):**
- **Tonic Pupil Level (30s):** Rolling mean baseline pupil size
- **Grip Force Variability (15s):** Rolling standard deviation of grip pressure
- **Tremor Trend (10s):** Rolling mean of tremor frequency
- **Phasic Pupil Change (5s):** Segment-aware pupil responses
- **Blink Rate (60s):** Rolling sum of blink events
- **Tool Switch Rate (120s):** Instrument change frequency
- **Noise Mean (60s):** Rolling mean ambient noise
- **Noise Spike Count (60s):** High-noise event detection

**Key Properties:**
- ✅ **Strictly Causal**: No future data leakage
- ✅ **Segment-Aware**: Baselines reset on tool switches
- ✅ **Real-time Legal**: Suitable for live streaming

## 📊 Model Performance

### **XGBoost Classifier (LOSO Cross-Validation):**
- **Multi-class Classification:** 4 cognitive states (Optimal, High Load, Fatigued, Attentional Lapse)
- **Class Weighting:** Balanced training for rare lapse events
- **Platt Scaling:** Calibrated probabilities for reliable estimates
- **Calibration Quality:** ECE=0.000296, MCE=0.000296, Brier=0.00192

### **Isolation Forest (Anomaly Detection):**
- **Target:** Rare attentional lapses (0.4% prevalence)
- **Training:** Non-lapse data only
- **Threshold:** 99th percentile anomaly score
- **Purpose:** Catch unusual patterns missed by supervised model

### **Key Metrics:**
- **Precision-Recall AUC:** Optimized for rare event detection
- **Confusion Matrix:** Multi-class performance visualization
- **Feature Importance:** XGBoost and SHAP-based explanations

---

## 🏁 Getting Started

### **Quick Start (Recommended)**

1. **Clone and Setup:**
   ```bash
   git clone https://github.com/mohdasti/surgical-cognitive-dashboard.git
   cd surgical-cognitive-dashboard
   make setup
   ```

2. **Run Complete Pipeline:**
   ```bash
   make simulate    # Generate synthetic data
   make features    # Compute causal features
   make train       # Train XGBoost model
   make anomaly     # Train Isolation Forest
   make shap        # Generate explainability plots
   make eval        # LOSO evaluation
   make diagnostics # Calibration artifacts
   ```

3. **Launch Dashboard:**
   ```bash
   make app
   ```

### **Individual Commands**

| Command | Description | Output |
|---------|-------------|---------|
| `make setup` | Install packages, setup environment | `renv.lock`, directories |
| `make simulate` | Generate synthetic surgical data | `data/processed/sim_stream.csv.gz` |
| `make features` | Compute causal features | `data/processed/features.csv.gz` |
| `make train` | Train XGBoost + calibration | `data/processed/xgb_loso_models.rds` |
| `make anomaly` | Train Isolation Forest | `data/processed/lapse_iso.rds` |
| `make shap` | Generate explainability plots | `data/diagnostics/model_artifacts.rds` |
| `make eval` | LOSO evaluation | `data/diagnostics/loso_eval.rds` |
| `make diagnostics` | Calibration artifacts | `data/diagnostics/calibration.rds` |
| `make app` | Launch Shiny dashboard | Interactive web app |

### **Testing**
```bash
# Run test suite
Rscript -e "library(testthat); test_dir('tests')"
```

---

## 💻 Dashboard Interface

### **🏥 Live Surgical Dashboard**
- **Real-time HUD:** 5Hz updates with cognitive state, probabilities, and reasons
- **Interactive Controls:** Silent mode, threshold sliders, logging toggle
- **Alert System:** Real-time alerts with detailed reason codes
- **Event Logging:** Optional CSV logging for post-hoc analysis
- **Streaming Data:** Replays 3-hour simulated surgical procedures

### **🔬 ML Model Diagnostics (6 Tabs)**
- **Overview:** Model card, feature list, hyperparameters
- **Cross-Validation:** Confusion matrix, PR curves, LOSO results
- **Calibration:** Reliability plots, calibration statistics, probability histograms
- **Threshold Sandbox:** Interactive threshold tuning with real-time metrics
- **Feature Importance:** XGBoost importance and SHAP plots
- **Partial Dependence:** Interactive PD plots for all features

---

## 🎯 Use Cases

### **Clinical Applications:**
- **Surgical Safety:** Real-time cognitive state monitoring and early warning systems
- **Training & Assessment:** Objective measurement of surgical skill development
- **Quality Improvement:** Data-driven insights into surgical performance patterns

### **Research Applications:**
- **Cognitive Load Studies:** Platform for studying attentional demands during procedures
- **Model Validation:** Framework for testing new physiological biomarkers
- **Anomaly Detection:** Research into rare but critical attentional lapses

### **Technical Applications:**
- **Real-time ML:** Causal feature engineering for streaming applications
- **Model Explainability:** SHAP and partial dependence for clinical interpretability
- **Calibration Research:** Probability calibration for safety-critical decisions

---

## 🔬 Research Background

### **Technical Innovations:**
- **Causal Feature Engineering:** Strict temporal causality for real-time applications
- **LOSO Cross-Validation:** Surgeon-independent model validation
- **Anomaly Fusion:** Combining supervised and unsupervised approaches
- **Probability Calibration:** Reliable uncertainty quantification for safety-critical decisions

### **Scientific Foundation:**
- **Cognitive Neuroscience:** Pupillometry as a biomarker for neural effort and cognitive load
- **Motor Control Theory:** Grip force variability as an indicator of attentional state
- **Human Factors Engineering:** Real-time monitoring for safety-critical environments
- **Machine Learning:** Causal inference and temporal modeling for streaming data

---

## 📈 Future Directions

### **Technical Enhancements:**
- **Real Sensor Integration:** Connect with actual pupillometry and force sensors
- **Deep Learning Models:** Explore LSTM/Transformer architectures for temporal data
- **Multi-Modal Fusion:** Integrate additional physiological signals (heart rate, EEG)
- **Edge Computing:** Deploy models for real-time inference on surgical devices

### **Clinical Validation:**
- **Real-World Testing:** Partner with surgical training centers for validation studies
- **Multi-Surgeon Studies:** Extend to team-based surgical environments
- **Longitudinal Studies:** Track cognitive state changes over extended procedures
- **Clinical Trials:** Randomized controlled trials for safety and efficacy

### **Research Extensions:**
- **Cross-Domain Adaptation:** Apply to other high-stakes domains (aviation, driving)
- **Personalized Models:** Surgeon-specific calibration and adaptation
- **Causal Discovery:** Automated feature engineering from raw sensor data

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Mohammad Dastgheib**  
PhD Candidate, Cognitive Neuroscience  
Portfolio: [mdastgheib.com](https://mdastgheib.com)  
LinkedIn: [mohdasti](https://linkedin.com/in/mohdasti)
