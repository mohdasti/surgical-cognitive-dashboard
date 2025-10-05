source("scripts/00_setup.R")
stream <- data.table::fread("data/processed/sim_stream.csv.gz") |> as_tibble()

# segment id increments on tool switches
stream <- stream |>
  group_by(surgeon_id) |>
  mutate(segment_id = cumsum(dplyr::coalesce(lag(tool_switch, default = 0L), 0L))) |>
  ungroup()

Rmean <- function(x,k) slider::slide_dbl(x, mean, .before=k-1, .after=0, .complete=TRUE)
Rsd   <- function(x,k) slider::slide_dbl(x, sd,   .before=k-1, .after=0, .complete=TRUE)
Rsum  <- function(x,k) slider::slide_dbl(x, sum,  .before=k-1, .after=0, .complete=TRUE)

feat <- stream |>
  arrange(surgeon_id, t) |>
  group_by(surgeon_id) |>
  mutate(
    tonic_pupil_level_30s     = Rmean(pupil_diameter_mm, CFG$windows$tonic_pupil_s),
    grip_force_variability_15s= Rsd(grip_force_newtons, CFG$windows$grip_var_s),
    tremor_trend_10s          = Rmean(instrument_tremor_hz, CFG$windows$tremor_trend_s),
    blink_rate_60s            = Rsum(blink, CFG$windows$blink_rate_s),
    tool_switch_rate_120s     = Rsum(tool_switch, CFG$windows$tool_switch_rate_s),
    noise_mean_60s            = Rmean(ambient_noise_db, CFG$windows$noise_rate_s),
    noise_sd_60s              = Rsd(ambient_noise_db, CFG$windows$noise_rate_s)
  ) |>
  ungroup() |>
  mutate(
    noise_spike               = as.integer(ambient_noise_db > (noise_mean_60s + 2*noise_sd_60s))
  ) |>
  group_by(surgeon_id) |>
  mutate(
    noise_spike_count_60s     = Rsum(noise_spike, CFG$windows$noise_rate_s)
  ) |>
  ungroup() |>
  group_by(surgeon_id, segment_id) |>
  mutate(
    local_baseline            = Rmean(pupil_diameter_mm, CFG$windows$phasic_pupil_s),
    phasic_pupil_change_5s    = pupil_diameter_mm - local_baseline
  ) |>
  ungroup() |>
  select(-noise_sd_60s, -noise_spike)

data.table::fwrite(feat, "data/processed/features.csv.gz")