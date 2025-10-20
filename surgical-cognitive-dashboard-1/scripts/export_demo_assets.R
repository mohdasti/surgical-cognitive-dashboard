#!/usr/bin/env Rscript
#' Export Demo Assets
#'
#' Creates static images and demo data matching the app's look and feel
#' for use in portfolio/documentation.
#'
#' Usage:
#'   Rscript --vanilla scripts/export_demo_assets.R  # Recommended
#'   Rscript scripts/export_demo_assets.R            # Requires renv setup
#'
#' Outputs:
#'   - assets/demo/monitor_02.png - Biosignal time series (TEPR, RMSSD)
#'   - assets/demo/monitor_03.png - Feature values with zones
#'   - assets/demo/calibration.png - Reliability diagram
#'   - assets/demo/prob_dists.png - Probability distributions by state
#'   - assets/demo/stability.png - Model stability over time
#'   - Thumbnails (if magick available): thumb_*.jpg (480px, quality 70)
#'
#' Colors match ui_constants.R (Okabe-Ito palette):
#'   - Normal/Optimal: #009E73 (green)
#'   - High Load: #E69F00 (amber)
#'   - Attentional Lapse: #D55E00 (red-orange)

# ============================================================================
# Setup
# ============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(tidyr)
  library(tibble)
})

# Check for optional packages
has_patchwork <- requireNamespace("patchwork", quietly = TRUE)
if (has_patchwork) {
  library(patchwork)
}
has_gridExtra <- requireNamespace("gridExtra", quietly = TRUE)

# Source theme for consistent styling
tryCatch({
  source("R/theme_md.R")
  source("R/calibration_metrics.R")
}, error = function(e) {
  # Fallback if theme_md.R not available
  md_colors <- list(
    state = c("Normal"="#0ea5b7","High Load"="#bc3c29","Attentional Lapse"="#6b7280")
  )
  theme_md <- function() ggplot2::theme_minimal()
  calib_metrics <- function(p_hat, y, bins = 10) {
    # Simple fallback
    list(df = data.frame(p = c(0.5), y = c(0.5), n = c(1)), 
         ece = 0, mce = 0, brier = 0)
  }
})

# Define colors directly (from ui_constants.R) to avoid dependencies
COLORS <- list(
  optimal = "#009E73",      # Green - Normal/Optimal state
  high_load = "#E69F00",    # Amber - High cognitive load
  lapse = "#D55E00",        # Red-Orange - Attentional lapse
  fatigue = "#0072B2",      # Blue - Fatigue indicator
  background_dark = "#2c3e50",
  text_primary = "#2c3e50",
  text_secondary = "#7f8c8d"
)

cat("🎨 Export Demo Assets\n")
cat("====================\n\n")

# Create output directory
out_dir <- "assets/demo"
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
  cat("✓ Created directory:", out_dir, "\n")
} else {
  cat("✓ Using existing directory:", out_dir, "\n")
}

# Check for magick
has_magick <- requireNamespace("magick", quietly = TRUE)
if (has_magick) {
  cat("✓ magick available - will generate thumbnails\n")
} else {
  cat("⚠ magick not available - skipping thumbnails\n")
}

cat("\n")

# ============================================================================
# 1. Simulate Small 10-Min Demo Segment
# ============================================================================

cat("📊 Simulating 10-min demo segment...\n")

set.seed(42)

# Simulation parameters
duration_s <- 600  # 10 minutes
fs <- 5  # 5 Hz sampling
n_samples <- duration_s * fs
time_s <- seq(0, duration_s - 1/fs, by = 1/fs)
time_min <- time_s / 60

# Create cognitive state sequence with realistic transitions
state <- rep("Normal", n_samples)

# Add High Load episodes (2 episodes, 60-90s each)
high_load_1_start <- 120 * fs  # 2 min in
high_load_1_dur <- 75 * fs     # 75 seconds
state[high_load_1_start:(high_load_1_start + high_load_1_dur)] <- "High Load"

high_load_2_start <- 420 * fs  # 7 min in
high_load_2_dur <- 60 * fs     # 60 seconds
state[high_load_2_start:(high_load_2_start + high_load_2_dur)] <- "High Load"

# Add Attentional Lapse (1 brief episode, 8s)
lapse_start <- 540 * fs  # 9 min in
lapse_dur <- 8 * fs
state[lapse_start:(lapse_start + lapse_dur)] <- "Attentional Lapse"

