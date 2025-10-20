#!/usr/bin/env Rscript
# Debug GT Table - Primary Biosignals Only
# Test sparklines specifically for Primary Biosignals

library(dplyr)
library(readr)
library(gt)
library(gtExtras)

cat("🔍 Debugging Primary Biosignals sparklines...\n")

# Load demo data
demo_data_path <- "inst/demo/demo_data_10min.csv"
data <- read_csv(demo_data_path, show_col_types = FALSE)

# Take snapshot from middle of timeline
snapshot_idx <- round(nrow(data) * 0.5)
trend_start <- max(1, snapshot_idx - 99)
trend_end <- snapshot_idx

cat("📊 Snapshot at index:", snapshot_idx, "\n")
cat("📊 Trend range:", trend_start, "to", trend_end, "\n")

# Create features_now with ONLY Primary Biosignals
features_now <- tibble(
  Feature = c(
    "Pupil Diameter",
    "HRV (RMSSD)",
    "Tremor RMS (8–12Hz)",
    "Grip Force"
  ),
  Value = c(
    data$pupil_mm[snapshot_idx],
    data$rmssd_ms[snapshot_idx],
    data$tremor_rms_um[snapshot_idx],
    data$grip_cv_pct[snapshot_idx]
  ),
  Unit = c("mm", "ms", "μm", "N"),
  Trend = list(
    data$pupil_mm[trend_start:trend_end],
    data$rmssd_ms[trend_start:trend_end],
    data$tremor_rms_um[trend_start:trend_end],
    data$grip_cv_pct[trend_start:trend_end]
  )
)

cat("📊 Features data:\n")
print(features_now)

# Create reference ranges
refs <- tibble(
  Feature = c("Pupil Diameter", "HRV (RMSSD)", "Tremor RMS (8–12Hz)", "Grip Force"),
  Unit = c("mm", "ms", "μm", "N"),
  baseline_mean = c(3.5, 40, 100, 3.0),
  baseline_sd = c(0.2, 10, 30, 1.0),
  normal_low = c(3.1, 30, 60, 1.5),
  normal_high = c(3.9, 60, 120, 5.0),
  alert_low = c(NA, 25, NA, NA),
  alert_high = c(4.8, NA, 180, 7.0),
  direction = c("high_worse", "low_worse", "high_worse", "high_worse"),
  evidence_ref = c("Kahneman & Beatty (1966)", "Task Force (1996)", "Andreu-Perez et al. (2021)", "Odik et al. (2021)"),
  pmid = c("5997497", "8737210", "33966234", "33668825")
)

# Build GT table step by step
cat("📊 Building GT table...\n")

# Step 1: Join with refs
df <- features_now %>%
  left_join(refs, by = c("Feature"), suffix = c(".live", ".ref"))

cat("📊 After join - Trend column preserved:\n")
cat("Trend lengths:", sapply(df$Trend, length), "\n")

# Step 2: Add computed columns
df <- df %>%
  mutate(
    Unit_display = Unit.live,
    Effect_Size = (Value - baseline_mean) / baseline_sd,
    Status = case_when(
      direction == "high_worse" & Value > alert_high ~ "Critical",
      direction == "high_worse" & Value > normal_high ~ "Elevated", 
      direction == "low_worse" & Value < alert_low ~ "Critical",
      direction == "low_worse" & Value < normal_low ~ "Elevated",
      TRUE ~ "Normal"
    ),
    Status_Icon = case_when(
      Status == "Normal" ~ "<span style='color:#27ae60'>●</span> Normal",
      Status == "Elevated" ~ "<span style='color:#f39c12'>▲</span> Elevated",
      Status == "Critical" ~ "<span style='color:#e74c3c'>⚠</span> Critical",
      TRUE ~ "·"
    ),
    Value_fmt = case_when(
      Unit.live == "mm" ~ sprintf("%.2f mm", Value),
      Unit.live == "μm" ~ sprintf("%.0f μm", Value),
      Unit.live == "N" ~ sprintf("%.2f N", Value),
      Unit.live == "ms" ~ sprintf("%.0f ms", Value),
      TRUE ~ as.character(signif(Value, 3))
    ),
    Effect_fmt = sprintf("%.2f", Effect_Size),
    Ref_CI = sprintf("%.2f–%.2f", baseline_mean - 1.96 * baseline_sd, baseline_mean + 1.96 * baseline_sd)
  )

cat("📊 Final data structure:\n")
cat("Trend column class:", class(df$Trend), "\n")
cat("Trend column length:", length(df$Trend), "\n")
for(i in 1:length(df$Trend)) {
  cat("Trend", i, "length:", length(df$Trend[[i]]), "\n")
}

# Step 3: Build GT table
g <- df %>%
  select(Feature, Value_fmt, Ref_CI, Effect_fmt, Status_Icon, Trend) %>%
  gt() %>%
  cols_label(
    Feature = "Feature",
    Value_fmt = html("Value<br><span style='font-size:.8em'>(Live)</span>"),
    Ref_CI = html("Literature<br><span style='font-size:.8em'>(≈95% CI)</span>"),
    Effect_fmt = html("Effect Size<br><span style='font-size:.8em'>(Cohen's d)</span>"),
    Status_Icon = "Status",
    Trend = "Trend"
  ) %>%
  fmt_markdown(columns = c(Ref_CI, Status_Icon))

cat("📊 GT table built, adding sparklines...\n")

# Step 4: Add sparklines
if (requireNamespace("gtExtras", quietly = TRUE)) {
  cat("📊 gtExtras available, adding sparklines...\n")
  tryCatch({
    if (exists("gt_plt_sparkline", where = asNamespace("gtExtras"))) {
      g <- g %>% gtExtras::gt_plt_sparkline(Trend, same_limit = FALSE)
      cat("✅ Sparklines added with gt_plt_sparkline\n")
    } else {
      g <- g %>% gtExtras::gt_sparkline(Trend, same_limit = FALSE)
      cat("✅ Sparklines added with gt_sparkline\n")
    }
  }, error = function(e) {
    cat("❌ Sparklines failed:", e$message, "\n")
    g <<- g %>%
      text_transform(
        locations = cells_body(columns = "Trend"),
        fn = function(x) rep("—", length(x))
      )
  })
} else {
  cat("❌ gtExtras not available\n")
}

# Save test table
dir.create("case_study/tables", showWarnings = FALSE, recursive = TRUE)
gt::gtsave(g, "case_study/tables/debug_primary_biosignals.html")

cat("✅ Debug table saved to: case_study/tables/debug_primary_biosignals.html\n")
cat("🎉 Debug complete!\n")
