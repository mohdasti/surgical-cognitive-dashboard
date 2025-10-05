# Test deployment script (doesn't actually deploy)
# This shows what the deployment script would do

cat("=== Testing Deployment Script ===\n")

# Test 1: Check rsconnect package
cat("1. Checking rsconnect package...\n")
if (!requireNamespace("rsconnect", quietly=TRUE)) {
  cat("   Would install rsconnect package\n")
} else {
  cat("   ✓ rsconnect package available\n")
}

# Test 2: Check environment variables
cat("2. Checking environment variables...\n")
acct   <- Sys.getenv("SHINYAPPS_ACCOUNT")
token  <- Sys.getenv("SHINYAPPS_TOKEN")
secret <- Sys.getenv("SHINYAPPS_SECRET")

cat("   SHINYAPPS_ACCOUNT:", ifelse(nzchar(acct), "SET", "NOT SET"), "\n")
cat("   SHINYAPPS_TOKEN:", ifelse(nzchar(token), "SET", "NOT SET"), "\n")
cat("   SHINYAPPS_SECRET:", ifelse(nzchar(secret), "SET", "NOT SET"), "\n")

# Test 3: Check app structure
cat("3. Checking app structure...\n")
required_files <- c("app.R", "00_setup.R", "config/config.yml", 
                   "R/streaming_inference.R", "R/diagnostics_module.R",
                   "data/processed/sim_stream.csv.gz",
                   "data/processed/xgb_loso_models.rds",
                   "data/processed/lapse_iso.rds")

for (file in required_files) {
  if (file.exists(file)) {
    cat("   ✓", file, "\n")
  } else {
    cat("   ✗", file, "MISSING\n")
  }
}

# Test 4: Check bundle size
cat("4. Checking bundle size...\n")
data_files <- list.files("data", recursive=TRUE, full.names=TRUE)
total_size <- sum(file.size(data_files), na.rm=TRUE)
cat("   Data files total size:", round(total_size/1024/1024, 2), "MB\n")

# Test 5: Simulate deployment
cat("5. Deployment simulation...\n")
if (nzchar(acct) && nzchar(token) && nzchar(secret)) {
  cat("   Would deploy to shinyapps.io as 'surgical-cognitive-dashboard'\n")
  cat("   URL would be: https://", acct, ".shinyapps.io/surgical-cognitive-dashboard/\n", sep="")
} else {
  cat("   Cannot deploy - environment variables not set\n")
  cat("   Set SHINYAPPS_ACCOUNT, SHINYAPPS_TOKEN, SHINYAPPS_SECRET\n")
}

cat("\n=== Test Complete ===\n")