state <- factor(state, levels = c("Normal", "High Load", "Attentional Lapse"))

# Simulate TEPR (Task-Evoked Pupillary Response)
pupil_baseline <- 4.0
pupil_fatigue_drop <- 0.0003 * time_s  # Slight decrease over time

# Add TEPR spikes on state transitions
tepr <- numeric(n_samples)
transitions <- which(diff(c(1, as.numeric(state))) != 0)
for (trans_idx in transitions) {
  if (state[trans_idx] %in% c("High Load", "Attentional Lapse")) {
    # TEPR: rise time ~1.2s, decay ~2s
    rise_samples <- 6  # 1.2s at 5Hz
    decay_samples <- 10  # 2s at 5Hz
    magnitude <- runif(1, 0.35, 0.5)
    
    # Create TEPR curve
    start_idx <- trans_idx
    peak_idx <- start_idx + rise_samples
    end_idx <- min(n_samples, peak_idx + decay_samples)
    
    if (peak_idx <= n_samples) {
      # Rise phase
      tepr[start_idx:peak_idx] <- seq(0, magnitude, length.out = rise_samples + 1)
      # Decay phase
      if (end_idx > peak_idx) {
        tepr[(peak_idx+1):end_idx] <- seq(magnitude, 0, length.out = end_idx - peak_idx)
      }
    }
  }
}

pupil_mm <- pupil_baseline - pupil_fatigue_drop + tepr + 
  0.04 * sin(2 * pi * 0.2 * time_s) +  # Hippus oscillation
  rnorm(n_samples, 0, 0.03)  # Noise

pupil_mm <- pmax(2.5, pmin(6.5, pupil_mm))  # Physiological bounds

# Simulate RMSSD (HRV metric)
rmssd_baseline <- 42  # ms
rmssd <- case_when(
  state == "Normal" ~ rnorm(n_samples, rmssd_baseline, 3),
  state == "High Load" ~ rnorm(n_samples, rmssd_baseline * 0.65, 3),  # -35% under load
  state == "Attentional Lapse" ~ rnorm(n_samples, rmssd_baseline * 0.55, 4)
)
rmssd <- pmax(15, pmin(80, rmssd))

# Simulate Grip Force Variability (CV%)
grip_cv_baseline <- 8.5
grip_cv <- case_when(
  state == "Normal" ~ rnorm(n_samples, grip_cv_baseline, 0.5),
  state == "High Load" ~ rnorm(n_samples, grip_cv_baseline * 1.15, 0.6),
  state == "Attentional Lapse" ~ rnorm(n_samples, grip_cv_baseline * 1.25, 0.8)
)
grip_cv <- pmax(4, pmin(20, grip_cv))

# Simulate Tremor RMS
tremor_baseline <- 88  # µm
tremor_growth <- 0.02 * time_s  # Time-on-task increase
tremor_rms <- case_when(
  state == "Normal" ~ tremor_baseline + tremor_growth + rnorm(n_samples, 0, 5),
  state == "High Load" ~ (tremor_baseline + tremor_growth) * 1.15 + rnorm(n_samples, 0, 6),
  state == "Attentional Lapse" ~ (tremor_baseline + tremor_growth) * 1.28 + rnorm(n_samples, 0, 8)
)
tremor_rms <- pmax(40, pmin(200, tremor_rms))

# Simulate predicted probabilities (mock ML output)
prob_normal <- case_when(
  state == "Normal" ~ rbeta(n_samples, 8, 2),
  state == "High Load" ~ rbeta(n_samples, 3, 5),
  state == "Attentional Lapse" ~ rbeta(n_samples, 1, 9)
)

prob_high_load <- case_when(
  state == "Normal" ~ rbeta(n_samples, 2, 8),
  state == "High Load" ~ rbeta(n_samples, 8, 2),
  state == "Attentional Lapse" ~ rbeta(n_samples, 2, 5)
)

prob_lapse <- case_when(
  state == "Normal" ~ rbeta(n_samples, 1, 20),
  state == "High Load" ~ rbeta(n_samples, 1, 10),
  state == "Attentional Lapse" ~ rbeta(n_samples, 8, 2)
)

