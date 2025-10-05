source("scripts/00_setup.R")

N_SURG <- 3
SEC_PER_CASE <- 3 * 60 * 60  # 3h @1Hz

tool_catalog <- c("forceps","scissors","needle_driver","cautery","stapler")
tool_transition <- matrix(0.1, length(tool_catalog), length(tool_catalog))
diag(tool_transition) <- 0.6
tool_transition <- tool_transition / rowSums(tool_transition)

surgeon_params <- tibble(
  surgeon_id = paste0("S", seq_len(N_SURG)),
  pupil_base = rnorm(N_SURG, 4.0, 0.5),
  pupil_sd   = runif(N_SURG, 0.08, 0.15),
  reactivity = runif(N_SURG, 0.6, 1.4),
  tremor_base= rnorm(N_SURG, 2.5, 0.4),
  tremor_sd  = runif(N_SURG, 0.15, 0.30),
  blink_opt  = runif(N_SURG, 12, 18),
  blink_fat  = runif(N_SURG, 18, 30),
  blink_high = runif(N_SURG, 6, 12)
)

simulate_case <- function(params) {
  n <- SEC_PER_CASE; t <- seq_len(n)
  states <- c("Optimal","High Load","Fatigued","Attentional Lapse")
  state <- character(n); state[1] <- "Optimal"

  for (i in 2:n) {
    state[i] <- state[i-1]
    if (runif(1) < 0.005) state[i] <- sample(states, 1, prob=c(0.75,0.15,0.09,0.01))
  }
  # longer fatigue bouts, rare lapses
  for (k in sample(1:n, 3)) state[k:min(n,k+sample(120:300,1))] <- "Fatigued"
  for (k in sample(1:n, 2)) state[k:min(n,k+sample(6:15,1))]     <- "Attentional Lapse"

  tool_idx <- integer(n); tool_idx[1] <- sample(seq_along(tool_catalog), 1)
  for (i in 2:n) tool_idx[i] <- sample(seq_along(tool_catalog), 1, prob=tool_transition[tool_idx[i-1], ])
  tool_id <- tool_catalog[tool_idx]; tool_switch <- c(FALSE, diff(tool_idx)!=0)

  noise <- pmax(45, rnorm(n, 52, 4))
  spike_idx <- sample(n, floor(n*0.01)); noise[spike_idx] <- noise[spike_idx] + runif(length(spike_idx), 10, 25)

  ton <- ifelse(state=="Fatigued",-0.25, ifelse(state=="High Load", +0.25, 0))
  pupil <- params$pupil_base + ton + rnorm(n, 0, params$pupil_sd)

  grip_mean <- ifelse(state=="Attentional Lapse",2.0, ifelse(state=="High Load",3.2,2.6))
  grip <- grip_mean + rnorm(n, 0, ifelse(state %in% c("Fatigued","Attentional Lapse"),0.55,0.35))
  special <- sample(n, floor(0.05*n)); grip[special] <- grip_mean[special] + rnorm(length(special), 0, 0.25)

  tremor <- params$tremor_base + ifelse(state=="Fatigued", runif(n,0.3,0.5), 0) + rnorm(n, 0, params$tremor_sd)

  blink_rate_min <- ifelse(state=="Fatigued", params$blink_fat,
                      ifelse(state=="High Load", params$blink_high, params$blink_opt))
  blink <- rbinom(n, 1, pmin(0.9, blink_rate_min/60))

  tibble(
    surgeon_id = params$surgeon_id, t,
    tool_id, tool_switch = as.integer(tool_switch),
    ambient_noise_db = noise, blink = as.integer(blink),
    pupil_diameter_mm = pmax(1.5, pupil),
    grip_force_newtons = pmax(0, grip),
    instrument_tremor_hz = pmax(0, tremor),
    cognitive_state = factor(state, levels = CFG$labels)
  )
}

stream <- map_dfr(split(surgeon_params, surgeon_params$surgeon_id), simulate_case)
data.table::fwrite(stream, "data/processed/sim_stream.csv.gz")