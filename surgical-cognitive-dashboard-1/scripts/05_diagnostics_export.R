source("scripts/00_setup.R")
source("R/theme_md.R")
source("R/calibration_metrics.R")
feats <- data.table::fread("data/processed/features.csv.gz") |> as_tibble()
models <- readRDS("data/processed/xgb_loso_models.rds"); mdl <- models[[1]]
eval  <- readRDS("data/diagnostics/loso_eval.rds")

feat_cols <- mdl$feat_cols; bst <- mdl$bst; glm_cal <- mdl$glm_cal
X <- as.matrix(feats[, feat_cols])
raw <- matrix(predict(bst, X), ncol=length(CFG$labels), byrow=TRUE); colnames(raw) <- CFG$labels
y <- feats$cognitive_state
lab_bin <- as.integer(y=="Attentional Lapse")
lapse_p <- predict(glm_cal, data.frame(p=raw[,"Attentional Lapse"]), type="response")

# Calibration using standardized metrics
m <- calib_metrics(p_hat = lapse_p, y = lab_bin, bins = 10)
calib_plot <- ggplot2::ggplot(m$df, ggplot2::aes(p, y)) +
  ggplot2::geom_point(ggplot2::aes(size = n), alpha = 0.85, colour = md_colors$warn) +
  ggplot2::geom_line(colour = md_colors$warn, linewidth = 1) +
  ggplot2::geom_abline(slope = 1, intercept = 0, linetype = 2, colour = md_colors$muted) +
  ggplot2::scale_size_area(max_size = 10, guide = "none") +
  ggplot2::labs(
    title = "Probability Calibration — Attentional Lapse",
    subtitle = sprintf("ECE=%.3f · MCE=%.3f · Brier=%.3f", m$ece, m$mce, m$brier),
    x = "Predicted Probability", 
    y = "Observed Frequency"
  ) +
  ggplot2::theme_minimal() + theme_md()

# Probability distributions by true state
prob_dist_data <- tibble::tibble(
  true_state = y,
  lapse_prob = lapse_p
)
prob_dist_plot <- ggplot2::ggplot(prob_dist_data, ggplot2::aes(x = lapse_prob, fill = true_state)) +
  ggplot2::geom_histogram(bins = 35, alpha = 0.85, position = "identity") +
  ggplot2::facet_wrap(~ true_state, ncol = 1, scales = "free_y") +
  scale_state_fill() +
  ggplot2::scale_x_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2)) +
  ggplot2::labs(
    title = "Predicted Probability Distributions by True State",
    subtitle = "Lapse probability predictions grouped by actual cognitive state",
    x = "P(Attentional Lapse)",
    y = "Count"
  ) +
  ggplot2::theme_minimal() + theme_md() +
  ggplot2::theme(legend.position = "none")

# Legacy histogram for backward compatibility
prob_hist_plot <- ggplot2::ggplot(tibble::tibble(p = lapse_p), ggplot2::aes(p)) +
  ggplot2::geom_histogram(bins = 30, fill = md_colors$warn, alpha = 0.8) + 
  ggplot2::theme_minimal() + theme_md() + 
  ggplot2::labs(title = "Lapse Probabilities", x = "P(Lapse)", y = "Count")

calibration <- list(
  calib_plot = calib_plot, 
  prob_hist_plot = prob_hist_plot,
  prob_dist_plot = prob_dist_plot,
  calib_stats_gt = gt::gt(data.frame(
    Metric = c("ECE", "MCE", "Brier"), 
    Value = c(m$ece, m$mce, m$brier)
  ))
)
saveRDS(calibration, "data/diagnostics/calibration.rds")

# Threshold sandbox - store data and function separately
threshold_sandbox_data <- list(
  lapse_p = lapse_p,
  lab_bin = lab_bin
)

threshold_fun <- function(theta_lapse, theta_high) {
  # Load the data from the stored environment
  lapse_p <- threshold_sandbox_data$lapse_p
  lab_bin <- threshold_sandbox_data$lab_bin
  
  cm_lapse <- table(pred = factor(as.integer(lapse_p>=theta_lapse), levels=c(0,1)),
                    truth= factor(lab_bin, levels=c(0,1)))
  cm_df <- as.data.frame(cm_lapse)
  cm_plot <- ggplot2::ggplot(cm_df, ggplot2::aes(pred, truth, fill=Freq)) + ggplot2::geom_tile() +
    ggplot2::geom_text(ggplot2::aes(label=Freq)) + ggplot2::scale_fill_viridis_c() +
    ggplot2::theme_minimal() + theme_md() + ggplot2::labs(title=sprintf("Lapse Confusion @ θ=%.2f", theta_lapse))

  tib <- tibble::tibble(th=seq(0,1,by=0.02))
  tib$precision <- sapply(tib$th, function(t) yardstick::precision_vec(factor(lab_bin, levels=c(0,1)), factor(as.integer(lapse_p>=t), levels=c(0,1))))
  tib$recall    <- sapply(tib$th, function(t) yardstick::recall_vec   (factor(lab_bin, levels=c(0,1)), factor(as.integer(lapse_p>=t), levels=c(0,1))))
  tib$f1        <- with(tib, ifelse(precision+recall>0, 2*precision*recall/(precision+recall), 0))
  metrics_vs_threshold <- ggplot2::ggplot(tib, ggplot2::aes(th)) +
    ggplot2::geom_line(ggplot2::aes(y=precision)) + ggplot2::geom_line(ggplot2::aes(y=recall), linetype=2) +
    ggplot2::geom_line(ggplot2::aes(y=f1), linetype=3) + ggplot2::theme_minimal() + theme_md() +
    ggplot2::geom_vline(xintercept=theta_lapse, color="red") +
    ggplot2::labs(title="Lapse: Precision/Recall/F1 vs Threshold", x="θ", y="metric")

  list(metrics_vs_threshold=metrics_vs_threshold, cm_plot=cm_plot)
}

saveRDS(list(threshold_fun=threshold_fun, data=threshold_sandbox_data), "data/diagnostics/threshold_sandbox.rds")