# Normalize probabilities
prob_sum <- prob_normal + prob_high_load + prob_lapse
prob_normal <- prob_normal / prob_sum
prob_high_load <- prob_high_load / prob_sum
prob_lapse <- prob_lapse / prob_sum

# Create demo data frame
demo_data <- tibble(
  time_s = time_s,
  time_min = time_min,
  cognitive_state = state,
  pupil_mm = pupil_mm,
  rmssd_ms = rmssd,
  grip_cv_pct = grip_cv,
  tremor_rms_um = tremor_rms,
  prob_normal = prob_normal,
  prob_high_load = prob_high_load,
  prob_lapse = prob_lapse
)

cat("  ✓ Generated", n_samples, "samples (10 min at 5 Hz)\n")
cat("  ✓ State distribution:\n")
print(table(demo_data$cognitive_state))

# ============================================================================
# 2. MONITOR_02: Biosignal Time Series (TEPR + RMSSD)
# ============================================================================

cat("\n📈 Generating monitor_02.png (TEPR + RMSSD time series)...\n")

# Prepare data for plotting
plot_data <- demo_data %>%
  select(time_min, cognitive_state, pupil_mm, rmssd_ms) %>%
  pivot_longer(cols = c(pupil_mm, rmssd_ms), names_to = "metric", values_to = "value")

# Create state ribbons for background
state_changes <- tibble(
  time_min = time_min,
  state = as.character(state)
) %>%
  mutate(
    state_num = as.numeric(factor(state, levels = c("Normal", "High Load", "Attentional Lapse"))),
    change = state_num != lag(state_num, default = 0)
  ) %>%
  filter(change) %>%
  mutate(
    xend = lead(time_min, default = max(time_min)),
    ymin = -Inf,
    ymax = Inf,
    fill_color = case_when(
      state == "Normal" ~ COLORS$optimal,
      state == "High Load" ~ COLORS$high_load,
      state == "Attentional Lapse" ~ COLORS$lapse
    )
  )

# TEPR plot
p1 <- ggplot(demo_data, aes(x = time_min, y = pupil_mm)) +
  # State background ribbons
  geom_rect(
    data = state_changes,
    aes(xmin = time_min, xmax = xend, ymin = 2.5, ymax = 6.5, fill = I(fill_color)),
    alpha = 0.15,
    inherit.aes = FALSE
  ) +
  geom_line(color = "#2c3e50", linewidth = 0.7) +
  geom_hline(yintercept = pupil_baseline, linetype = "dashed", color = "#7f8c8d", alpha = 0.6) +
  scale_y_continuous(limits = c(2.5, 6.5), breaks = seq(2.5, 6.5, 0.5)) +
  labs(
    title = "Task-Evoked Pupillary Response (TEPR)",
    subtitle = "Pupil diameter shows phasic dilations during high cognitive load",
    x = NULL,
    y = "Pupil Diameter (mm)"
  ) +
  theme_minimal(base_size = 12) + theme_md() +
  theme(
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  )

# RMSSD plot
p2 <- ggplot(demo_data, aes(x = time_min, y = rmssd_ms)) +
  geom_rect(
    data = state_changes,
    aes(xmin = time_min, xmax = xend, ymin = 15, ymax = 80, fill = I(fill_color)),
    alpha = 0.15,
    inherit.aes = FALSE
  ) +
  geom_line(color = "#2c3e50", linewidth = 0.7) +
  geom_hline(yintercept = rmssd_baseline, linetype = "dashed", color = "#7f8c8d", alpha = 0.6) +
  annotate("rect", xmin = 0, xmax = 10, ymin = 40, ymax = 80, 
           fill = COLORS$optimal, alpha = 0.1, color = NA) +
  annotate("text", x = 0.3, y = 75, label = "Normal HRV", 
           hjust = 0, size = 3, color = COLORS$optimal, fontface = "bold") +
  scale_y_continuous(limits = c(15, 80), breaks = seq(20, 80, 20)) +
  labs(
    title = "Heart Rate Variability (RMSSD)",
    subtitle = "HRV decreases during cognitive load",
    x = "Time (min)",
    y = "RMSSD (ms)"
  ) +
  theme_minimal(base_size = 12) + theme_md() +
  theme(
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  )

