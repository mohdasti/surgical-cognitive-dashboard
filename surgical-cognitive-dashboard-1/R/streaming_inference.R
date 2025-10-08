CogEngine <- R6::R6Class("CogEngine", list(
  CFG = NULL,
  data_stream = NULL,
  buffer = NULL,
  models = NULL,
  lapse_model = NULL,

  initialize = function(CFG) {
    self$CFG <- CFG
    self$buffer <- list() # Store last 120s of data
    self$data_stream <- tibble::tibble() # Aggregated stream
    # Load models here if they are passed in init
  },
  
  load_models = function(models_list, lapse_model_obj) {
    self$models <- models_list
    self$lapse_model <- lapse_model_obj
  },

  update = function(new_row) {
    new_df <- as.data.frame(new_row) # Convert list to data frame
    self$data_stream <- dplyr::bind_rows(self$data_stream, new_df)
    # Keep only last 120 seconds of data
    self$data_stream <- self$data_stream %>% 
      dplyr::filter(timestamp >= (max(timestamp) - self$CFG$feature_params$max_window_s))
  },

  compute_features = function() {
    if (nrow(self$data_stream) < self$CFG$feature_params$min_window_s) {
      return(NULL) # Not enough data for features yet
    }
    df <- self$data_stream %>% dplyr::arrange(timestamp)

    # Ensure numeric types for calculations
    df <- df %>% dplyr::mutate(
      t = as.numeric(t),
      ambient_noise_db = as.numeric(ambient_noise_db),
      blink = as.numeric(blink),
      pupil_diameter_mm = as.numeric(pupil_diameter_mm),
      grip_force_newtons = as.numeric(grip_force_newtons),
      instrument_tremor_hz = as.numeric(instrument_tremor_hz),
      tool_switch = as.numeric(tool_switch)
    )

    Rmean <- function(x,k) slider::slide_dbl(x, mean, .before=k-1, .after=0, .complete=TRUE)
    Rsd   <- function(x,k) slider::slide_dbl(x, sd,   .before=k-1, .after=0, .complete=TRUE)
    Rsum  <- function(x,k) slider::slide_dbl(x, sum,  .before=k-1, .after=0, .complete=TRUE)

    w <- self$CFG$windows
    df$tonic_pupil_level_30s      <- Rmean(df$pupil_diameter_mm, w$tonic_pupil_s)
    df$grip_force_variability_15s <- Rsd(df$grip_force_newtons, w$grip_var_s)
    df$tremor_trend_10s           <- Rmean(df$instrument_tremor_hz, w$tremor_trend_s)
    df$blink_rate_60s             <- Rsum(df$blink, w$blink_rate_s)
    df$tool_switch_rate_120s      <- Rsum(df$tool_switch, w$tool_switch_rate_s)
    mu <- Rmean(df$ambient_noise_db, w$noise_rate_s)
    sdv<- Rsd(df$ambient_noise_db, w$noise_rate_s)
    spike <- as.numeric(df$ambient_noise_db > (mu + 2*sdv))
    df$noise_mean_60s             <- mu
    df$noise_spike_count_60s      <- Rsum(spike, w$noise_rate_s)

    # Phasic pupil change over short window; guard NA
    kpre <- w$phasic_pupil_s
    df$local_baseline             <- Rmean(df$pupil_diameter_mm, kpre)
    df$phasic_pupil_change_5s     <- ifelse(is.na(df$local_baseline), 0, df$pupil_diameter_mm - df$local_baseline)

    tail(df, 1) %>% dplyr::select(
      tonic_pupil_level_30s, grip_force_variability_15s, tremor_trend_10s,
      blink_rate_60s, tool_switch_rate_120s, noise_mean_60s, noise_spike_count_60s,
      phasic_pupil_change_5s
    )
  },

  predict = function() {
    feats <- self$compute_features()
    if (is.null(feats) || any(is.na(feats))) {
      return(list(
        state_probs = setNames(c(1, rep(0, length(self$CFG$labels)-1)), self$CFG$labels),
        lapse_p = 0,
        final_state = self$CFG$labels[1],
        alert = list(lapse=FALSE, highload=FALSE),
        reasons = c("Not enough data")
      ))
    }

    labels <- self$CFG$labels
    probs <- setNames(rep(0, length(labels)), labels)

    # Simple heuristic fusion using base-R rescaling
    n01 <- function(x, minv, maxv) {
      if (is.na(x) || is.infinite(x)) return(0)
      if (maxv == minv) return(0)
      z <- (as.numeric(x) - minv) / (maxv - minv)
      max(0, min(1, z))
    }
    # Heuristics for normalization bounds
    highload_score <- n01(feats$phasic_pupil_change_5s, 0, 1) +
      n01(feats$tool_switch_rate_120s, 0, max(1, self$CFG$windows$tool_switch_rate_s)) +
      n01(feats$noise_spike_count_60s, 0, max(1, self$CFG$windows$noise_rate_s))
    highload_score <- as.numeric(highload_score)

    lapse_score <- n01(-as.numeric(feats$phasic_pupil_change_5s), -1, 0) +
      n01(feats$grip_force_variability_15s, 0, 1)
    lapse_score <- as.numeric(lapse_score)

    # Normalize to [0,1]
    hl <- max(0, min(1, highload_score/3))
    lp <- max(0, min(1, lapse_score/2))

    # Assign to known labels if present
    if ("High Load" %in% labels) probs["High Load"] <- hl
    if ("Attentional Lapse" %in% labels) probs["Attentional Lapse"] <- lp
    # Optional fatigued proxy
    if ("Fatigued" %in% labels) probs["Fatigued"] <- max(0, min(1, as.numeric(feats$blink_rate_60s)/10))

    # Remaining mass to Optimal
    probs[labels[1]] <- max(0, 1 - sum(probs[-1]))

    final_state <- names(which.max(probs))
    reasons <- c()
    thr_h <- self$CFG$thresholds$alert_prob_highload
    if (is.null(thr_h) || is.na(thr_h)) thr_h <- 0.7
    thr_l <- self$CFG$thresholds$alert_prob_lapse
    if (is.null(thr_l) || is.na(thr_l)) thr_l <- 0.5
    if (probs["High Load"] > thr_h) reasons <- c(reasons, "High cognitive load signals")
    if (probs["Attentional Lapse"] > thr_l) reasons <- c(reasons, "Possible attentional lapse")

    list(
      state_probs = probs,
      lapse_p = if (!is.na(probs["Attentional Lapse"])) probs["Attentional Lapse"] else 0,
      final_state = final_state,
      alert = list(
        lapse = (if (!is.na(probs["Attentional Lapse"])) probs["Attentional Lapse"] else 0) >= thr_l,
        highload = (if (!is.na(probs["High Load"])) probs["High Load"] else 0) >= thr_h
      ),
      reasons = if (length(reasons)) head(reasons, 3) else c("None")
    )
  }
))
