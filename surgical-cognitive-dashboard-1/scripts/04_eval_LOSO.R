source("scripts/00_setup.R")
source("R/theme_md.R")
feats <- data.table::fread("data/processed/features.csv.gz") |> as_tibble()
models <- readRDS("data/processed/xgb_loso_models.rds")
metrics <- readRDS("data/processed/xgb_loso_metrics.rds")
mdl <- models[[1]]; bst <- mdl$bst; glm_cal <- mdl$glm_cal
feat_cols <- mdl$feat_cols

X <- as.matrix(feats[, feat_cols])
raw <- matrix(predict(bst, X), ncol=length(CFG$labels), byrow=TRUE); colnames(raw) <- CFG$labels
y <- feats$cognitive_state

y_hat <- factor(CFG$labels[max.col(raw)], levels=CFG$labels)
y_true <- factor(y, levels=CFG$labels)
cm_tbl <- yardstick::conf_mat(tibble(y_true=y_true,y_hat=y_hat), truth=y_true, estimate=y_hat)
cm_plot <- as.data.frame(cm_tbl$table) |>
  ggplot2::ggplot(aes(Prediction, Truth, fill=Freq)) + ggplot2::geom_tile() +
  ggplot2::geom_text(aes(label=Freq)) + ggplot2::scale_fill_viridis_c() +
  ggplot2::theme_minimal() + theme_md() + ggplot2::labs(title="Confusion Matrix (Aggregated)")

lapse_p <- predict(glm_cal, data.frame(p=raw[,"Attentional Lapse"]), type="response")
lab_bin <- as.integer(y=="Attentional Lapse")
pr <- PRROC::pr.curve(scores.class0=lapse_p, weights.class0=lab_bin, curve=TRUE)
pr_df <- tibble(recall=pr$curve[,1], precision=pr$curve[,2])
pr_plot <- ggplot2::ggplot(pr_df, aes(recall, precision)) + ggplot2::geom_line() +
  ggplot2::labs(title=sprintf("PR Curve (Lapse) — AUC=%.3f", pr$auc.integral)) + ggplot2::theme_minimal() + theme_md()

saveRDS(list(cm_plot=cm_plot, pr_lapse_plot=pr_plot,
             loso_df=tibble(holdout=names(metrics), pr_auc=sapply(metrics, `[[`, "pr_auc"))),
        "data/diagnostics/loso_eval.rds")
