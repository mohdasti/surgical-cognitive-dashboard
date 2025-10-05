source("scripts/00_setup.R"); library(solitude)
df <- data.table::fread("data/processed/features.csv.gz") |> as_tibble()
feat_cols <- c("tonic_pupil_level_30s","grip_force_variability_15s","tremor_trend_10s",
               "phasic_pupil_change_5s","blink_rate_60s","tool_switch_rate_120s",
               "noise_mean_60s","noise_spike_count_60s")
train <- df |> filter(cognitive_state != "Attentional Lapse")
# Remove rows with any NA values for anomaly detection
train_clean <- train |> filter(complete.cases(train[,feat_cols]))
iso <- isolationForest$new(num_trees=300)
iso$fit(train_clean[,feat_cols])
scores <- iso$predict(train_clean[,feat_cols])$anomaly_score
thr <- quantile(scores, 0.99, na.rm=TRUE)
saveRDS(list(model=iso, score_threshold=as.numeric(thr), feat_cols=feat_cols), "data/processed/lapse_iso.rds")
