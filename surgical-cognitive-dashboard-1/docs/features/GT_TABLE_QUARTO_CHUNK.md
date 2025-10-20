# Single R Chunk for GT Table with Trends in Quarto

## 📋 Complete Self-Contained Code

Copy and paste this entire chunk into your `.qmd` file:

```{r}
#| label: features-gt-with-trends
#| echo: false
#| warning: false
#| message: false

# Self-contained GT table with trends for Quarto case study
# Renders the Real-time Feature Values table from the Shiny app

if (requireNamespace("gt", quietly = TRUE) &&
    requireNamespace("readr", quietly = TRUE) &&
    requireNamespace("dplyr", quietly = TRUE)) {
  
  library(readr)
  library(dplyr)
  library(gt)
  
  # ===== REFERENCE RANGES =====
  ref_path <- "data/reference_ranges.csv"
  refs <- if (file.exists(ref_path)) {
    read_csv(ref_path, show_col_types = FALSE)
  } else {
    tibble::tibble(
      Feature = c("Pupil Diameter", "Grip Force", "Tremor RMS (8–12Hz)", "HRV (RMSSD)",
                  "Grip CV%", "Time-on-Task", "Normal Prob", "High Load Prob", "Lapse Prob"),
      Unit = c("mm", "N", "μm", "ms", "%", "min", "%", "%", "%"),
      baseline_mean = c(3.5, 3.0, 100, 40, 8, 10, 60, 30, 10),
      baseline_sd   = c(0.2, 1.0, 30, 10, 2, NA, NA, NA, NA),
      normal_low    = c(3.1, 1.5, 60, 30, 5, 0, 40, 0, 0),
      normal_high   = c(3.9, 5.0, 120, 60, 12, 30, 100, 60, 30),
      alert_low     = c(NA, NA, NA, 25, NA, NA, 0, 0, 0),
      alert_high    = c(4.8, 7.0, 180, NA, 15, 60, 100, 100, 100),
      direction     = c("high_worse", "high_worse", "high_worse", "low_worse", 
                        "high_worse", "high_worse", "low_worse", "high_worse", "high_worse")
    )
  }
  
  # ===== SNAPSHOT DATA WITH TRENDS =====
  snap_rds_path <- "data/processed/demo_features_snapshot.rds"
  snap_csv_path <- "data/processed/demo_features_snapshot.csv"
  
  if (file.exists(snap_rds_path)) {
    # Preferred: RDS with parsed trends
    snap <- readRDS(snap_rds_path)
  } else if (file.exists(snap_csv_path)) {
    # CSV: need to parse trend strings
    snap <- read_csv(snap_csv_path, show_col_types = FALSE) %>%
      mutate(
        Trend_List = lapply(Trend, function(t) {
          if (is.na(t) || nchar(as.character(t)) == 0) {
            numeric(0)
          } else {
            as.numeric(strsplit(as.character(t), ",")[[1]])
          }
        })
      )
  } else {
    # Fallback: dummy data without trends
    snap <- tibble::tibble(
      Feature = c("Pupil Diameter", "Grip Force", "Tremor RMS (8–12Hz)", "HRV (RMSSD)",
                  "Grip CV%", "Time-on-Task", "Normal Prob", "High Load Prob", "Lapse Prob"),
      Value   = c(3.62, 5.30, 78, 45, 9.3, 10.0, 43.5, 40.5, 16.0),
      Unit    = c("mm", "N", "μm", "ms", "%", "min", "%", "%", "%"),
      Trend_List = replicate(9, numeric(0), simplify = FALSE)
    )
    message("⚠️  Snapshot file not found. Run 'make features-snapshot' to generate trend data.")
  }
  
  # ===== HELPER FUNCTIONS =====
  status_row <- function(val, r) {
    dir <- r$direction
    nl <- r$normal_low
    nh <- r$normal_high
    al <- r$alert_low
    ah <- r$alert_high
    
    if (is.na(val)) return("Unknown")
    
    if (dir == "high_worse") {
      if (!is.na(ah) && val > ah) "Critical"
      else if (!is.na(nh) && val > nh) "Elevated"
      else "Normal"
    } else if (dir == "low_worse") {
      if (!is.na(al) && val < al) "Critical"
      else if (!is.na(nl) && val < nl) "Elevated"
      else "Normal"
    } else {
      if ((!is.na(al) && val < al) || (!is.na(ah) && val > ah)) "Critical"
      else if ((!is.na(nl) && val < nl) || (!is.na(nh) && val > nh)) "Elevated"
      else "Normal"
    }
  }
  
  d_cohen <- function(val, m, s) {
    ifelse(is.na(s) || s <= 0, NA_real_, (val - m) / s)
  }
  
  # ===== BUILD TABLE DATA =====
  df <- snap %>%
    left_join(refs, by = c("Feature", "Unit")) %>%
    rowwise() %>%
    mutate(
      Status = status_row(Value, cur_data()),
      Effect = d_cohen(Value, baseline_mean, baseline_sd),
      Ref_CI = if (!is.na(baseline_mean) && !is.na(baseline_sd)) {
        sprintf("%.2f–%.2f", baseline_mean - 1.96 * baseline_sd, baseline_mean + 1.96 * baseline_sd)
      } else {
        ""
      }
    ) %>%
    ungroup() %>%
    mutate(
      Status_Icon = case_when(
        Status == "Normal"   ~ "<span style='color:#27ae60'>●</span> Normal",
        Status == "Elevated" ~ "<span style='color:#f39c12'>▲</span> Elevated",
        Status == "Critical" ~ "<span style='color:#e74c3c'>⚠</span> Critical",
        TRUE ~ "·"
      ),
      Value_fmt = case_when(
        Unit == "mm"  ~ sprintf("%.2f mm", Value),
        Unit == "μm"  ~ sprintf("%.0f μm", Value),
        Unit == "N"   ~ sprintf("%.2f N", Value),
        Unit == "ms"  ~ sprintf("%.0f ms", Value),
        Unit == "%"   ~ sprintf("%.1f%%", Value),
        Unit == "min" ~ sprintf("%.1f min", Value),
        TRUE ~ as.character(signif(Value, 3))
      ),
      Effect_fmt = ifelse(is.na(Effect), "", sprintf("%.2f", Effect))
    )
  
  # ===== BUILD GT TABLE =====
  g <- df %>%
    select(Feature, Value_fmt, Ref_CI, Effect_fmt, Status_Icon, Trend_List) %>%
    gt() %>%
    cols_label(
      Feature    = "Feature",
      Value_fmt  = html("Value<br><span style='font-size:.8em'>(Live)</span>"),
      Ref_CI     = html("Literature<br><span style='font-size:.8em'>(≈95% CI)</span>"),
      Effect_fmt = html("Effect Size<br><span style='font-size:.8em'>(Cohen's d)</span>"),
      Status_Icon = "Status",
      Trend_List  = "Trend"
    ) %>%
    fmt_markdown(columns = c(Ref_CI, Status_Icon)) %>%
    # Color-code Value by status
    tab_style(
      style = list(cell_fill(color = "#e8f5e9"), cell_text(color = "#0b1526")),
      locations = cells_body(columns = "Value_fmt", rows = df$Status == "Normal")
    ) %>%
    tab_style(
      style = cell_text(color = "#0b1526"),
      locations = cells_body(columns = "Value_fmt", rows = df$Status == "Elevated")
    ) %>%
    tab_style(
      style = cell_text(color = "#0b1526"),
      locations = cells_body(columns = "Value_fmt", rows = df$Status == "Critical")
    ) %>%
    # Bold large effect sizes
    tab_style(
      style = cell_text(weight = "bold"),
      locations = cells_body(
        columns = "Effect_fmt",
        rows = !is.na(df$Effect_fmt) & df$Effect_fmt != "" & as.numeric(df$Effect_fmt) > 0.8
      )
    ) %>%
    # Footnote
    tab_footnote(
      footnote = html("Colors: <span style='color:#27ae60'>Normal</span> | <span style='color:#f39c12'>Elevated</span> | <span style='color:#e74c3c'>Critical</span>"),
      locations = cells_column_labels(columns = "Value_fmt")
    )
  
  # ===== ADD SPARKLINES =====
  if (requireNamespace("gtExtras", quietly = TRUE)) {
    tryCatch({
      # Try gt_plt_sparkline (newer) or gt_sparkline (older)
      if (exists("gt_plt_sparkline", where = asNamespace("gtExtras"))) {
        g <- g %>% gtExtras::gt_plt_sparkline(Trend_List, same_limit = FALSE)
      } else if (exists("gt_sparkline", where = asNamespace("gtExtras"))) {
        g <- g %>% gtExtras::gt_sparkline(Trend_List, same_limit = FALSE)
      } else {
        # Fallback: show dash
        g <- g %>%
          text_transform(
            locations = cells_body(columns = "Trend_List"),
            fn = function(x) rep("—", length(x))
          )
      }
    }, error = function(e) {
      # If sparklines fail, show dash
      g <- g %>%
        text_transform(
          locations = cells_body(columns = "Trend_List"),
          fn = function(x) rep("—", length(x))
        )
    })
  } else {
    # No gtExtras: show dash
    g <- g %>%
      text_transform(
        locations = cells_body(columns = "Trend_List"),
        fn = function(x) rep("—", length(x))
      )
  }
  
  # Display table
  g
  
} else {
  cat("📦 Install packages: install.packages(c('gt', 'readr', 'dplyr'))\n")
}
```

