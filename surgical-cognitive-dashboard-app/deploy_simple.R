#!/usr/bin/env Rscript
# Simple deployment script without renv dependency

cat("=== Deploying Simple Shiny App ===\n")

# Install required packages if not available
required_packages <- c("shiny", "yaml", "tidyverse", "data.table", "DT")

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("Installing", pkg, "...\n")
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

# Load rsconnect
if (!requireNamespace("rsconnect", quietly = TRUE)) {
  install.packages("rsconnect", repos = "https://cloud.r-project.org")
}

library(rsconnect)

# Set account info
rsconnect::setAccountInfo(
  name = '0z6q8c-mohammad0dastgheib', 
  token = '233AF363930F2FAA1F671FB18FEA4295', 
  secret = 'VWgmEglRQC+BPriZ7OEUc81Fv0RaUfUYKlUB23Ee'
)

# Deploy the simple app
cat("Deploying simple app...\n")
rsconnect::deployApp(
  appName = "surgical-cognitive-dashboard-simple",
  appFiles = c("app_simple.R", "config/config.yml"),
  appPrimaryDoc = "app_simple.R",
  forceUpdate = TRUE
)

cat("Deployment complete!\n")
cat("Your simple app is available at: https://0z6q8c-mohammad0dastgheib.shinyapps.io/surgical-cognitive-dashboard-simple/\n")
