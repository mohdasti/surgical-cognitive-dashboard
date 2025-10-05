# Deployment Guide for ShinyApps.io

## 🚀 One-Command Deployment

### Prerequisites

1. **ShinyApps.io Account**: Sign up at https://www.shinyapps.io/
2. **Authentication Token**: Get your token from Account Settings → Tokens

### Environment Variables

Set these environment variables before running the deployment:

```bash
export SHINYAPPS_ACCOUNT="your-account-name"
export SHINYAPPS_TOKEN="your-token"
export SHINYAPPS_SECRET="your-secret"
```

### Deploy

```bash
Rscript deploy.R
```

## 📦 Bundle Size Optimization

The `.rscignore` file excludes:
- `renv/library/` - Package libraries (rebuilt on server)
- `data/logs/` - Runtime logs
- `tests/` - Test files
- `case_study/` - Development artifacts
- Development scripts (keeps only `00_setup.R`)

**Included Demo Data:**
- `data/processed/sim_stream.csv.gz` - 32K rows of demo data
- `data/processed/xgb_loso_models.rds` - Trained models
- `data/processed/lapse_iso.rds` - Isolation Forest model
- `data/diagnostics/*.rds` - Pre-computed artifacts

## 🔧 Troubleshooting

### Common Issues:

1. **Authentication Error**: Verify environment variables are set correctly
2. **Bundle Too Large**: Check `.rscignore` file excludes unnecessary files
3. **Package Dependencies**: Ensure all required packages are in `00_setup.R`

### Manual Deployment:

If the script fails, you can deploy manually:

```r
library(rsconnect)
rsconnect::setAccountInfo(name="your-account", token="your-token", secret="your-secret")
rsconnect::deployApp(appName="surgical-cognitive-dashboard")
```

## 📊 App Features

Once deployed, the app provides:
- **Real-time Dashboard**: Live cognitive state monitoring
- **ML Diagnostics**: 6-tab diagnostic interface
- **Interactive Controls**: Threshold tuning and logging
- **Demo Data**: Pre-loaded with 32K rows of simulated data

## 🔗 Public URL

After successful deployment, you'll get a URL like:
`https://your-account.shinyapps.io/surgical-cognitive-dashboard/`

This URL can be embedded in iframes on Netlify or other platforms.
