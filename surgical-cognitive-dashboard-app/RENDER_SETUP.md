# 🚀 Deploy to Render.com (3 minutes)

## Step 1: Go to Render.com

1. **Visit [render.com](https://render.com)**
2. **Sign up with your GitHub account**
3. **Click "New" → "Web Service"**

## Step 2: Connect Your Repository

1. **Select "Build and deploy from a Git repository"**
2. **Connect your GitHub account**
3. **Select repository:** `mohdasti/surgical-cognitive-dashboard`
4. **Choose the `surgical-cognitive-dashboard-app` directory**

## Step 3: Configure Build Settings

Render will auto-detect the `render.yaml` file, but you can also set manually:

- **Name:** `surgical-cognitive-dashboard`
- **Environment:** `R`
- **Build Command:** `Rscript -e 'if(!requireNamespace("renv", quietly=TRUE)) install.packages("renv"); renv::restore(prompt=FALSE)'`
- **Start Command:** `Rscript -e 'shiny::runApp(port=$PORT, host="0.0.0.0")'`
- **Plan:** Free

## Step 4: Deploy

1. **Click "Create Web Service"**
2. **Wait 3-5 minutes for build to complete**
3. **Get your URL:** `https://surgical-cognitive-dashboard.onrender.com`

## What You'll Get

- ✅ **Live Shiny app** with real-time cognitive monitoring
- ✅ **ML Model Diagnostics** with 6 comprehensive tabs
- ✅ **Public URL** you can share immediately
- ✅ **Automatic HTTPS** and custom domain support
- ✅ **Free tier** available (750 hours/month)

## Troubleshooting

If build fails:
1. Check the build logs in Render dashboard
2. Make sure all files are committed to GitHub
3. Verify the `render.yaml` file is in the app directory