# Combine and save plots
if (has_patchwork) {
  monitor_02 <- p1 / p2 + 
    plot_annotation(
      title = "🧠 Live Biosignal Monitor - 10-Minute Surgical Segment",
      subtitle = "Real-time monitoring of cognitive state via pupillometry and HRV",
      theme = theme(
        plot.title = element_text(face = "bold", size = 16, hjust = 0.5, color = "#2c3e50"),
        plot.subtitle = element_text(size = 12, hjust = 0.5, color = "#7f8c8d"),
        plot.background = element_rect(fill = "white", color = NA)
      )
    )
  ggsave(
    file.path(out_dir, "monitor_02.png"),
    monitor_02,
    width = 10,
    height = 7,
    dpi = 300,
    bg = "white"
  )
} else if (has_gridExtra) {
  # Fallback: use gridExtra
  monitor_02 <- gridExtra::arrangeGrob(
    p1, p2,
    ncol = 1,
    top = grid::textGrob(
      "🧠 Live Biosignal Monitor - 10-Minute Surgical Segment",
      gp = grid::gpar(fontface = "bold", fontsize = 16, col = "#2c3e50")
    )
  )
  ggsave(
    file.path(out_dir, "monitor_02.png"),
    monitor_02,
    width = 10,
    height = 7,
    dpi = 300,
    bg = "white"
  )
} else {
  # Save plots separately
  cat("  ⚠ patchwork/gridExtra not available - saving plots separately\n")
  ggsave(file.path(out_dir, "monitor_02a_tepr.png"), p1, width = 10, height = 3.5, dpi = 300, bg = "white")
  ggsave(file.path(out_dir, "monitor_02b_rmssd.png"), p2, width = 10, height = 3.5, dpi = 300, bg = "white")
}

cat("  ✓ Saved monitor_02.png\n")

# ============================================================================
# 3. MONITOR_03: Feature Values with Reference Zones
# ============================================================================

cat("\n📊 Generating monitor_03.png (Feature zones)...\n")

# Calculate summary statistics
feature_summary <- demo_data %>%
  group_by(cognitive_state) %>%
  summarise(
    pupil_mean = mean(pupil_mm),
    rmssd_mean = mean(rmssd_ms),
    grip_cv_mean = mean(grip_cv_pct),
    tremor_mean = mean(tremor_rms_um),
    .groups = "drop"
  ) %>%
  pivot_longer(
    cols = -cognitive_state,
    names_to = "feature",
    values_to = "value"
  ) %>%
  mutate(
    feature_label = case_when(
      feature == "pupil_mean" ~ "Pupil Diameter (mm)",
      feature == "rmssd_mean" ~ "RMSSD (ms)",
      feature == "grip_cv_mean" ~ "Grip CV (%)",
      feature == "tremor_mean" ~ "Tremor RMS (µm)"
    )
  )

# Plot feature zones
p_zones <- ggplot(feature_summary, aes(x = cognitive_state, y = value, fill = cognitive_state)) +
  geom_col(position = "dodge", width = 0.7, alpha = 0.9) +
  facet_wrap(~ feature_label, scales = "free_y", ncol = 2) +
  scale_fill_manual(
    values = c(
      "Normal" = COLORS$optimal,
      "High Load" = COLORS$high_load,
      "Attentional Lapse" = COLORS$lapse
    )
  ) +
  labs(
    title = "Feature Values by Cognitive State",
    subtitle = "Average biosignal characteristics across states",
    x = NULL,
    y = "Mean Value",
    fill = "Cognitive State"
  ) +
  theme_minimal(base_size = 12) + theme_md() +
  theme(
    strip.text = element_text(face = "bold", size = 11),
    legend.position = "bottom",
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  )

ggsave(
  file.path(out_dir, "monitor_03.png"),
  p_zones,
  width = 10,
  height = 7,
  dpi = 300,
  bg = "white"
)

cat("  ✓ Saved monitor_03.png\n")

# ============================================================================
# 4. CALIBRATION: Reliability Diagram
# ============================================================================

cat("\n📐 Generating calibration.png (Reliability diagram)...\n")

# Create calibration data using standardized metrics
demo_data_calib <- demo_data %>%
  mutate(lapse_true = as.integer(cognitive_state == "Attentional Lapse"))

m <- calib_metrics(p_hat = demo_data$prob_lapse, y = demo_data_calib$lapse_true, bins = 10)

