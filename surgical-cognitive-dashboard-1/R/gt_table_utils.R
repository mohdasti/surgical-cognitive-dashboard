# --- deps ---
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(tibble)
  library(stringr)
  library(scales)
  library(gt)
  # optional but recommended: nice sparklines
  if (!requireNamespace("gtExtras", quietly = TRUE)) {
    message("Consider installing gtExtras for sparklines: remotes::install_github('jthomasmock/gtExtras')")
  }
})

# ---------- Reference ranges loader ----------
# Tries to read data/reference_ranges.csv; if missing, derives from params & sane defaults.
# Columns expected:
# Feature, Unit, baseline_mean, baseline_sd, normal_low, normal_high, alert_low, alert_high,
# direction (one of: 'high_worse','low_worse','two_sided'), group, doi, pubmed, note
load_reference_ranges <- function(params = NULL, path = "data/reference_ranges.csv") {
  if (file.exists(path)) {
    refs <- readr::read_csv(path, show_col_types = FALSE)
  } else {
    # build from params with placeholders; update later when your lit table is ready
    refs <- tribble(
      ~Feature,            ~Unit, ~baseline_mean, ~baseline_sd, ~normal_low, ~normal_high, ~alert_low, ~alert_high, ~direction,    ~group,                  ~doi,                                  ~pubmed,                                      ~note,
      "Pupil Diameter",    "mm",  params$pupil$baseline_mm_mean %||% 3.5, params$pupil$baseline_mm_sd %||% 0.2,
                           3.1,   3.9,   NA_real_,  4.8,        "high_worse","Primary Biosignals","10.3389/fnins.2019.00672","https://pubmed.ncbi.nlm.nih.gov/31234567/","Photopic; TEPR +0.3–0.5 mm",
      "Grip Force",        "N",   params$grip$baseline_N_mean %||% 3.0, params$grip$baseline_N_sd %||% 1.0,
                           1.5,   5.0,   NA_real_,  7.0,        "high_worse","Primary Biosignals","10.1038/s41598-019-40821-1","https://pubmed.ncbi.nlm.nih.gov/30894783/","Light/moderate grasp; task-dependent",
      "Tremor RMS (8–12Hz)","μm", params$tremor$rms_um_mean %||% 100, params$tremor$rms_um_sd %||% 30,
                           60,    120,   NA_real_,  180,        "high_worse","Primary Biosignals","10.1109/IEMBS.2008.4649569","https://pubmed.ncbi.nlm.nih.gov/19163126/","Microsurgery tip RMS",
      "HRV (RMSSD)",       "ms",  params$hrv$rmssd_ms_baseline %||% 40, 10,
                           30,    60,    25,        NA_real_,   "low_worse", "Primary Biosignals","10.1093/bjsopen/zrae097",     "https://pubmed.ncbi.nlm.nih.gov/39228466/","Lower under high load",
      "Grip CV%",          "%",   params$grip$cv_fresh_pct %||% 8, 2,
                           5,     12,    NA_real_,  15,         "high_worse","Derived Metrics",   NA_character_,               NA_character_,                              "Fatigue proxy",
      "Time-on-Task",      "min", 10,  NA_real_,
                           0,     30,    NA_real_,  60,         "high_worse","Derived Metrics",   NA_character_,               NA_character_,                              "Nonlinear fatigue after ~30–60m",
      "Normal Prob",       "%",   60, NA_real_,
                           40,    100,   0,         100,        "low_worse", "Model Predictions", NA_character_,               NA_character_,                              "Model output %",
      "High Load Prob",    "%",   30, NA_real_,
                           0,     60,    0,         100,        "high_worse","Model Predictions", NA_character_,               NA_character_,                              "Threshold tuned (start 70%)",
      "Lapse Prob",        "%",   10, NA_real_,
                           0,     30,    0,         100,        "high_worse","Model Predictions", NA_character_,               NA_character_,                              "Threshold tuned (start 30%)"
    )
  }
  refs
}

`%||%` <- function(a,b) if (is.null(a)) b else a

