#' Theme and Color Consistency Tests
#'
#' @description
#' Guards against "plot drift" by enforcing stable color palettes
#' and theme properties. These tests ensure screenshots continue
#' to match case study visuals.

library(testthat)

# ============================================================================
# State Color Palette Stability
# ============================================================================

test_that("state palette is stable", {
  source("../../R/theme_md.R")
  
  # State colors must match case study palette
  expect_equal(unname(md_colors$state["Normal"]), "#0ea5b7")
  expect_equal(unname(md_colors$state["High Load"]), "#bc3c29")
  expect_equal(unname(md_colors$state["Attentional Lapse"]), "#6b7280")
})

test_that("semantic colors are stable", {
  source("../../R/theme_md.R")
  
  # Semantic colors for consistent UI
  expect_equal(md_colors$accent, "#1f9bb6")
  expect_equal(md_colors$ok, "#27ae60")
  expect_equal(md_colors$warn, "#f39c12")
  expect_equal(md_colors$crit, "#e74c3c")
})

test_that("typography colors are stable", {
  source("../../R/theme_md.R")
  
  # Typography and UI colors
  expect_equal(md_colors$ink, "#0b1526")
  expect_equal(md_colors$muted, "#4b5563")
  expect_equal(md_colors$border, "#e5e7eb")
  expect_equal(md_colors$bg, "#f7f9fc")
  expect_equal(md_colors$card, "#ffffff")
})

# ============================================================================
# Theme Function Validation
# ============================================================================

test_that("theme_md function exists and returns ggplot theme", {
  source("../../R/theme_md.R")
  
  expect_true(exists("theme_md"))
  expect_true(is.function(theme_md))
  
  # Should return a theme object
  theme_obj <- theme_md()
  expect_s3_class(theme_obj, "theme")
})

test_that("scale helpers exist", {
  source("../../R/theme_md.R")
  
  expect_true(exists("scale_state_color"))
  expect_true(exists("scale_state_fill"))
  expect_true(is.function(scale_state_color))
  expect_true(is.function(scale_state_fill))
})

# ============================================================================
# Plot Function Existence
# ============================================================================

test_that("live monitor plot functions exist", {
  source("../../R/plots_live_monitor.R")
  
  expect_true(exists("plot_tepr_hrv_demo"))
  expect_true(exists("plot_feat_by_state_demo"))
  expect_true(is.function(plot_tepr_hrv_demo))
  expect_true(is.function(plot_feat_by_state_demo))
})

test_that("diagnostics plot functions exist", {
  source("../../R/plots_diagnostics.R")
  
  expect_true(exists("plot_calibration_lapse_demo"))
  expect_true(exists("plot_prob_dists_demo"))
  expect_true(exists("plot_stability_lapse_demo"))
  expect_true(is.function(plot_calibration_lapse_demo))
  expect_true(is.function(plot_prob_dists_demo))
  expect_true(is.function(plot_stability_lapse_demo))
})

# ============================================================================
# Feature Computation Functions
# ============================================================================

test_that("RMSSD computation is available", {
  source("../../R/feature_hrv.R")
  
  expect_true(exists("compute_rmssd"))
  expect_true(exists("rolling_rmssd"))
  
  # Test basic functionality
  ibi_ms <- c(1000, 1010, 990, 1005, 995)
  rmssd <- compute_rmssd(ibi_ms)
  
  expect_type(rmssd, "double")
  expect_true(!is.na(rmssd))
  expect_true(rmssd > 0)
})

test_that("calibration metrics computation is available", {
  source("../../R/calibration_metrics.R")
  
  expect_true(exists("calib_metrics"))
  
  # Test basic functionality
  set.seed(42)
  p_hat <- runif(100)
  y <- rbinom(100, 1, p_hat)
  
  m <- calib_metrics(p_hat, y, bins = 10)
  
  expect_type(m, "list")
  expect_true("df" %in% names(m))
  expect_true("ece" %in% names(m))
  expect_true("mce" %in% names(m))
  expect_true("brier" %in% names(m))
  
  # Metrics should be numeric and in valid ranges
  expect_type(m$ece, "double")
  expect_type(m$mce, "double")
  expect_type(m$brier, "double")
  expect_true(m$ece >= 0 && m$ece <= 1)
  expect_true(m$mce >= 0 && m$mce <= 1)
  expect_true(m$brier >= 0 && m$brier <= 1)
})

