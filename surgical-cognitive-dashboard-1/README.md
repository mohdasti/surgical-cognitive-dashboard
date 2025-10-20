# 🧠 Surgical Cognitive Dashboard

A real-time biosignal monitoring system for robotic-assisted surgery, featuring advanced cognitive state detection using machine learning and physiological signal analysis.

![Dashboard Preview](case_study/images/Live_Surgical_Dashboard.gif)

## 🎯 Overview

The Surgical Cognitive Dashboard monitors cognitive workload during robotic-assisted surgery using multiple biosignals:

- **Pupil Diameter (TEPR)** - Task-evoked pupillary response
- **Heart Rate Variability (HRV)** - RMSSD-based cognitive load detection  
- **Motor Steadiness** - Tremor and grip force variability
- **Blink Patterns** - Fatigue and attention state indicators

The system provides real-time alerts and comprehensive diagnostics for surgical team awareness.

## 🚀 Quick Start

### Prerequisites

- R 4.5+ with `renv` package manager
- Required R packages (automatically installed via `renv`)

### Installation

```bash
# Clone the repository
git clone https://github.com/mohdasti/surgical-cognitive-dashboard.git
cd surgical-cognitive-dashboard/surgical-cognitive-dashboard-1

# Install dependencies
R -e "renv::restore()"

# Launch the dashboard
cd shiny_app
R -e "shiny::runApp('app_working.R', port=8888)"
```

### Demo Mode

For quick testing without full data processing:

```bash
# Run in demo mode
DEMO_MODE=1 R -e "shiny::runApp('app_working.R', port=8888)"
```

## 🎨 Key Features

### Real-Time Monitoring
- **Cognitive Load Index** - Composite metric combining pupil dilation and HRV
- **Motor Steadiness Index** - Tremor and grip force variability assessment
- **State Probability Distribution** - Real-time cognitive state classification
- **Sparkline Visualizations** - Compact trend displays

### Machine Learning Diagnostics
- **Leave-One-Surgeon-Out (LOSO)** cross-validation
- **Probability Calibration** - ECE, MCE, and Brier score analysis
- **Feature Importance** - Partial dependence plots
- **Model Performance** - Comprehensive evaluation metrics

### Interactive Controls
- **Threshold Adjustment** - Real-time sensitivity tuning
- **Alert Management** - Configurable notification system
- **Feature Toggle** - Show/hide detailed biosignal tables

## 📊 Architecture

### Core Components

```
├── shiny_app/           # Main Shiny application
│   ├── app_working.R    # Primary dashboard interface
│   └── modules/         # Reusable UI components
├── R/                   # R functions and utilities
│   ├── theme_md.R       # Visual theme and colors
│   ├── feature_hrv.R    # HRV computation functions
│   └── *_utils.R        # Specialized utility functions
├── scripts/             # Data processing and model training
│   ├── 00_setup.R       # Environment setup
│   ├── 01_simulate_data_enhanced.R  # Enhanced data simulation
│   ├── 03_train_model.R # XGBoost model training
│   └── render_showcase.R # Screenshot generation
├── data/                # Processed datasets and models
│   ├── processed/       # Feature-engineered data
│   └── diagnostics/    # Model evaluation artifacts
└── docs/               # Organized documentation
```

### Data Flow

1. **Simulation** → Enhanced biosignal data generation
2. **Feature Engineering** → 24-feature HRV model preparation
3. **Model Training** → LOSO XGBoost with Platt calibration
4. **Real-Time Inference** → Live cognitive state prediction
5. **Visualization** → Interactive dashboard updates

## 🧪 Model Details

### Feature Engineering (24 Features)

**HRV Features (12):**
- Time-domain: RMSSD, SDNN, pNN50 (30s, 60s, 120s windows)
- Frequency-domain: HF/LF power, LF/HF ratio (60s windows)
- Non-linear: Sample entropy, Poincaré SD1 (60s windows)
- Baseline-adjusted: Z-scores and percentage drops

**Other Biosignals (9):**
- Pupil: TEPR, tonic level, dilation rate
- Blink: Rate and variability
- Motor: Grip force, tremor RMS (8-12 Hz)
- Context: Ambient noise, time-on-task

**Interaction Terms (3):**
- TEPR × HRV drop
- Blink rate × HRV drop
- Cross-feature combinations

### Model Performance

- **Algorithm:** XGBoost with multi-class softmax
- **Validation:** Leave-One-Surgeon-Out (LOSO)
- **Calibration:** Platt scaling per class
- **Target Classes:** Normal, High Load, Attentional Lapse

## 📁 Documentation Structure

```
docs/
├── architecture/        # System design decisions
├── features/           # Feature specifications
│   ├── biosignals/     # Physiological signal details
│   ├── controls/       # Interactive control systems
│   └── diagnostics/    # ML model evaluation
├── implementation/     # Development logs and guides
│   ├── logs/          # Implementation history
│   ├── prompts/       # Development prompts
│   ├── summaries/     # Feature summaries
│   └── status/        # Implementation status
└── status/            # Bug fixes and resolutions
    ├── fixes/         # Issue resolutions
    └── resolutions/   # Problem solutions
```

## 🛠️ Development

### Adding New Features

1. **Create feature functions** in `R/feature_*.R`
2. **Update model training** in `scripts/03_train_model.R`
3. **Add UI components** in `shiny_app/app_working.R`
4. **Update documentation** in `docs/features/`

### Testing

```bash
# Run unit tests
R -e "testthat::test_dir('tests')"

# Generate showcase screenshots
DEMO_MODE=1 Rscript scripts/render_showcase.R
```

### Code Style

- Follow R style guidelines
- Use `theme_md()` for consistent plotting
- Document functions with roxygen2
- Maintain organized file structure

## 📈 Performance

### Simulation Speed
- **Fast startup:** 20ms intervals for first 60 seconds
- **Normal operation:** 200ms intervals for remaining data
- **Total load time:** ~6-10 seconds (vs. 10+ minutes previously)

### Model Accuracy
- **LOSO validation** ensures surgeon-independent performance
- **Calibrated probabilities** provide reliable uncertainty estimates
- **Real-time inference** maintains <100ms latency

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Follow the development guidelines
4. Submit a pull request

## 📄 License

This project is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)** - see the [LICENSE](LICENSE) file for details.

Key points of AGPL-3.0:
- ✅ Free to use, modify, and distribute
- ✅ Source code must be made available
- ✅ Network use is distribution (SaaS provision requires source disclosure)
- ✅ Modifications must also be licensed under AGPL-3.0

## 📚 References

- **HRV Analysis:** Task Force guidelines and ultra-short window validation
- **Pupillometry:** Kahneman & Beatty (1966) TEPR foundations
- **Surgical Workload:** Systematic reviews of cognitive load in surgery
- **Machine Learning:** XGBoost and calibration best practices

## 🆘 Support

For questions or issues:
- Check the [documentation](docs/)
- Review [implementation logs](docs/implementation/logs/)
- Open an issue on GitHub

---

**Built with ❤️ for surgical safety and cognitive monitoring**