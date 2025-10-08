message("▶ Running preflight...")
source("scripts/preflight.R")

# minimal sanity checks on modules & config
stopifnot(file.exists("R/streaming_inference.R"))
stopifnot(file.exists("R/diagnostics_module.R"))
stopifnot(file.exists("config/config.yml"))

message("🚀 Launching full app locally...")
shiny::runApp("shiny_app", launch.browser = TRUE)
