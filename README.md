# The Surgeon's "Cognitive Black Box" 🧠

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Status: Proof of Concept](https://img.shields.io/badge/Status-Proof_of_Concept-blue.svg)](https://github.com/mohdasti/surgical-cognitive-dashboard)
[![R Version: 4.x](https://img.shields.io/badge/R-4.x-blue?logo=r)](https://www.r-project.org/)
[![Shiny App](https://img.shields.io/badge/Shiny-App-blue?logo=rstudio)](https://shiny.rstudio.com/)

A proof-of-concept dashboard for monitoring a surgeon's cognitive state in real-time using machine learning on simulated physiological and motor data.

**➡️ [View the Live Interactive Dashboard](http://127.0.0.1:4494)** *(when running locally)*

---

## 🚀 The Vision

Inspired by my work at **Surgical Safety Technologies (SST)** and grounded in my PhD research on the cognitive neuroscience of effort, this project addresses a critical challenge in patient safety: how can we proactively monitor a surgeon's cognitive state to mitigate the risks of fatigue and overload?

This R Shiny application simulates a "Cognitive Black Box"—a real-time analytics platform that translates complex data streams into simple, actionable insights.

![A mockup of a surgical console screen displaying a time-series plot of the surgeon's pupil dilation and grip force variability, indicating their cognitive state during a procedure.](case_study/images/surgical_console_enhanced.png)

---

## ✨ Key Features

* **Real-Time Simulation:** The dashboard simulates a live, second-by-second data stream from a multi-hour surgical procedure.
* **Multimodal Data Fusion:** Ingests and processes multiple data types simultaneously:
    * **Physiological:** Pupillometry data as a biomarker for neural gain and cognitive load.
    * **Motor Control:** A novel "grip force variability" metric, hypothesized to be a proxy for attentional lapses.
* **Machine Learning Core:** Uses a trained **XGBoost** model to classify the surgeon's cognitive state into one of four categories: *Optimal*, *High Load*, *Fatigued*, or *Attentional Lapse*.
* **Explainable AI (XAI):** Includes a dynamic "Why" panel that explains in plain language which physiological and motor signals are driving the current prediction, making the model interpretable and trustworthy for clinical use.

---

## 🛠️ Tech Stack

* **Language:** R
* **Core Packages:** `shiny`, `dplyr`, `xgboost`, `ggplot2`, `zoo` (for rolling calculations)
* **Development Environment:** RStudio / Cursor

---

## 📂 Project Structure

The repository is organized into four main directories:

/ (project root)
├── data/

│   ├── raw/

│   └── processed/

│

├── scripts/

│   ├── 01_simulate_data.R

│   ├── 02_feature_engineering.R

│   └── 03_train_model.R

│

├── shiny_app/

│   └── app.R

│

└── case_study/
    └── images/                     # Generated plots and model diagnostics

---

## 🧪 Data & Features

The system monitors and processes multiple physiological and behavioral signals:

### **Raw Sensor Data:**
- **Pupil Diameter (mm):** Continuous pupillometry measurements
- **Grip Force (Newtons):** Surgical instrument grip pressure
- **Instrument Tremor (Hz):** High-frequency tremor measurements

### **Engineered Features:**
- **Tonic Pupil Level (30s):** Rolling mean baseline pupil size
- **Grip Force Variability (15s):** Rolling standard deviation of grip pressure
- **Tremor Trend (10s):** Rolling mean of tremor frequency
- **Phasic Pupil Change (5s):** Task-evoked pupil responses
- **Pupil Diameter Lag (5s):** Previous pupil state for temporal context

## 📊 Model Performance

Our XGBoost classifier achieves:
- **Overall Accuracy:** 99.58%
- **Cohen's Kappa:** 0.993
- **Cross-Validation:** 3-fold CV with hyperparameter tuning

**Per-Class Performance:**
- **Optimal State:** 100% sensitivity, 100% specificity
- **High Load:** 99.9% sensitivity, 100% specificity  
- **Fatigued:** 99.9% sensitivity, 99.4% specificity
- **Attentional Lapse:** 25% sensitivity, 100% specificity*

*Note: Attentional lapses are rare events (0.4% prevalence), prioritizing specificity over sensitivity.*

---

## 🏁 Getting Started

To run this application locally:

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/mohdasti/surgical-cognitive-dashboard.git](https://github.com/mohdasti/surgical-cognitive-dashboard.git)
    cd surgical-cognitive-dashboard
    ```

2.  **Install dependencies:**
    Install the required R packages:
    ```r
    install.packages(c("shiny", "tidyverse", "xgboost", "caret", "zoo", "DT"))
    ```

3.  **Run the Pipeline (Optional):**
    If you want to re-generate the data and re-train the model, run the scripts in the `/scripts` directory in numerical order.
    ```r
    source("scripts/01_simulate_data.R")
    source("scripts/02_feature_engineering.R")
    source("scripts/03_train_model.R")
    ```

4.  **Launch the Shiny App:**
    ```r
    shiny::runApp("shiny_app/app.R")
    ```

---

## 💻 Dashboard Interface

The application features two main panels:

### **🏥 Live Surgical Dashboard**
- **Real-time plots:** Pupil diameter and grip force over time
- **Cognitive state indicator:** Dynamic visual state with moving dial
- **Speed controls:** 1x, 10x, 50x, or 100x simulation speed
- **Progress tracking:** Video-style progress bar with time remaining
- **Clinical interpretation:** Dynamic "Why" panel explaining current predictions

### **🔬 ML Model Diagnostics**
- **Prediction probabilities:** Live confidence scores for all cognitive states
- **Feature values:** Real-time table of engineered feature values
- **Feature importance:** Static visualization of model decision drivers

---

## 🎯 Use Cases

This proof-of-concept demonstrates applications in:

- **Surgical Safety:** Early warning system for cognitive overload
- **Training & Assessment:** Objective measurement of surgical skill development
- **Research:** Platform for studying cognitive load during complex procedures
- **Quality Improvement:** Data-driven insights into surgical performance

---

## 🔬 Research Background

This project is inspired by:
- **Cognitive Neuroscience:** Pupillometry as a biomarker for neural effort
- **Motor Control Theory:** Grip force variability as an indicator of attentional state
- **Human Factors Engineering:** Real-time monitoring for safety-critical environments

---

## 📈 Future Directions

- **Real sensor integration:** Connect with actual pupillometry and force sensors
- **Advanced ML models:** Explore deep learning architectures for temporal data
- **Clinical validation:** Partner with surgical training centers for real-world testing
- **Multi-surgeon monitoring:** Extend to team-based surgical environments

---

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Mohammad Dastgheib**  
PhD Candidate, Cognitive Neuroscience  
Portfolio: [mdastgheib.com](https://mdastgheib.com)  
LinkedIn: [mohdasti](https://linkedin.com/in/mohdasti)
