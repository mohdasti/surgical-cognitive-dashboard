# Surgical Cognitive Dashboard App

A standalone deployment-ready Shiny application for real-time surgical cognitive state monitoring.

## 🚀 Quick Start

1. **Install Dependencies:**
   ```r
   source("00_setup.R")
   ```

2. **Launch App:**
   ```r
   shiny::runApp()
   ```

## 📦 What's Included

- **Real-time Dashboard**: Live cognitive state monitoring with 5Hz updates
- **ML Diagnostics**: 6-tab diagnostic interface with model analysis
- **Demo Data**: Pre-computed models and sample data for immediate testing
- **Event Logging**: Optional CSV logging for post-hoc analysis

## 🏗️ Architecture

```
/
├── app.R                    # Main Shiny application
├── 00_setup.R              # Runtime setup and dependencies
├── config/
│   └── config.yml          # Configuration parameters
├── R/
│   ├── streaming_inference.R  # CogEngine class
│   └── diagnostics_module.R   # Diagnostics UI/Server
├── data/
│   ├── processed/          # Demo data and models
│   └── diagnostics/        # Pre-computed artifacts
├── www/                    # Static assets (optional)
├── renv/                   # Package management
└── renv.lock              # Package versions
```

## 🎯 Features

- **Real-time Streaming**: Simulated surgical data stream
- **Multi-Model Architecture**: XGBoost + Isolation Forest + Platt Scaling
- **Interactive Diagnostics**: Calibration analysis and threshold tuning
- **Causal Features**: 8 strictly causal features with segment-aware baselines
- **LOSO Validation**: Leave-One-Surgeon-Out cross-validation

## 🔧 Configuration

Edit `config/config.yml` to adjust:
- Alert thresholds
- Feature window sizes
- Model parameters
- UI settings

## 📊 Demo Data

The app includes pre-computed:
- **Synthetic Data**: 3-hour simulated surgical procedures
- **Trained Models**: XGBoost and Isolation Forest models
- **Diagnostics**: Calibration plots and evaluation metrics
- **Artifacts**: SHAP plots and partial dependence visualizations

## 🚀 Deployment

This app is ready for deployment to:
- **RStudio Connect**
- **Shiny Server**
- **ShinyApps.io**
- **Docker containers**

## 📝 License

MIT License - see LICENSE file for details.
