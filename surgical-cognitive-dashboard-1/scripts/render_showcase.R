#!/usr/bin/env Rscript
#' Render Showcase Screenshots
#'
#' @description
#' Generates showcase images using DEMO mode and the same plotting functions
#' as the live app. Ensures visual consistency between screenshots and app.
#'
#' Usage:
#'   Rscript scripts/render_showcase.R
#'   # Or with DEMO_MODE env var:
#'   DEMO_MODE=1 Rscript scripts/render_showcase.R

# ============================================================================
# Setup
# ============================================================================

cat("🎬 Render Showcase Screenshots\n")
cat("================================\n\n")

# Enable DEMO mode
options(surgdash.demo = TRUE)
Sys.setenv(DEMO_MODE = "1")

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
})

# Source theme and plotting functions
source("R/theme_md.R")
source("R/calibration_metrics.R")
source("R/plots_live_monitor.R")
source("R/plots_diagnostics.R")

# Create output directory
dir.create("showcase", showWarnings = FALSE)
cat("✓ Output directory: showcase/\n\n")

# ============================================================================
# Load Demo Data
# ============================================================================

cat("📂 Loading demo data...\n")

demo_file <- "inst/demo/demo_data_10min.csv"
if (!file.exists(demo_file)) {
  stop("Demo data not found: ", demo_file, 
       "\nRun: Rscript --vanilla scripts/export_demo_assets.R")
}

demo_data <- read.csv(demo_file)
cat(sprintf("  ✓ Loaded %d rows (%.1f min at %.0f Hz)\n", 
            nrow(demo_data), 
            max(demo_data$time_min),
            nrow(demo_data) / max(demo_data$time_s)))

# ============================================================================
# Generate Mock Probabilities (if not in data)
# ============================================================================

if (!"prob_lapse" %in% names(demo_data)) {
  cat("\n⚙️  Generating mock probabilities...\n")
  
  set.seed(42)
  demo_data <- demo_data %>%
    mutate(
      # Simulate probabilities based on cognitive state
      prob_normal = case_when(
        cognitive_state == "Normal" ~ rbeta(n(), 8, 2),
        cognitive_state == "High Load" ~ rbeta(n(), 3, 5),
        cognitive_state == "Attentional Lapse" ~ rbeta(n(), 1, 9)
      ),
      prob_high_load = case_when(
        cognitive_state == "Normal" ~ rbeta(n(), 2, 8),
        cognitive_state == "High Load" ~ rbeta(n(), 8, 2),
        cognitive_state == "Attentional Lapse" ~ rbeta(n(), 2, 5)
      ),
      prob_lapse = case_when(
        cognitive_state == "Normal" ~ rbeta(n(), 1, 20),
        cognitive_state == "High Load" ~ rbeta(n(), 1, 10),
        cognitive_state == "Attentional Lapse" ~ rbeta(n(), 8, 2)
      )
    ) %>%
    mutate(
      # Normalize to sum to 1
      prob_sum = prob_normal + prob_high_load + prob_lapse,
      prob_normal = prob_normal / prob_sum,
      prob_high_load = prob_high_load / prob_sum,
      prob_lapse = prob_lapse / prob_sum
    ) %>%
    select(-prob_sum)
  
  cat("  ✓ Generated prob_normal, prob_high_load, prob_lapse\n")
}

# ============================================================================
# 1. Live Monitor - TEPR + HRV Time Series
# ============================================================================

cat("\n📈 Generating live_tepr_hrv.png...\n")

w <- 1280
h <- 780
dpi <- 144

p_tepr_hrv <- plot_tepr_hrv_demo(demo_data)

# Handle both patchwork object and list return
if (is.list(p_tepr_hrv) && !inherits(p_tepr_hrv, "ggplot")) {
  # patchwork not available - save separately or use gridExtra
  if (requireNamespace("gridExtra", quietly = TRUE)) {
    combined <- gridExtra::arrangeGrob(
      p_tepr_hrv$tepr, 
      p_tepr_hrv$hrv, 
      ncol = 1
    )
    ggsave(
      "showcase/live_tepr_hrv.png", 
      plot = combined, 
      width = w / dpi, 
      height = h / dpi, 
      dpi = dpi, 
      bg = "white"
    )
  } else {
    # Save separately
    cat("  ⚠ patchwork/gridExtra not available - saving plots separately\n")
    ggsave("showcase/live_tepr.png", plot = p_tepr_hrv$tepr, 
           width = w / dpi, height = (h / dpi) / 2, dpi = dpi, bg = "white")
    ggsave("showcase/live_hrv.png", plot = p_tepr_hrv$hrv,
           width = w / dpi, height = (h / dpi) / 2, dpi = dpi, bg = "white")
  }
} else {
  # patchwork available or single ggplot - save normally
  ggsave(
    "showcase/live_tepr_hrv.png", 
    plot = p_tepr_hrv, 
    width = w / dpi, 
    height = h / dpi, 
    dpi = dpi, 
    bg = "white"
  )
}

