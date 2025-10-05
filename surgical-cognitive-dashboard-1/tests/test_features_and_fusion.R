library(testthat); library(data.table)
test_that("AUCI not used & feature set is causal", {
  # Use relative path that works from both project root and tests directory
  features_path <- if (file.exists("data/processed/features.csv.gz")) {
    "data/processed/features.csv.gz"
  } else {
    "../data/processed/features.csv.gz"
  }
  f <- fread(features_path)
  expect_true(all(c("tonic_pupil_level_30s","grip_force_variability_15s","tremor_trend_10s",
                    "phasic_pupil_change_5s","blink_rate_60s","tool_switch_rate_120s",
                    "noise_mean_60s","noise_spike_count_60s") %in% names(f)))
  expect_true(all(!grepl("^event_", names(f))))
})
test_that("threshold sandbox responds", {
  # Use relative path that works from both project root and tests directory
  sandbox_path <- if (file.exists("data/diagnostics/threshold_sandbox.rds")) {
    "data/diagnostics/threshold_sandbox.rds"
  } else {
    "../data/diagnostics/threshold_sandbox.rds"
  }
  s <- readRDS(sandbox_path)
  # Make data available globally for the threshold function
  threshold_sandbox_data <<- s$data
  a <- s$threshold_fun(0.2, 0.7)
  b <- s$threshold_fun(0.8, 0.7)
  expect_true(!identical(a$cm_plot, b$cm_plot))
})