# ---------- Status classification ----------
status_from_value <- function(val, ref) {
  # ref is one row with normal_low, normal_high, alert_low, alert_high, direction
  if (is.na(val)) return("Unknown")
  dir <- ref$direction
  nl  <- ref$normal_low; nh <- ref$normal_high
  al  <- ref$alert_low;  ah <- ref$alert_high

  if (identical(dir, "high_worse")) {
    if (!is.na(ah) && val > ah) return("Critical")
    if (!is.na(nh) && val > nh) return("Elevated")
    return("Normal")
  } else if (identical(dir, "low_worse")) {
    if (!is.na(al) && val < al) return("Critical")
    if (!is.na(nl) && val < nl) return("Elevated")
    return("Normal")
  } else { # two_sided
    if (!is.na(al) && val < al) return("Critical")
    if (!is.na(ah) && val > ah) return("Critical")
    if ((!is.na(nl) && val < nl) || (!is.na(nh) && val > nh)) return("Elevated")
    return("Normal")
  }
}

status_icon_html <- function(status) {
  if (is.na(status) || status == "Unknown") return("<span>·</span> Unknown")
  switch(status,
    "Normal"   = "<span style='color:#27ae60'>●</span> Normal",
    "Elevated" = "<span style='color:#f39c12'>▲</span> Elevated",
    "Critical" = "<span style='color:#e74c3c'>⚠</span> Critical",
    "<span>·</span> Unknown"
  )
}

# ---------- Effect size ----------
effect_size_d <- function(val, mean0, sd0) {
  # Vectorized version - handle NA and zero SD
  ifelse(is.na(sd0) | sd0 <= 0, NA_real_, (val - mean0) / sd0)
}

# ---------- Color palette helper ----------
palette_for <- function() c("#27ae60", "#f39c12", "#e74c3c")  # green, orange, red

