source("scripts/00_setup.R")
feats <- data.table::fread("data/processed/features.csv.gz") |> as_tibble()
models <- readRDS("data/processed/xgb_loso_models.rds"); mdl <- models[[1]]
eval  <- readRDS("data/diagnostics/loso_eval.rds")

feat_cols <- mdl$feat_cols; bst <- mdl$bst; glm_cal <- mdl$glm_cal
X <- as.matrix(feats[, feat_cols])
raw <- matrix(predict(bst, X), ncol=length(CFG$labels), byrow=TRUE); colnames(raw) <- CFG$labels
y <- feats$cognitive_state
lab_bin <- as.integer(y=="Attentional Lapse")
lapse_p <- predict(glm_cal, data.frame(p=raw[,"Attentional Lapse"]), type="response")

# Calibration
bins <- cut(lapse_p, breaks=seq(0,1,by=0.1), include.lowest=TRUE)
obs <- tapply(lab_bin, bins, mean, na.rm=TRUE)
exp <- tapply(lapse_p, bins, mean, na.rm=TRUE)
calib_df <- tibble::tibble(bin=levels(bins), expected=as.numeric(exp), observed=as.numeric(obs))
ece <- mean(abs(calib_df$observed-calib_df$expected), na.rm=TRUE)
mce <- max(abs(calib_df$observed-calib_df$expected), na.rm=TRUE)
brier <- mean((lapse_p - lab_bin)^2, na.rm=TRUE)
calib_plot <- ggplot2::ggplot(calib_df, aes(expected, observed)) +
  ggplot2::geom_abline(linetype=2) + ggplot2::geom_point() + ggplot2::geom_line() +
  ggplot2::labs(title=sprintf("Reliability (Lapse) — ECE=%.3f MCE=%.3f Brier=%.3f", ece,mce,brier),
                x="Predicted", y="Observed") + ggplot2::theme_minimal()
prob_hist_plot <- ggplot2::ggplot(tibble::tibble(p=lapse_p), aes(p)) +
  ggplot2::geom_histogram(bins=30) + ggplot2::theme_minimal() + ggplot2::labs(title="Lapse Probabilities")

calibration <- list(calib_plot=calib_plot, prob_hist_plot=prob_hist_plot,
                    calib_stats_gt = gt::gt(data.frame(Metric=c("ECE","MCE","Brier"), Value=c(ece,mce,brier))))
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
    ggplot2::theme_minimal() + ggplot2::labs(title=sprintf("Lapse Confusion @ θ=%.2f", theta_lapse))

  tib <- tibble::tibble(th=seq(0,1,by=0.02))
  tib$precision <- sapply(tib$th, function(t) yardstick::precision_vec(factor(lab_bin, levels=c(0,1)), factor(as.integer(lapse_p>=t), levels=c(0,1))))
  tib$recall    <- sapply(tib$th, function(t) yardstick::recall_vec   (factor(lab_bin, levels=c(0,1)), factor(as.integer(lapse_p>=t), levels=c(0,1))))
  tib$f1        <- with(tib, ifelse(precision+recall>0, 2*precision*recall/(precision+recall), 0))
  metrics_vs_threshold <- ggplot2::ggplot(tib, ggplot2::aes(th)) +
    ggplot2::geom_line(ggplot2::aes(y=precision)) + ggplot2::geom_line(ggplot2::aes(y=recall), linetype=2) +
    ggplot2::geom_line(ggplot2::aes(y=f1), linetype=3) + ggplot2::theme_minimal() +
    ggplot2::geom_vline(xintercept=theta_lapse, color="red") +
    ggplot2::labs(title="Lapse: Precision/Recall/F1 vs Threshold", x="θ", y="metric")

  list(metrics_vs_threshold=metrics_vs_threshold, cm_plot=cm_plot)
}

saveRDS(list(threshold_fun=threshold_fun, data=threshold_sandbox_data), "data/diagnostics/threshold_sandbox.rds")