## 📋 What This Does

This single chunk:
1. ✅ Loads reference ranges (or uses fallback defaults)
2. ✅ Loads snapshot with trends (or uses fallback data)
3. ✅ Defines helper functions for status and effect size
4. ✅ Builds the GT table with all styling
5. ✅ Adds sparklines (with graceful fallbacks)
6. ✅ Renders the complete table

## 🚀 Before Using

Generate the snapshot data once:
```bash
make features-snapshot
```

Or in R:
```r
source("scripts/92_export_features_snapshot.R")
```

## 💡 Optional: Customize in Place

You can edit the chunk directly to:
- Change reference ranges (in the `refs` tibble)
- Modify color schemes (search for `#27ae60`, etc.)
- Adjust status thresholds
- Change effect size cutoff (currently 0.8)
- Modify fallback values

## 📦 Dependencies

**Required:**
- `gt`
- `readr`
- `dplyr`

**Optional (for sparklines):**
- `gtExtras`

Install:
```r
install.packages(c("gt", "readr", "dplyr", "gtExtras"))
```

## 🎨 Output

The table will render with:
- ✅ Color-coded status indicators
- ✅ Green highlighting for normal values
- ✅ Bold effect sizes > 0.8
- ✅ Sparkline trends (if gtExtras available)
- ✅ Literature reference ranges
- ✅ Footnote explaining colors
