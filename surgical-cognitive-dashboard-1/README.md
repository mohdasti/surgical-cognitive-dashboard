# Surgical Cognitive Dashboard

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Status: Research Prototype](https://img.shields.io/badge/Status-Research_Prototype-blue.svg)](https://github.com/mohdasti/surgical-cognitive-dashboard)
[![R Version: 4.x](https://img.shields.io/badge/R-4.x-blue?logo=r)](https://www.r-project.org/)
[![Shiny App](https://img.shields.io/badge/Shiny-App-blue?logo=rstudio)](https://shiny.rstudio.com/)
[![Evidence-Based](https://img.shields.io/badge/Evidence-Based-green.svg)](BIOSIGNAL_EVIDENCE_SUMMARY.md)

A **professional, enterprise-grade** real-time surgical cognitive monitoring system with evidence-based biosignal simulation, comprehensive ML diagnostics, and clinical-quality visualization. Features literature-validated parameters from 16 peer-reviewed studies and full model interpretability.

**➡️ [Run Locally](#-getting-started)** | **[View Evidence Summary](BIOSIGNAL_EVIDENCE_SUMMARY.md)**

---

## 🚀 The Vision

This project addresses a critical challenge in patient safety: how can we proactively monitor a surgeon's cognitive state to mitigate the risks of fatigue and overload? The system implements a comprehensive machine learning pipeline with strict causal feature engineering to ensure real-time applicability.

**Key Innovations:**
- **Professional Interface**: Clinical-grade UI with CSS animations and purposeful visual indicators
- **Causal Feature Engineering**: Strictly causal features with no future data leakage
- **LOSO Cross-Validation**: Leave-One-Surgeon-Out validation for generalizability
- **Anomaly Fusion**: Isolation Forest for detecting rare attentional lapses
- **Real-time Calibration**: Platt scaling for reliable probability estimates
- **Comprehensive Diagnostics**: Full model explainability, threshold tuning, and performance analysis

![A mockup of a surgical console screen displaying a time-series plot of the surgeon's pupil dilation and grip force variability, indicating their cognitive state during a procedure.](case_study/images/surgical_console_enhanced.png)

---

## ✨ Key Features

### **Two Integrated Modules:**

#### **1. Live Monitor (Real-Time Streaming Dashboard)**
* **Evidence-Based Simulation:** Multi-component biosignal generation with parameters from 16 peer-reviewed studies
* **Real-Time Streaming:** 10-minute surgical simulation with 5Hz updates (200ms intervals) and live clock
* **Interactive Visualizations:** 
    * Pupil diameter tracking with tonic/phasic responses
    * Grip force variability with micro-movements and fatigue
    * Tremor amplitude with stress-modulated components
    * Cognitive state distribution with smoothed state transitions
* **Cognitive State Detection:**
    * Normal operating state (green indicator)
    * High cognitive load detection (orange indicator)
    * Attentional lapse detection (red indicator with urgent animation)
* **Professional Interface:** 
    * CSS-animated status indicators (attention-appropriate speeds)
    * Pulsing LIVE indicator with glow effect
    * Clean, emoji-free design suitable for clinical environments
    * Responsive layout with centered, professional typography

#### **2. ML Model Diagnostics (Comprehensive Performance Analysis)**
* **6 Progressive Disclosure Sections:**
    1. **Threshold Sandbox:** Interactive threshold tuning with real-time precision-recall tradeoffs
    2. **Probability Calibration:** Reliability analysis with ECE/MCE metrics and Brier scores
    3. **Model Overview:** Architecture, hyperparameters, confusion matrices, and PR curves
    4. **Cross-Validation Results:** LOSO evaluation with per-surgeon performance metrics
    5. **Feature Importance:** XGBoost gain-based importance rankings
    6. **Partial Dependence:** Marginal effect plots showing feature-prediction relationships
* **Real Data Integration:** All diagnostics use actual LOSO cross-validation results
* **Professional Accordion UI:** Expandable sections with high-impact sections prioritized

---

## 🛠️ Tech Stack

* **Language:** R 4.x
* **Core Packages:** 
    * **Visualization:** `shiny`, `shinydashboard`, `plotly`, `ggplot2`
    * **Data Processing:** `tidyverse`, `data.table`, `zoo`
    * **Real-Time:** Custom `CogEngine` R6 class with streaming buffer
* **Evidence Base:** 16 peer-reviewed studies (see [BIOSIGNAL_EVIDENCE_SUMMARY.md](BIOSIGNAL_EVIDENCE_SUMMARY.md))
* **Development:** `renv` for package management, Git for version control

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
│   ├── app_working.R               # Current production version
│   ├── app.R                       # Main development version
│   └── app_*.R                     # Various app iterations
├── tests/
│   ├── test_windowing.R            # Feature engineering tests
│   └── test_features_and_fusion.R  # Integration tests
├── case_study/
│   └── images/                     # Generated plots
├── Makefile                        # Build automation
└── renv.lock                       # Package versions
```

---

## 🧪 Evidence-Based Biosignal Simulation

### **Pupillometry (Literature-Validated):**
- **Baseline:** 3-5mm diameter (individual variation)
- **Tonic Response:** Slow drift over 30-90s windows
- **Phasic Response:** 0.5-1.5mm dilation under cognitive load (300-3000ms latency)
- **Micro-movements:** 0.1mm noise at 3-5 Hz
- **Fatigue Effect:** 5-15% constriction over 10 minutes
- **Sources:** Beatty (1982), Kahneman & Beatty (1966), Hess & Polt (1964)

### **Grip Force Dynamics:**
- **Baseline:** 5-25N (task-dependent)
- **Micro-movements:** 10-15% CV for precision tasks
- **Fatigue:** 1-3% decline per minute
- **Load Effect:** 20-30% increased variability under stress
- **Tremor Coupling:** Correlated with hand tremor
- **Sources:** Johansson & Westling (1984), Flanagan & Wing (1993)

### **Tremor Characteristics:**
- **Physiological Range:** 8-12 Hz baseline
- **Stress Modulation:** +2-5 Hz under load
- **Amplitude:** 20-100 μm (higher in surgeons)
- **Fatigue Effect:** +5-20% amplitude increase
- **Sources:** Elble & Koller (1990), Riviere et al. (1997)

### **State Detection Logic:**
- **Normal:** Stable baselines, low variability
- **High Load:** Pupil dilation >0.5mm, grip CV >15%, tremor >10 Hz
- **Lapse:** Pupil constriction, grip variability spike, tremor irregularity

📖 **Full methodology with 16 citations:** [BIOSIGNAL_EVIDENCE_SUMMARY.md](BIOSIGNAL_EVIDENCE_SUMMARY.md)

## 📊 Machine Learning Pipeline

### **Complete ML Diagnostics Workflow:**

#### **1. Data Generation (`scripts/01_simulate_data.R`)**
- Multi-component biosignal synthesis with literature-validated parameters
- Cognitive state simulation with realistic transitions
- 10-minute segments at 5Hz sampling rate

#### **2. Feature Engineering (`scripts/02_feature_engineering.R`)**
- **57 causal features** extracted with strict temporal constraints
- Rolling window statistics (mean, SD, CV, entropy)
- Spectral features (FFT, dominant frequencies)
- Time-on-task and fatigue indicators
- No future data leakage (production-ready)

#### **3. Model Training (`scripts/03_train_model.R`, `03b_lapse_detector.R`)**
- **XGBoost multi-class classifier** for state prediction
- **Isolation Forest** for rare lapse detection (anomaly fusion)
- **Platt scaling** for probability calibration
- Hyperparameter tuning with cross-validation

#### **4. LOSO Evaluation (`scripts/04_eval_LOSO.R`)**
- **Leave-One-Surgeon-Out** cross-validation
- Per-surgeon performance metrics (PR-AUC)
- Confusion matrices and precision-recall curves
- Generalization assessment across individuals

#### **5. Model Interpretability (`scripts/03c_explain_and_pd.R`)**
- **SHAP values** for feature importance
- **Partial dependence plots** showing feature effects
- **Feature importance rankings** (gain-based)

#### **6. Diagnostic Export (`scripts/05_diagnostics_export.R`)**
- **Threshold analysis:** Precision-recall tradeoffs
- **Calibration analysis:** ECE, MCE, Brier scores
- **Model artifacts:** Plots and tables for dashboard
- All diagnostics saved as `.rds` files for real-time loading

### **Real-Time Dashboard Integration:**
- **Live Monitor:** Streams simulated data at 5Hz with state predictions
- **ML Diagnostics:** Loads pre-computed diagnostics for instant access
- **Interactive threshold tuning:** Explore performance at different decision boundaries
- **Full transparency:** Every metric linked to training/validation results

---

## 🏁 Getting Started

### **Quick Start (Recommended)**

1. **Clone Repository:**
   ```bash
   git clone https://github.com/mohdasti/surgical-cognitive-dashboard.git
   cd surgical-cognitive-dashboard/surgical-cognitive-dashboard-1
   ```

2. **Install R Dependencies:**
   ```r
   # In R console:
   install.packages(c("shiny", "shinydashboard", "plotly", "tidyverse", 
                      "data.table", "zoo", "R6"))
   ```

3. **Launch Dashboard:**
   ```bash
   # Option 1: Run directly
   Rscript -e "shiny::runApp('shiny_app/app_working.R', launch.browser=TRUE)"
   
   # Option 2: Open in RStudio
   # Open shiny_app/app_working.R and click "Run App"
   ```

4. **Explore Features:**
   - Watch the 10-minute simulation unfold in real-time (5Hz updates)
   - Observe state transitions in the stacked probability chart
   - Review literature-validated biosignal patterns
   - Check feature metrics with embedded citations

### **Development Notes**

The repository includes multiple app versions for reference:
- `app_working.R` - **Current production version** (run this!)
- `app_minimal.R` - Minimal debugging version
- `app_enhanced.R` - Intermediate with ML models
- `app_full.R` - Full-featured with diagnostics tabs

### **System Requirements**
- **R:** 4.0 or higher
- **Memory:** 2GB+ RAM recommended
- **Browser:** Modern browser (Chrome, Firefox, Safari) for Plotly rendering
- **OS:** macOS, Linux, or Windows

---

## 💻 Dashboard Interface

### **Live Monitor Tab**
- **Status Cards:** Real-time state display with animated CSS indicators
  - Green dot (slow pulse) - Normal operation
  - Orange dot (warning flash) - High cognitive load
  - Red dot (urgent pulse) - Attentional lapse detected
- **LIVE Indicator:** Pulsing red dot with glow effect shows real-time streaming
- **Live Clock:** Elapsed time (MM:SS), duration, progress percentage
- **Real-Time Plots:**
  - Pupil Diameter (photopic, TEPR)
  - Grip Force (da Vinci robotic instruments)
  - Tremor Amplitude (8-12 Hz, μm)
  - Cognitive State Distribution (stacked probabilities)
- **Feature Metrics:** Live table with literature citations (toggleable)
- **Alert System:** Automatic notifications on state transitions
- **Control Panel:** Silent mode, adjustable thresholds, display options

### **ML Model Diagnostics Tab**
- **Threshold Sandbox:**
  - Distribution of lapse probabilities histogram
  - Precision-Recall tradeoff curve with optimal threshold
  - Dynamic threshold range based on actual data
- **Probability Calibration:**
  - Calibration plot (predicted vs. observed)
  - Probability distribution histogram
  - Calibration statistics (ECE, MCE, Brier Score)
- **Model Overview:**
  - LOSO confusion matrix
  - Precision-Recall curve for lapse detection
  - Model hyperparameters display
- **Cross-Validation Results:**
  - Per-surgeon PR-AUC metrics
  - LOSO validation summary table
- **Feature Importance:**
  - XGBoost gain-based importance barplot
  - Ranked feature contributions
- **Partial Dependence:**
  - Marginal effect plots for top 3 features
  - Feature-prediction relationship visualization

### **Professional Design Features**
- ✅ **CSS Animations:** Purposeful, attention-appropriate indicator speeds
- ✅ **Emoji-Free:** Clean, professional typography throughout
- ✅ **Clinical-Grade:** Suitable for academic presentations and publications
- ✅ **Responsive Layout:** Adapts to different screen sizes
- ✅ **Progressive Disclosure:** Accordion-style diagnostics prioritized by impact

---

## 🎯 Use Cases

### **Research & Education:**
- 📚 **Teaching Tool:** Demonstrate real-time biosignal processing and cognitive state detection
- 🔬 **Hypothesis Testing:** Validate literature parameters against synthetic data
- 📊 **Visualization:** Interactive platform for exploring physiological relationships
- 💡 **Proof-of-Concept:** Foundation for grant proposals and research plans

### **Technical Demonstration:**
- 🎨 **Shiny Development:** Example of professional dashboard design with `shinydashboard`
- ⚡ **Real-Time Processing:** Streaming data with reactive programming patterns
- 📈 **Plotly Integration:** Advanced visualizations (stacked area charts, custom tooltips)
- 🧪 **Evidence-Based Simulation:** Literature-validated parameter implementation

### **Future Clinical Extensions:**
- 🏥 **Sensor Integration:** Framework ready for real pupillometry/force sensors
- 🧠 **ML Enhancement:** Placeholder for actual trained models with real data
- 🔔 **Alert System:** Foundation for clinical decision support systems

---

## 🔬 Scientific Foundation

### **Evidence Base (16 Peer-Reviewed Studies):**

**Pupillometry:**
- Beatty, J. (1982). Task-evoked pupillary responses
- Kahneman, D., & Beatty, J. (1966). Pupil diameter and load
- Hess, E.H., & Polt, J.M. (1964). Pupil size in relation to interest
- Lowenstein, O., & Loewenfeld, I.E. (1964). Nervous control
- Granholm, E., et al. (1996). Pupillary responses index cognitive load

**Motor Control:**
- Johansson, R.S., & Westling, G. (1984). Grip force coordination
- Flanagan, J.R., & Wing, A.M. (1993). Modulation patterns
- Elble, R.J., & Koller, W.C. (1990). Tremor characteristics
- Riviere, C.N., et al. (1997). Surgical tremor analysis

**Cognitive Performance:**
- Warm, J.S., et al. (2008). Vigilance requires hard work
- Helton, W.S., & Warm, J.S. (2008). Signal salience decline
- Matthews, G., et al. (2010). Sustained attention to response task
- Hockey, G.R.J. (1997). Compensatory control model

📖 **Full citations and methodology:** [BIOSIGNAL_EVIDENCE_SUMMARY.md](BIOSIGNAL_EVIDENCE_SUMMARY.md)

---

## 📈 Future Directions

### **Data Collection Phase:**
- 🎥 **Surgical Video Analysis:** Motion tracking and procedure segmentation
- 📱 **Wearable Integration:** Smart surgical gloves with embedded force sensors
- 👁️ **Eye Tracking:** Commercial pupillometry systems (Tobii, SR Research)
- 🏥 **Clinical Partnerships:** Collaboration with surgical training centers

### **ML Development Phase:**
- 🧠 **Deep Learning:** LSTM/Transformer for temporal sequence modeling
- 📊 **Multi-Task Learning:** Simultaneous state and skill level prediction
- 🔄 **Transfer Learning:** Domain adaptation from simulation to real data
- ⚖️ **Calibration:** Surgeon-specific threshold tuning

### **Deployment & Validation:**
- 🚀 **Edge Computing:** Real-time inference on surgical console hardware
- 📋 **Clinical Trials:** IRB-approved prospective studies
- 📈 **Outcome Metrics:** Correlation with surgical performance and complications
- 🌐 **Open Science:** Public datasets and reproducible pipelines

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Mohammad Dastgheib**  
PhD Candidate, Cognitive Neuroscience  
Portfolio: [mdastgheib.com](https://mdastgheib.com)  
LinkedIn: [mohdasti](https://linkedin.com/in/mohdasti)  
GitHub: [@mohdasti](https://github.com/mohdasti)

---

## 🙏 Acknowledgments

This project synthesizes findings from 16 peer-reviewed studies in cognitive neuroscience, motor control, and human factors engineering. Special thanks to the research community for establishing the evidence base that made this simulation possible.

---

## 📸 Screenshots

![Live Dashboard](case_study/images/surgical_console_enhanced.png)
*Real-time biosignal monitoring with cognitive state detection*

For animated demonstrations, see the `case_study/images/` directory.
