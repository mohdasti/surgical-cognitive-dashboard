# 🚀 Deploy to ShinyApps.io (2 minutes)

## Step 1: Get ShinyApps.io Account

1. **Go to [shinyapps.io](https://www.shinyapps.io/)**
2. **Sign up for a free account** (or sign in if you have one)
3. **Go to Account → Tokens**
4. **Copy your credentials:**
   - Account name
   - Token
   - Secret

## Step 2: Set Environment Variables

```bash
cd /Users/mohdasti/Documents/GitHub/surgical-cognitive-dashboard/surgical-cognitive-dashboard-app

export SHINYAPPS_ACCOUNT="your-account-name"
export SHINYAPPS_TOKEN="your-token-here"
export SHINYAPPS_SECRET="your-secret-here"
```

## Step 3: Deploy

```bash
Rscript quick_deploy.R
```

## Step 4: Get Your URL

Your app will be available at:
`https://your-account-name.shinyapps.io/surgical-cognitive-dashboard/`

## Alternative: Manual Deploy

If the script doesn't work, you can deploy manually:

```bash
Rscript -e "
library(rsconnect)
rsconnect::setAccountInfo(name='your-account', token='your-token', secret='your-secret')
rsconnect::deployApp(appName='surgical-cognitive-dashboard', forceUpdate=TRUE)
"
```

## What You'll Get

- ✅ **Live Shiny app** with real-time cognitive monitoring
- ✅ **ML Model Diagnostics** with 6 comprehensive tabs
- ✅ **Public URL** you can share immediately
- ✅ **Automatic HTTPS** and custom domain support
- ✅ **Free tier** available (5 apps, 25 hours/month)

## Troubleshooting

If you get errors:
1. Make sure you're in the `surgical-cognitive-dashboard-app` directory
2. Check that your credentials are set correctly
3. Try running `Rscript -e "library(rsconnect); rsconnect::accounts()"` to verify your account
