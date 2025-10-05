CogEngine <- R6::R6Class("CogEngine",
  public = list(
    CFG=NULL, model=NULL, iso=NULL, iso_thr=NULL,
    buf=NULL, last_tool=NULL,

    initialize = function(cfg) {
      self$CFG <- cfg
      m <- readRDS("data/processed/xgb_loso_models.rds")[[1]]
      self$model <- m
      iso_obj <- readRDS("data/processed/lapse_iso.rds")
      self$iso <- iso_obj$model; self$iso_thr <- iso_obj$score_threshold
      self$buf <- list()
      self$last_tool <- NULL
    },

    update = function(row) {
      if (is.null(self$last_tool)) self$last_tool <- row$tool_id
      row$tool_switch <- as.integer(row$tool_id != self$last_tool)
      if (row$tool_id != self$last_tool) self$last_tool <- row$tool_id
      self$buf <- append(self$buf, list(row))
      maxk <- max(unlist(self$CFG$windows))
      if (length(self$buf)>maxk) self$buf <- self$buf[(length(self$buf)-maxk+1):length(self$buf)]
    },

    compute_features = function() {
      if (!length(self$buf)) return(NULL)
      # Convert list of lists to data frame
      df <- tibble::as_tibble(do.call(rbind, lapply(self$buf, function(x) unlist(x))))
      Rmean <- function(x,k) slider::slide_dbl(x, mean, .before=k-1, .after=0, .complete=TRUE)
      Rsd   <- function(x,k) slider::slide_dbl(x, sd,   .before=k-1, .after=0, .complete=TRUE)
      Rsum  <- function(x,k) slider::slide_dbl(x, sum,  .before=k-1, .after=0, .complete=TRUE)

      df$tonic_pupil_level_30s      <- Rmean(df$pupil_diameter_mm, self$CFG$windows$tonic_pupil_s)
      df$grip_force_variability_15s <- Rsd(df$grip_force_newtons, self$CFG$windows$grip_var_s)
      df$tremor_trend_10s           <- Rmean(df$instrument_tremor_hz, self$CFG$windows$tremor_trend_s)
      df$blink_rate_60s             <- Rsum(df$blink, self$CFG$windows$blink_rate_s)
      df$tool_switch_rate_120s      <- Rsum(df$tool_switch, self$CFG$windows$tool_switch_rate_s)
      mu <- Rmean(df$ambient_noise_db, self$CFG$windows$noise_rate_s)
      sdv<- Rsd(df$ambient_noise_db, self$CFG$windows$noise_rate_s)
      spike <- as.integer(df$ambient_noise_db > (mu + 2*sdv))
      df$noise_mean_60s             <- mu
      df$noise_spike_count_60s      <- Rsum(spike, self$CFG$windows$noise_rate_s)
      # segment-local baseline approx
      kpre <- self$CFG$windows$phasic_pupil_s
      df$local_baseline             <- slider::slide_dbl(df$pupil_diameter_mm, mean, .before=kpre-1, .after=0, .complete=TRUE)
      # Handle NA values in baseline calculation
      df$phasic_pupil_change_5s     <- ifelse(is.na(df$local_baseline), 0, df$pupil_diameter_mm - df$local_baseline)

      tail(df, 1) |>
        dplyr::select(all_of(self$model$feat_cols))
    },

    predict = function() {
      feats <- self$compute_features()
      if (is.null(feats) || any(is.na(feats))) return(NULL)

      bst <- self$model$bst
      pr <- predict(bst, as.matrix(feats))
      pr <- matrix(pr, ncol=length(self$CFG$labels)); colnames(pr) <- self$CFG$labels
      pr <- pr[1,]
      lapse_p <- predict(self$model$glm_cal, data.frame(p=pr["Attentional Lapse"]), type="response")
      anomaly <- self$iso$predict(feats)$anomaly_score[1]

      # guardrails from last 10 minutes
      win <- min(600, length(self$buf))
      hist <- tibble::as_tibble(do.call(rbind, lapply(self$buf[(length(self$buf)-win+1):length(self$buf)], function(x) unlist(x))))
      q5 <- quantile(hist$pupil_diameter_mm, self$CFG$thresholds$tonic_low_quantile, na.rm=TRUE)
      q95<- quantile(hist$pupil_diameter_mm, self$CFG$thresholds$tonic_high_quantile, na.rm=TRUE)
      mu_g <- mean(hist$grip_force_newtons, na.rm=TRUE)
      sd_g <- sd(hist$grip_force_newtons, na.rm=TRUE)
      z_grip <- (tail(hist$grip_force_newtons,1)-mu_g)/sd_g

      guard <- list(tonic_low = tail(hist$pupil_diameter_mm,1) < q5,
                    tonic_high= tail(hist$pupil_diameter_mm,1) > q95,
                    grip_z_high = z_grip > self$CFG$thresholds$grip_z_guard)

      alert_lapse <- (as.numeric(lapse_p) >= self$CFG$thresholds$alert_prob_lapse) || (anomaly >= self$iso_thr)
      alert_high  <- (as.numeric(pr["High Load"]) >= self$CFG$thresholds$alert_prob_highload)
      final_state <- names(which.max(pr))

      reasons <- c()
      if (guard$grip_z_high) reasons <- c(reasons, sprintf("high grip variability (z=%.2f)", z_grip))
      if (guard$tonic_high)  reasons <- c(reasons, "elevated tonic pupil")
      if (guard$tonic_low)   reasons <- c(reasons, "depressed tonic pupil")
      if (tail(hist$tool_switch,1)==1) reasons <- c(reasons, "recent tool switch")
      if (tail(hist$ambient_noise_db,1) > (mean(hist$ambient_noise_db,na.rm=TRUE)+2*sd(hist$ambient_noise_db,na.rm=TRUE)))
        reasons <- c(reasons, "noise spike in OR")

      list(
        state_probs = pr,
        lapse_p = as.numeric(lapse_p),
        anomaly = anomaly,
        guardrail_flags = guard,
        final_state = final_state,
        alert = list(lapse = alert_lapse, highload = alert_high),
        reasons = head(reasons, 3)
      )
    }
  )
)
