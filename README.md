# Surgical Cognitive Dashboard 🧠

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Status: Production Ready](https://img.shields.io/badge/Status-Production_Ready-green.svg)](https://github.com/mohdasti/surgical-cognitive-dashboard)
[![R Version: 4.x](https://img.shields.io/badge/R-4.x-blue?logo=r)](https://www.r-project.org/)
[![Shiny App](https://img.shields.io/badge/Shiny-App-blue?logo=rstudio)](https://shiny.rstudio.com/)

A comprehensive machine learning pipeline for real-time surgical cognitive state monitoring using causal feature engineering, Leave-One-Surgeon-Out (LOSO) cross-validation, and multi-model architecture with deployment-ready applications.

## 🚀 Project Overview

This project implements a complete machine learning system for monitoring surgical cognitive states, featuring:

- **Causal Feature Engineering**: 8 strictly causal features with segment-aware baselines
- **Multi-Model Architecture**: XGBoost classifier + Isolation Forest anomaly detection + Platt scaling
- **LOSO Cross-Validation**: Leave-One-Surgeon-Out validation for generalizability
- **Real-time Streaming**: 5Hz updates with configurable thresholds
- **Comprehensive Diagnostics**: 6-tab diagnostic interface with calibration analysis
- **Deployment Ready**: Multiple deployment options (ShinyApps.io, Docker, self-hosted)
- **iframe Embedding**: Ready for Netlify/Quarto integration

## 📁 Project Structure

```
surgical-cognitive-dashboard/
├── surgical-cognitive-dashboard-1/     # Main Development Environment
│   ├── Complete ML pipeline (scripts 01-05)
│   ├── Test suite (25 tests passing)
│   ├── Makefile automation
│   ├── Shiny app with diagnostics
│   └── Full development environment
│
└── surgical-cognitive-dashboard-app/   # Deployment Package
    ├── Standalone Shiny app
    ├── Docker + nginx setup
    ├── ShinyApps.io deployment
    └── iframe embedding utilities
```

## 🛠️ Tech Stack

- **Language**: R 4.x
- **Core Packages**: `shiny`, `tidyverse`, `xgboost`, `yardstick`, `slider`, `solitude`, `fastshap`, `pdp`
- **Development**: `renv` for package management, `testthat` for testing
- **Build System**: `Makefile` for automated pipeline execution
- **Deployment**: Docker, nginx, ShinyApps.io

## 🧪 Data & Features

### **Raw Sensor Data:**
- **Pupil Diameter (mm)**: Continuous pupillometry measurements
- **Grip Force (Newtons)**: Surgical instrument grip pressure  
- **Instrument Tremor (Hz)**: High-frequency tremor measurements
- **Ambient Noise (dB)**: Operating room noise levels
- **Blink Events**: Eye blink detection
- **Tool Usage**: Surgical instrument tracking

### **Causal Engineered Features (8 total):**
- **Tonic Pupil Level (30s)**: Rolling mean baseline pupil size
- **Grip Force Variability (15s)**: Rolling standard deviation of grip pressure
- **Tremor Trend (10s)**: Rolling mean of tremor frequency
- **Phasic Pupil Change (5s)**: Segment-aware pupil responses
- **Blink Rate (60s)**: Rolling sum of blink events
- **Tool Switch Rate (120s)**: Instrument change frequency
- **Noise Mean (60s)**: Rolling mean ambient noise
- **Noise Spike Count (60s)**: High-noise event detection

**Key Properties:**
- ✅ **Strictly Causal**: No future data leakage
- ✅ **Segment-Aware**: Baselines reset on tool switches
- ✅ **Real-time Legal**: Suitable for live streaming

## 📊 Model Performance

### **XGBoost Classifier (LOSO Cross-Validation):**
- **Multi-class Classification**: 4 cognitive states (Optimal, High Load, Fatigued, Attentional Lapse)
- **Class Weighting**: Balanced training for rare lapse events
- **Platt Scaling**: Calibrated probabilities for reliable estimates
- **Calibration Quality**: ECE=0.000296, MCE=0.000296, Brier=0.00192

### **Isolation Forest (Anomaly Detection):**
- **Target**: Rare attentional lapses (0.4% prevalence)
- **Training**: Non-lapse data only
- **Threshold**: 99th percentile anomaly score
- **Purpose**: Catch unusual patterns missed by supervised model

## 🏁 Getting Started

### **Development Environment**

1. **Clone and Setup:**
   ```bash
   git clone https://github.com/mohdasti/surgical-cognitive-dashboard.git
   cd surgical-cognitive-dashboard/surgical-cognitive-dashboard-1
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

3. **Run Tests:**
   ```bash
   Rscript -e "library(testthat); test_dir('tests')"
   ```

4. **Launch Development App:**
   ```bash
   make app
   ```

### **Deployment**

#### **ShinyApps.io Deployment:**
```bash
cd surgical-cognitive-dashboard-app
export SHINYAPPS_ACCOUNT="your-account"
export SHINYAPPS_TOKEN="your-token"
export SHINYAPPS_SECRET="your-secret"
Rscript deploy.R
```

#### **Docker Deployment:**
```bash
cd surgical-cognitive-dashboard-app
docker build -t cogbb .
docker run -p 8080:80 cogbb
```

## 💻 Application Features

### **Real-time Dashboard:**
- **Live HUD**: 5Hz updates with cognitive state, probabilities, and reasons
- **Interactive Controls**: Silent mode, threshold sliders, logging toggle
- **Alert System**: Real-time alerts with detailed reason codes
- **Event Logging**: Optional CSV logging for post-hoc analysis

### **ML Model Diagnostics (6 Tabs):**
- **Overview**: Model card, feature list, hyperparameters
- **Cross-Validation**: Confusion matrix, PR curves, LOSO results
- **Calibration**: Reliability plots, calibration statistics, probability histograms
- **Threshold Sandbox**: Interactive threshold tuning with real-time metrics
- **Feature Importance**: XGBoost importance and SHAP plots
- **Partial Dependence**: Interactive PD plots for all features

## 🔗 iframe Embedding

The app is ready for embedding in websites:

```html
<iframe 
  src="https://your-app-url/" 
  width="100%" 
  height="820" 
  loading="lazy"
  style="border:1px solid #ddd;border-radius:12px">
</iframe>
```

## 🎯 Use Cases

### **Clinical Applications:**
- **Surgical Safety**: Real-time cognitive state monitoring and early warning systems
- **Training & Assessment**: Objective measurement of surgical skill development
- **Quality Improvement**: Data-driven insights into surgical performance patterns

### **Research Applications:**
- **Cognitive Load Studies**: Platform for studying attentional demands during procedures
- **Model Validation**: Framework for testing new physiological biomarkers
- **Anomaly Detection**: Research into rare but critical attentional lapses

### **Technical Applications:**
- **Real-time ML**: Causal feature engineering for streaming applications
- **Model Explainability**: SHAP and partial dependence for clinical interpretability
- **Calibration Research**: Probability calibration for safety-critical decisions

## 🔬 Research Background

### **Technical Innovations:**
- **Causal Feature Engineering**: Strict temporal causality for real-time applications
- **LOSO Cross-Validation**: Surgeon-independent model validation
- **Anomaly Fusion**: Combining supervised and unsupervised approaches
- **Probability Calibration**: Reliable uncertainty quantification for safety-critical decisions

### **Scientific Foundation:**
- **Cognitive Neuroscience**: Pupillometry as a biomarker for neural effort and cognitive load
- **Motor Control Theory**: Grip force variability as an indicator of attentional state
- **Human Factors Engineering**: Real-time monitoring for safety-critical environments
- **Machine Learning**: Causal inference and temporal modeling for streaming data

## 📈 Future Directions

### **Technical Enhancements:**
- **Real Sensor Integration**: Connect with actual pupillometry and force sensors
- **Deep Learning Models**: Explore LSTM/Transformer architectures for temporal data
- **Multi-Modal Fusion**: Integrate additional physiological signals (heart rate, EEG)
- **Edge Computing**: Deploy models for real-time inference on surgical devices

### **Clinical Validation:**
- **Real-World Testing**: Partner with surgical training centers for validation studies
- **Multi-Surgeon Studies**: Extend to team-based surgical environments
- **Longitudinal Studies**: Track cognitive state changes over extended procedures
- **Clinical Trials**: Randomized controlled trials for safety and efficacy

## 📜 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Mohammad Dastgheib**  
PhD Candidate, Cognitive Neuroscience  
Portfolio: [mdastgheib.com](https://mdastgheib.com)  
LinkedIn: [mohdasti](https://linkedin.com/in/mohdasti)

## 🙏 Acknowledgments

This project represents a comprehensive implementation of machine learning techniques for real-time cognitive state monitoring in surgical environments. The work combines causal feature engineering, multi-model architecture, and deployment-ready applications for both research and clinical applications.