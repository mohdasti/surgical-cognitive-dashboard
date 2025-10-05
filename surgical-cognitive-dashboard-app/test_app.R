# Test script to verify the standalone app works
cat("Testing standalone app...\n")

# Test 1: Load setup
cat("1. Loading setup...\n")
source("00_setup.R")
cat("✓ Setup loaded successfully\n")

# Test 2: Load modules
cat("2. Loading modules...\n")
source("R/streaming_inference.R")
source("R/diagnostics_module.R")
cat("✓ Modules loaded successfully\n")

# Test 3: Test CogEngine initialization
cat("3. Testing CogEngine...\n")
engine <- CogEngine$new(CFG)
cat("✓ CogEngine initialized successfully\n")

# Test 4: Test data loading
cat("4. Testing data loading...\n")
stream <- data.table::fread("data/processed/sim_stream.csv.gz")
cat("✓ Data loaded successfully (", nrow(stream), " rows)\n")

# Test 5: Test model loading
cat("5. Testing model loading...\n")
models <- readRDS("data/processed/xgb_loso_models.rds")
iso_model <- readRDS("data/processed/lapse_iso.rds")
cat("✓ Models loaded successfully\n")

# Test 6: Test diagnostics loading
cat("6. Testing diagnostics loading...\n")
eval_data <- readRDS("data/diagnostics/loso_eval.rds")
calib_data <- readRDS("data/diagnostics/calibration.rds")
artifacts <- readRDS("data/diagnostics/model_artifacts.rds")
cat("✓ Diagnostics loaded successfully\n")

cat("\n🎉 All tests passed! The standalone app is ready to run.\n")
cat("To start the app, run: shiny::runApp()\n")