p_calib <- ggplot(m$df, aes(x = p, y = y)) +
  geom_point(aes(size = n), alpha = 0.85, colour = md_colors$warn) +
  geom_line(colour = md_colors$warn, linewidth = 1) +
  geom_abline(slope = 1, intercept = 0, linetype = 2, colour = md_colors$muted) +
  scale_size_area(max_size = 10, guide = "none") +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  labs(
    title = "Probability Calibration — Attentional Lapse",
    subtitle = sprintf("ECE=%.3f · MCE=%.3f · Brier=%.3f", m$ece, m$mce, m$brier),
    x = "Predicted Probability",
    y = "Observed Frequency"
  ) +
  theme_minimal(base_size = 12) + theme_md() +
  theme(
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  )

ggsave(
  file.path(out_dir, "calibration.png"),
  p_calib,
  width = 8,
  height = 6,
  dpi = 300,
  bg = "white"
)

cat("  ✓ Saved calibration.png\n")

# ============================================================================
# 5. PROB_DISTS: Probability Distributions by State
# ============================================================================

cat("\n📊 Generating prob_dists.png (Probability distributions)...\n")

# Probability distributions by true state (using lapse probability only)
prob_dist_data <- demo_data %>%
  select(cognitive_state, prob_lapse) %>%
  rename(true_state = cognitive_state)

p_dists <- ggplot(prob_dist_data, aes(x = prob_lapse, fill = true_state)) +
  geom_histogram(bins = 35, alpha = 0.85, position = "identity") +
  facet_wrap(~ true_state, ncol = 1, scales = "free_y") +
  scale_state_fill() +
  scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  labs(
    title = "Predicted Probability Distributions by True State",
    subtitle = "Lapse probability predictions grouped by actual cognitive state",
    x = "P(Attentional Lapse)",
    y = "Count"
  ) +
  theme_minimal(base_size = 12) + theme_md() +
  theme(
    strip.text = element_text(face = "bold", size = 11),
    legend.position = "none",
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  )

ggsave(
  file.path(out_dir, "prob_dists.png"),
  p_dists,
  width = 8,
  height = 10,
  dpi = 300,
  bg = "white"
)

cat("  ✓ Saved prob_dists.png\n")

# ============================================================================
# 6. STABILITY: Model Stability Over Time
# ============================================================================

cat("\n📉 Generating stability.png (Model stability)...\n")

# Calculate rolling metrics
window_size <- 30  # 30 samples = 6 seconds at 5Hz

demo_data_stability <- demo_data %>%
  arrange(time_s) %>%
  mutate(
    lapse_true = as.integer(cognitive_state == "Attentional Lapse"),
    # Rolling mean of predicted probabilities
    prob_lapse_smooth = zoo::rollmean(prob_lapse, k = window_size, fill = NA, align = "right"),
    prob_high_load_smooth = zoo::rollmean(prob_high_load, k = window_size, fill = NA, align = "right"),
    # Rolling standard deviation
    prob_lapse_sd = zoo::rollapply(prob_lapse, width = window_size, FUN = sd, fill = NA, align = "right"),
    # Prediction (using threshold)
    pred_lapse = as.integer(prob_lapse >= 0.3)
  )

p_stability_top <- ggplot(demo_data_stability, aes(x = time_min)) +
  geom_rect(
    data = state_changes,
    aes(xmin = time_min, xmax = xend, ymin = 0, ymax = 1, fill = I(fill_color)),
    alpha = 0.15,
    inherit.aes = FALSE
  ) +
  geom_line(aes(y = prob_lapse, color = "Raw"), alpha = 0.4, linewidth = 0.5) +
  geom_line(aes(y = prob_lapse_smooth, color = "Smoothed (30pt)"), linewidth = 1.2) +
  geom_hline(yintercept = 0.3, linetype = "dashed", color = md_colors$muted, alpha = 0.6) +
  scale_color_manual(
    values = c("Raw" = md_colors$muted, "Smoothed (30pt)" = md_colors$warn),
    name = NULL
  ) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  labs(
    title = "Prediction Stability Over Time",
    subtitle = "Raw vs. smoothed lapse probabilities with rolling uncertainty",
    x = NULL,
    y = "P(Lapse)"
  ) +
  theme_minimal(base_size = 12) + theme_md() +
  theme(
    legend.position.inside = c(0.15, 0.88),
    legend.background = element_rect(fill = "white", color = md_colors$border),
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  )