cat("  ✓ Saved showcase/live_tepr_hrv.png\n")

# ============================================================================
# 2. Feature Values by Cognitive State
# ============================================================================

cat("\n📊 Generating feat_by_state.png...\n")

p_feat_by_state <- plot_feat_by_state_demo(demo_data)

ggsave(
  "showcase/feat_by_state.png", 
  plot = p_feat_by_state, 
  width = w / dpi, 
  height = h / dpi, 
  dpi = dpi, 
  bg = "white"
)

cat("  ✓ Saved showcase/feat_by_state.png\n")

# ============================================================================
# 3. Calibration - Reliability Diagram
# ============================================================================

cat("\n📐 Generating calibration_lapse.png...\n")

# Prepare calibration data
lapse_true <- as.integer(demo_data$cognitive_state == "Attentional Lapse")

p_calib <- plot_calibration_lapse_demo(
  p_hat = demo_data$prob_lapse,
  y = lapse_true,
  bins = 10
)

ggsave(
  "showcase/calibration_lapse.png", 
  plot = p_calib, 
  width = 1000 / 144, 
  height = 760 / 144, 
  dpi = 144, 
  bg = "white"
)

cat("  ✓ Saved showcase/calibration_lapse.png\n")

# ============================================================================
# 4. Probability Distributions by True State
# ============================================================================

cat("\n📊 Generating prob_dists.png...\n")

prob_dist_data <- demo_data %>%
  select(cognitive_state, prob_lapse) %>%
  rename(true_state = cognitive_state)

p_prob_dists <- plot_prob_dists_demo(prob_dist_data, bins = 35)

ggsave(
  "showcase/prob_dists.png", 
  plot = p_prob_dists, 
  width = 800 / 144, 
  height = 1000 / 144, 
  dpi = 144, 
  bg = "white"
)

cat("  ✓ Saved showcase/prob_dists.png\n")

# ============================================================================
# 5. Prediction Stability Over Time
# ============================================================================

cat("\n📉 Generating stability_lapse.png...\n")

# Calculate rolling metrics
window_size <- 30  # 30 samples

stability_data <- demo_data %>%
  arrange(time_s) %>%
  mutate(
    prob_lapse_smooth = zoo::rollmean(prob_lapse, k = window_size, fill = NA, align = "right"),
    prob_lapse_sd = zoo::rollapply(prob_lapse, width = window_size, FUN = sd, fill = NA, align = "right")
  )

p_stability <- plot_stability_lapse_demo(stability_data)

# Handle both patchwork object and list return
if (is.list(p_stability) && !inherits(p_stability, "ggplot")) {
  # patchwork not available - save separately or use gridExtra
  if (requireNamespace("gridExtra", quietly = TRUE)) {
    combined <- gridExtra::arrangeGrob(
      p_stability$top, 
      p_stability$bottom, 
      ncol = 1,
      heights = c(2, 1)
    )
    ggsave(
      "showcase/stability_lapse.png", 
      plot = combined, 
      width = w / dpi, 
      height = h / dpi, 
      dpi = dpi, 
      bg = "white"
    )
  } else {
    # Save separately
    cat("  ⚠ patchwork/gridExtra not available - saving plots separately\n")
    ggsave("showcase/stability_top.png", plot = p_stability$top,
           width = w / dpi, height = (h / dpi) * 0.67, dpi = dpi, bg = "white")
    ggsave("showcase/stability_bottom.png", plot = p_stability$bottom,
           width = w / dpi, height = (h / dpi) * 0.33, dpi = dpi, bg = "white")
  }
} else {
  # patchwork available - save normally
  ggsave(
    "showcase/stability_lapse.png", 
    plot = p_stability, 
    width = w / dpi, 
    height = h / dpi, 
    dpi = dpi, 
    bg = "white"
  )
}

cat("  ✓ Saved showcase/stability_lapse.png\n")

# ============================================================================
# Summary
# ============================================================================

cat("\n✅ Showcase generation complete!\n")
cat("==================================\n\n")
cat("Generated files:\n")
cat("  📈 showcase/live_tepr_hrv.png      - TEPR + HRV time series\n")
cat("  📊 showcase/feat_by_state.png      - Feature values by state\n")
cat("  📐 showcase/calibration_lapse.png  - Reliability diagram\n")
cat("  📊 showcase/prob_dists.png         - Probability distributions\n")
cat("  📉 showcase/stability_lapse.png    - Prediction stability\n")
cat("\n💡 All plots use the same code as the live app!\n")
cat("   Copy these to your portfolio/case study repo.\n\n")

