#!/usr/bin/env Rscript
# Quick deployment script for ShinyApps.io

cat("=== Surgical Cognitive Dashboard - Quick Deploy ===\n")

# Check if rsconnect is available
if (!requireNamespace("rsconnect", quietly = TRUE)) {
  cat("Installing rsconnect...\n")
  install.packages("rsconnect", repos = "https://cloud.r-project.org")
}

library(rsconnect)

# Get credentials from environment or prompt
acct <- Sys.getenv("SHINYAPPS_ACCOUNT")
token <- Sys.getenv("SHINYAPPS_TOKEN") 
secret <- Sys.getenv("SHINYAPPS_SECRET")

if (nzchar(acct) && nzchar(token) && nzchar(secret)) {
  cat("Using environment variables for credentials\n")
} else {
  cat("Please set your ShinyApps.io credentials:\n")
  cat("export SHINYAPPS_ACCOUNT='your-account-name'\n")
  cat("export SHINYAPPS_TOKEN='your-token-here'\n") 
  cat("export SHINYAPPS_SECRET='your-secret-here'\n")
  cat("Then run this script again.\n")
  quit(status = 1)
}

# Set account info
rsconnect::setAccountInfo(name = acct, token = token, secret = secret)

# Deploy the app
cat("Deploying to ShinyApps.io...\n")
rsconnect::deployApp(
  appName = "surgical-cognitive-dashboard",
  forceUpdate = TRUE,
  launch.browser = TRUE
)

cat("Deployment complete! Your app should be available at:\n")
cat("https://", acct, ".shinyapps.io/surgical-cognitive-dashboard/\n", sep = "")