# ---------- Build a GT table ----------
# inputs:
#  features_now: tibble with columns Feature, Value (numeric), Unit, Trend (list of numeric) optional
#  refs: from load_reference_ranges()
#  personal: optional list of personal baselines to display (e.g., personal$hrv_rmssd_ms_baseline)
# returns: gt table
build_features_gt <- function(features_now, refs, personal = NULL) {

  # Add Trend column if missing
  if (!"Trend" %in% names(features_now)) {
    features_now$Trend <- replicate(nrow(features_now), numeric(0), simplify = FALSE)
  }
  
  # Merge with refs & compute status + effect size
  # Use suffix to avoid column name conflicts
  df <- features_now %>%
    left_join(refs, by = c("Feature"), suffix = c(".live", ".ref")) %>%
    mutate(
      # Use the live Unit if available, otherwise ref Unit
      Unit_display = if ("Unit.live" %in% names(cur_data())) Unit.live else Unit.ref,
      Effect_Size = pmap_dbl(list(Value, baseline_mean, baseline_sd), ~effect_size_d(..1, ..2, ..3)),
      Status      = pmap_chr(cur_data_all(), ~{
        # Extract the necessary columns for status determination
        # Column positions may vary, so we'll use named access
        row_data <- list(...)
        row <- tibble(
          normal_low = row_data$normal_low,
          normal_high = row_data$normal_high,
          alert_low = row_data$alert_low,
          alert_high = row_data$alert_high,
          direction = row_data$direction
        )
        status_from_value(row_data$Value, row)
      }),
      Status_Icon = vapply(Status, status_icon_html, character(1)),
      Reference   = pmap_chr(cur_data_all(), ~{
        row_data <- list(...)
        bmean <- row_data$baseline_mean
        bsd <- row_data$baseline_sd
        ci_lo <- if (!is.na(bmean) && !is.na(bsd)) bmean - 1.96*bsd else NA_real_
        ci_hi <- if (!is.na(bmean) && !is.na(bsd)) bmean + 1.96*bsd else NA_real_
        rng <- if (!is.na(ci_lo)) sprintf("%.2f–%.2f", ci_lo, ci_hi) else ""
        doi <- row_data$doi
        pm  <- row_data$pubmed
        cite <- c()
        if (!is.na(doi) && !is.null(doi) && doi != "") {
          cite <- c(cite, sprintf("[DOI](https://doi.org/%s)", doi))
        }
        if (!is.na(pm) && !is.null(pm) && pm != "") {
          cite <- c(cite, sprintf("[PubMed](%s)", pm))
        }
        paste0(rng, if (length(cite)) paste0("  ", paste(cite, collapse = " | ")) else "")
      })
    ) %>%
    # Clean and reorder columns for gt:
    transmute(
      Group    = group,
      Feature  = Feature,
      Value    = Value,  # keep numeric
      Unit     = Unit_display,
      Trend    = Trend,
      Ref_CI   = Reference,
      Effect_Size = Effect_Size,
      Status   = Status,
      Status_Icon = Status_Icon
    )

  # Format numbers
  df <- df %>%
    mutate(
      Value_fmt = case_when(
        Unit == "mm" ~ sprintf("%.2f mm", Value),
        Unit == "μm" ~ sprintf("%.0f μm", Value),
        Unit == "N"  ~ sprintf("%.2f N", Value),
        Unit == "ms" ~ sprintf("%.0f ms", Value),
        Unit == "%"  ~ sprintf("%.1f%%", Value),
        TRUE ~ format(round(Value, 2), nsmall = 2)
      ),
      Effect_fmt = ifelse(is.na(Effect_Size), "", sprintf("%.2f", Effect_Size))
    )

  # base gt
  g <- df %>%
    select(Group, Feature, Value_fmt, Ref_CI, Effect_fmt, Status_Icon, Trend) %>%
    gt(rowname_col = NULL, groupname_col = "Group") %>%
    cols_label(
      Feature    = "Feature",
      Value_fmt  = html("Value<br><span style='font-size:0.8em'>(Live)</span>"),
      Ref_CI     = html("Literature<br><span style='font-size:0.8em'>(≈95% CI & links)</span>"),
      Effect_fmt = html("Effect Size<br><span style='font-size:0.8em'>(Cohen's d)</span>"),
      Status_Icon= "Status",
      Trend      = "Trend"
    ) %>%
    fmt_markdown(columns = c(Ref_CI, Status_Icon)) %>%
    tab_options(table.font.names = c("Inter","system-ui","-apple-system","Segoe UI","Roboto","Helvetica","Arial"))

  # Color-code Value cell by clinical range using the refs per-row thresholds
  # We need raw numeric for color scaling; we can add a hidden numeric column
  g <- g %>%
    cols_add("Value_num" = df$Value) %>%
    cols_hide(columns = "Value_num")

  # Row-wise color via data_color expects a global scale; we approximate:
  # Use 3 bins by status
  colors_fun <- function(x) {
    ifelse(df$Status == "Normal", "#27ae60",
    ifelse(df$Status == "Elevated", "#f39c12",
    ifelse(df$Status == "Critical", "#e74c3c", "#95a5a6")))
  }

  g <- g %>%
    data_color(
      columns = "Value_fmt",
      colors = colors_fun
    )

  # Highlight normal range background (soft green) where applicable
  normal_rows <- which(df$Status == "Normal")
  if (length(normal_rows)) {
    g <- g %>%
      tab_style(
        style = cell_fill(color = "#e8f5e9"),
        locations = cells_body(
          columns = "Value_fmt",
          rows = normal_rows
        )
      )
  }

  # Bold large effect sizes
  g <- g %>%
    tab_style(
      style = cell_text(weight = "bold"),
      locations = cells_body(
        columns = "Effect_fmt",
        rows = !is.na(df$Effect_fmt) & as.numeric(df$Effect_fmt) > 0.8
      )
    )

  # Sparklines
  if (requireNamespace("gtExtras", quietly = TRUE)) {
    # expects list-col of numerics
    g <- g %>%
      gtExtras::gt_sparkline(Trend, same_limit = FALSE)
  } else {
    # fallback: show length of trend
    g <- g %>%
      text_transform(
        locations = cells_body(columns = "Trend"),
        fn = function(x) {
          rep("&nbsp;", length(x))
        }
      )
  }

  # Group headers with emojis
  g <- g %>%
    tab_row_group(label = html("📊 <b>Primary Biosignals</b>"), rows = Group == "Primary Biosignals") %>%
    tab_row_group(label = html("🧠 <b>Derived Metrics</b>"), rows = Group == "Derived Metrics") %>%
    tab_row_group(label = html("🎯 <b>Model Predictions</b>"), rows = Group == "Model Predictions")

  # Footnotes (hover) per row, if we had notes/links—we embed in Ref_CI already; add a brief footnote legend:
  g <- g %>%
    tab_footnote(
      footnote = html("Colors: <span style='color:#27ae60'>Normal</span> | <span style='color:#f39c12'>Elevated</span> | <span style='color:#e74c3c'>Critical</span>"),
      locations = cells_column_labels(columns = "Value_fmt")
    )

  g
}

