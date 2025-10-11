#' Run Complete Demo Pipeline
#'
#' One-command script to generate demo data and launch the dashboard.
#' Perfect for testing, demos, and development.
#'
#' Usage:
#'   Rscript scripts/run_demo.R
#'   Rscript scripts/run_demo.R --quick  # 2-min simulation instead of 10
#'
#' @export

cat("╔═══════════════════════════════════════════════════════════╗\n")
cat("║  Surgical Cognitive Dashboard - Demo Pipeline            ║\n")
cat("╚═══════════════════════════════════════════════════════════╝\n\n")

# Parse arguments
args <- commandArgs(trailingOnly = TRUE)
quick_mode <- "--quick" %in% args

# Setup
suppressPackageStartupMessages({
  source("scripts/00_setup.R")
  source("R/load_params.R")
})

# Load parameters
params <- load_params("config/parameters.yml")

# Modify for quick demo if requested
if (quick_mode) {
  cat("⚡ Quick mode: 2-minute simulation\n\n")
  params$simulation$duration_s <- 120
  params$simulation$num_surgeons <- 3
} else {
  cat(sprintf("📊 Standard mode: %d-minute simulation\n\n", 
              params$simulation$duration_s / 60))
}

# Step 1: Check for existing demo data
demo_file <- "data/processed/simulation_enhanced.rds"
if (file.exists(demo_file)) {
  cat("📂 Found existing demo data. Options:\n")
  cat("  [1] Use existing data\n")
  cat("  [2] Regenerate data\n")
  cat("  [q] Quit\n\n")
  
  if (interactive()) {
    choice <- readline("Choice: ")
  } else {
    choice <- "1"  # Default to using existing in non-interactive mode
    cat("Choice: 1 (non-interactive)\n\n")
  }
  
  if (choice == "q") {
    cat("👋 Goodbye!\n")
    quit(save = "no")
  }
  
  regenerate <- choice == "2"
} else {
  regenerate <- TRUE
}

# Step 2: Generate demo data if needed
if (regenerate) {
  cat("═══════════════════════════════════════════════════════════\n")
  cat(" STEP 1/2: Generating Demo Data\n")
  cat("═══════════════════════════════════════════════════════════\n\n")
  
  # Temporarily modify parameters file for quick mode
  if (quick_mode) {
    temp_params_file <- tempfile(fileext = ".yml")
    params_list <- as.list(params)
    params_list$meta <- NULL
    class(params_list) <- "list"
    yaml::write_yaml(params_list, temp_params_file)
    
    # Run simulator with temp params
    system2("Rscript", c("-e", sprintf(
      "source('scripts/00_setup.R'); source('R/load_params.R'); params <- load_params('%s'); source('scripts/01_simulate_data_enhanced.R')",
      temp_params_file
    )))
    
    unlink(temp_params_file)
  } else {
    # Run standard simulator
    status <- system2("Rscript", "scripts/01_simulate_data_enhanced.R", 
                     stdout = TRUE, stderr = TRUE)
    
    if (!is.null(attr(status, "status")) && attr(status, "status") != 0) {
      cat("\n❌ Simulation failed. Check errors above.\n")
      quit(save = "no", status = 1)
    }
  }
  
  cat("\n✅ Demo data generated!\n\n")
} else {
  cat("✅ Using existing demo data\n\n")
}

# Step 3: Verify data exists
if (!file.exists(demo_file)) {
  cat("❌ Demo data file not found: ", demo_file, "\n")
  cat("   Try running: Rscript scripts/01_simulate_data_enhanced.R\n")
  quit(save = "no", status = 1)
}

# Load and summarize demo data
cat("═══════════════════════════════════════════════════════════\n")
cat(" Demo Data Summary\n")
cat("═══════════════════════════════════════════════════════════\n\n")

demo_data <- readRDS(demo_file)
signals <- demo_data$signals

cat(sprintf("Duration: %.1f minutes\n", max(signals$timestamp) / 60))
cat(sprintf("Surgeons: %d\n", length(unique(signals$surgeon_id))))
cat(sprintf("Total samples: %s\n", scales::comma(nrow(signals))))
cat(sprintf("Sampling rate: %d Hz\n", params$simulation$sampling_hz))

state_summary <- signals %>%
  count(cognitive_state) %>%
  mutate(pct = n / sum(n) * 100) %>%
  arrange(desc(n))

cat("\nCognitive State Distribution:\n")
for (i in seq_len(nrow(state_summary))) {
  cat(sprintf("  %s: %.1f%%\n", 
              state_summary$cognitive_state[i],
              state_summary$pct[i]))
}

cat(sprintf("\nBiosignal Ranges:\n"))
cat(sprintf("  Pupil: %.2f - %.2f mm\n", 
            min(signals$pupil_diameter_mm), max(signals$pupil_diameter_mm)))
cat(sprintf("  Grip: %.2f - %.2f N\n",
            min(signals$grip_force_N), max(signals$grip_force_N)))
cat(sprintf("  Tremor: %.0f - %.0f μm\n",
            min(signals$tremor_rms_um), max(signals$tremor_rms_um)))

cat("\n")

# Step 4: Launch Shiny app
cat("═══════════════════════════════════════════════════════════\n")
cat(" STEP 2/2: Launching Dashboard\n")
cat("═══════════════════════════════════════════════════════════\n\n")

cat("🚀 Starting Shiny app...\n")
cat("📍 URL: http://127.0.0.1:4162\n")
cat("⚠️  Press Ctrl+C to stop the server\n\n")

# Set environment variable to use demo data
Sys.setenv(DASHBOARD_DEMO_MODE = "true")
Sys.setenv(DASHBOARD_DEMO_FILE = demo_file)

# Launch app
tryCatch({
  shiny::runApp("shiny_app/app_working.R", 
                port = 4162, 
                host = "0.0.0.0",
                launch.browser = interactive())
}, interrupt = function(e) {
  cat("\n\n👋 Dashboard stopped.\n")
}, error = function(e) {
  cat("\n\n❌ Error launching dashboard:\n")
  cat(e$message, "\n")
  quit(save = "no", status = 1)
})

cat("\n✅ Demo complete!\n")