p_stability_bottom <- ggplot(demo_data_stability, aes(x = time_min)) +
  geom_rect(
    data = state_changes,
    aes(xmin = time_min, xmax = xend, ymin = 0, ymax = 0.5, fill = I(fill_color)),
    alpha = 0.15,
    inherit.aes = FALSE
  ) +
  geom_line(aes(y = prob_lapse_sd), color = md_colors$accent, linewidth = 0.9) +
  labs(
    title = "Rolling Prediction Uncertainty",
    x = "Time (min)",
    y = "SD(P(Lapse))"
  ) +
  theme_minimal(base_size = 12) + theme_md() +
  theme(
    panel.background = element_rect(fill = "white", color = NA),
    plot.background = element_rect(fill = "white", color = NA)
  )

if (has_patchwork) {
  p_stability <- p_stability_top / p_stability_bottom +
    plot_layout(heights = c(2, 1))
  ggsave(
    file.path(out_dir, "stability.png"),
    p_stability,
    width = 10,
    height = 7,
    dpi = 300,
    bg = "white"
  )
} else if (has_gridExtra) {
  p_stability <- gridExtra::arrangeGrob(
    p_stability_top, p_stability_bottom,
    ncol = 1,
    heights = c(2, 1)
  )
  ggsave(
    file.path(out_dir, "stability.png"),
    p_stability,
    width = 10,
    height = 7,
    dpi = 300,
    bg = "white"
  )
} else {
  # Save plots separately
  cat("  ⚠ patchwork/gridExtra not available - saving plots separately\n")
  ggsave(file.path(out_dir, "stability_top.png"), p_stability_top, width = 10, height = 5, dpi = 300, bg = "white")
  ggsave(file.path(out_dir, "stability_bottom.png"), p_stability_bottom, width = 10, height = 2.5, dpi = 300, bg = "white")
}

cat("  ✓ Saved stability.png\n")

# ============================================================================
# 7. Generate Thumbnails (if magick available)
# ============================================================================

if (has_magick) {
  cat("\n🖼️  Generating thumbnails...\n")
  
  images <- c("monitor_02", "monitor_03", "calibration", "prob_dists", "stability")
  
  for (img_name in images) {
    src_path <- file.path(out_dir, paste0(img_name, ".png"))
    thumb_path <- file.path(out_dir, paste0("thumb_", img_name, ".jpg"))
    
    img <- magick::image_read(src_path)
    thumb <- magick::image_resize(img, "480x")
    magick::image_write(thumb, thumb_path, quality = 70, format = "jpg")
    
    cat(sprintf("  ✓ %s (480px, quality 70)\n", basename(thumb_path)))
  }
}

# ============================================================================
# 8. Export Demo Data CSV
# ============================================================================

cat("\n💾 Exporting demo data CSV...\n")

demo_data_export <- demo_data %>%
  select(
    time_s,
    time_min,
    cognitive_state,
    pupil_mm,
    rmssd_ms,
    grip_cv_pct,
    tremor_rms_um
  )

readr::write_csv(demo_data_export, file.path(out_dir, "demo_data_10min.csv"))
cat("  ✓ Saved demo_data_10min.csv (", nrow(demo_data_export), "rows )\n")

# ============================================================================
# Summary
# ============================================================================

cat("\n")
cat("✅ Export complete!\n")
cat("==================\n\n")
cat("Generated files in", out_dir, ":\n")
cat("  📊 monitor_02.png      - TEPR + RMSSD time series\n")
cat("  📊 monitor_03.png      - Feature values by state\n")
cat("  📐 calibration.png     - Reliability diagram\n")
cat("  📊 prob_dists.png      - Probability distributions\n")
cat("  📉 stability.png       - Model stability over time\n")

if (has_magick) {
  cat("\n  🖼️  Thumbnails (480px, quality 70):\n")
  cat("     - thumb_monitor_02.jpg\n")
  cat("     - thumb_monitor_03.jpg\n")
  cat("     - thumb_calibration.jpg\n")
  cat("     - thumb_prob_dists.jpg\n")
  cat("     - thumb_stability.jpg\n")
}

cat("\n  💾 demo_data_10min.csv - Simulated 10-min segment\n")

cat("\n📋 Next steps:\n")
cat("   Copy assets/demo/* to your portfolio repo's /assets/demo/\n")
cat("   All images use the app's color scheme (Okabe-Ito palette)\n\n")

