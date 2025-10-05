source("scripts/00_setup.R")
feats <- data.table::fread("data/processed/features.csv.gz") |> as_tibble()
models <- readRDS("data/processed/xgb_loso_models.rds"); mdl <- models[[1]]
feat_cols <- mdl$feat_cols; bst <- mdl$bst

X <- as.matrix(feats[, feat_cols])

# XGB importance
imp <- xgboost::xgb.importance(model=bst)
xgb_importance_plot <- xgboost::xgb.plot.importance(imp, top_n=15)

# SHAP (for High Load as example) - try with error handling
shap_global_plot <- NULL
tryCatch({
  set.seed(1)
  idx <- sample.int(nrow(X), size=min(500, nrow(X)))
  pred_fun <- function(newdata) {
    p <- predict(bst, newdata)
    matrix(p, ncol=length(CFG$labels), byrow=TRUE)[,"High Load"]
  }
  sh <- fastshap::explain(bst, X[idx,], X=X, pred_wrapper=pred_fun, nsim=10)
  shap_global_plot <- fastshap::autoplot(sh) + ggplot2::labs(title="SHAP (High Load)")
}, error = function(e) {
  cat("SHAP computation failed:", e$message, "\n")
})

# PD for top 3 features
top_feats <- head(imp$Feature, 3)
pd_plots <- setNames(vector("list", length(top_feats)), top_feats)
for (f in top_feats) {
  tryCatch({
    pd <- pdp::partial(bst, pred.var=f, train=as.data.frame(X), prob=TRUE, which.class=2)
    pd_plots[[f]] <- autoplot(pd) + ggplot2::labs(title=paste("PD for", f, "(High Load)"))
  }, error = function(e) {
    cat("PD plot failed for", f, ":", e$message, "\n")
  })
}

saveRDS(list(xgb_importance_plot=xgb_importance_plot, shap_global_plot=shap_global_plot,
             pd_plots=pd_plots, feat_names=feat_cols, params=mdl$params),
        "data/diagnostics/model_artifacts.rds")
