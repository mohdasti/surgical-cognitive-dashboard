source("scripts/00_setup.R")
df <- data.table::fread("data/processed/features.csv.gz") |> as_tibble()
df <- df |> mutate(cognitive_state = factor(cognitive_state, levels = CFG$labels))

feat_cols <- c(
  "tonic_pupil_level_30s","grip_force_variability_15s","tremor_trend_10s",
  "phasic_pupil_change_5s","blink_rate_60s","tool_switch_rate_120s",
  "noise_mean_60s","noise_spike_count_60s"
)

loso_ids <- unique(df$surgeon_id)
metrics <- list(); models <- list()

for (hold in loso_ids) {
  train <- df |> filter(surgeon_id != hold)
  test  <- df |> filter(surgeon_id == hold)

  # class weights
  wtab <- table(train$cognitive_state); w <- as.numeric(max(wtab)/wtab)
  wt <- w[match(train$cognitive_state, levels(train$cognitive_state))]

  dtrain <- xgboost::xgb.DMatrix(as.matrix(train[,feat_cols]), label = as.integer(train$cognitive_state)-1, weight=wt)
  dtest  <- xgboost::xgb.DMatrix(as.matrix(test[,feat_cols]),  label = as.integer(test$cognitive_state)-1)

  param <- list(
    objective="multi:softprob", num_class=length(CFG$labels),
    eval_metric="mlogloss", max_depth=5, eta=0.08,
    subsample=0.9, colsample_bytree=0.9, min_child_weight=5
  )
  bst <- xgboost::xgb.train(param, dtrain, nrounds=400, verbose=0)

  # raw probs
  p_raw <- matrix(predict(bst, dtest), byrow=TRUE, ncol=length(CFG$labels))
  colnames(p_raw) <- CFG$labels

  # calibrate **lapse** probability via Platt scaling
  val <- tibble(p=p_raw[,"Attentional Lapse"], y = as.integer(test$cognitive_state=="Attentional Lapse"))
  glm_cal <- glm(y ~ p, data=val, family=binomial())

  # metrics
  y_true <- test$cognitive_state
  y_hat  <- factor(CFG$labels[max.col(p_raw)], levels = CFG$labels)
  cm <- yardstick::conf_mat(tibble(y_true, y_hat), truth=y_true, estimate=y_hat)
  pr <- PRROC::pr.curve(scores.class0 = predict(glm_cal, data.frame(p=val$p), type="response"),
                        weights.class0 = val$y, curve=TRUE)

  metrics[[hold]] <- list(cm=cm, pr_auc=pr$auc.integral)
  models[[hold]]  <- list(bst=bst, glm_cal=glm_cal, feat_cols=feat_cols, params=param)
}

saveRDS(models,  "data/processed/xgb_loso_models.rds")
saveRDS(metrics, "data/processed/xgb_loso_metrics.rds")