# ============================================================================
# Demo Data Validation
# ============================================================================

test_that("demo data exists and has required columns", {
  demo_file <- "../../inst/demo/demo_data_10min.csv"
  
  expect_true(file.exists(demo_file))
  
  demo_data <- read.csv(demo_file)
  
  # Required columns for showcase script
  required_cols <- c("time_s", "time_min", "cognitive_state", 
                     "pupil_mm", "rmssd_ms", "grip_cv_pct", "tremor_rms_um")
  
  for (col in required_cols) {
    expect_true(col %in% names(demo_data), 
                info = sprintf("Column '%s' missing from demo data", col))
  }
  
  # Data should have reasonable size
  expect_true(nrow(demo_data) > 100)
  expect_true(nrow(demo_data) < 10000)
})

test_that("demo data has valid cognitive states", {
  demo_file <- "../../inst/demo/demo_data_10min.csv"
  demo_data <- read.csv(demo_file)
  
  valid_states <- c("Normal", "High Load", "Attentional Lapse")
  expect_true(all(demo_data$cognitive_state %in% valid_states))
  
  # Should have all three states represented
  state_counts <- table(demo_data$cognitive_state)
  expect_true(all(valid_states %in% names(state_counts)))
})

# ============================================================================
# Color Contrast (Accessibility)
# ============================================================================

test_that("state colors have reasonable contrast on white background", {
  source("../../R/theme_md.R")
  
  # Helper function to compute luminance
  hex_to_rgb <- function(hex) {
    as.numeric(c(
      strtoi(substr(hex, 2, 3), 16L),
      strtoi(substr(hex, 4, 5), 16L),
      strtoi(substr(hex, 6, 7), 16L)
    )) / 255
  }
  
  relative_luminance <- function(rgb) {
    rgb_adj <- ifelse(rgb <= 0.03928, rgb / 12.92, ((rgb + 0.055) / 1.055)^2.4)
    0.2126 * rgb_adj[1] + 0.7152 * rgb_adj[2] + 0.0722 * rgb_adj[3]
  }
  
  contrast_ratio <- function(color1, color2) {
    L1 <- relative_luminance(hex_to_rgb(color1))
    L2 <- relative_luminance(hex_to_rgb(color2))
    (max(L1, L2) + 0.05) / (min(L1, L2) + 0.05)
  }
  
  # State colors should have minimum 2.5:1 contrast on white
  # (Relaxed for UI components and data visualization)
  # Note: Case study palette prioritizes visual consistency over strict WCAG
  white <- "#ffffff"
  
  expect_true(contrast_ratio(md_colors$state["Normal"], white) >= 2.5)
  expect_true(contrast_ratio(md_colors$state["High Load"], white) >= 2.5)
  expect_true(contrast_ratio(md_colors$state["Attentional Lapse"], white) >= 2.5)
})

# ============================================================================
# Guard Against Common Mistakes
# ============================================================================

test_that("no accidental uppercase in state names", {
  source("../../R/theme_md.R")
  
  # State names should match exactly (case-sensitive)
  expect_true("Normal" %in% names(md_colors$state))
  expect_true("High Load" %in% names(md_colors$state))
  expect_true("Attentional Lapse" %in% names(md_colors$state))
  
  # Should not have all-caps or other variations
  expect_false("NORMAL" %in% names(md_colors$state))
  expect_false("HIGH LOAD" %in% names(md_colors$state))
})

test_that("color values start with # and are valid hex", {
  source("../../R/theme_md.R")
  
  all_colors <- unlist(md_colors, use.names = FALSE)
  
  for (color in all_colors) {
    expect_match(color, "^#[0-9a-fA-F]{6}$", 
                info = sprintf("Color '%s' is not valid hex", color))
  }
})

