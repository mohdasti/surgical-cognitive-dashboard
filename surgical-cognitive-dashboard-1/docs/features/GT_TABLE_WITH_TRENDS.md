# GT Table with Trends for Quarto Case Study

This guide shows how to render the **Real-time Feature Values** table from the Shiny app in your Quarto case study document, **including sparkline trends**.

## 🎯 Quick Start

### Step 1: Generate Features Snapshot

Run this command to generate a snapshot with trend data:

```bash
make features-snapshot
# OR
Rscript scripts/92_export_features_snapshot.R
```

This creates:
- `data/processed/demo_features_snapshot.csv` - CSV with trend data as strings
- `data/processed/demo_features_snapshot.rds` - RDS with parsed trend lists

### Step 2: Add to Your Quarto Document

#### Option A: Source the Helper Script (Recommended)

```{r}
#| label: features-gt-with-trends
#| echo: false

source("scripts/features_gt_with_trends.R")
```

#### Option B: Inline Code (Full Control)

```{r}
#| label: features-gt-with-trends
#| echo: false

if (requireNamespace("gt", quietly=TRUE) &&
    requireNamespace("readr", quietly=TRUE) &&
    requireNamespace("dplyr", quietly=TRUE)) {
  
  library(readr); library(dplyr); library(gt)
  
  # Load snapshot with trends
  snap_rds_path <- "data/processed/demo_features_snapshot.rds"
  
  if (file.exists(snap_rds_path)) {
    snap <- readRDS(snap_rds_path)
  } else {
    stop("Run 'make features-snapshot' first to generate snapshot data")
  }
  
  # Load reference ranges
  ref_path <- "data/reference_ranges.csv"
  refs <- read_csv(ref_path, show_col_types = FALSE)
  
  # ... (see scripts/features_gt_with_trends.R for full code)
}
```

## 📊 What's Included

### Features in the Table

1. **Biosignals:**
   - Pupil Diameter (mm) - with sparkline trend
   - HRV (RMSSD, ms) - with sparkline trend
   - Tremor RMS 8-12Hz (μm) - with sparkline trend
   - Grip Force (N) - with sparkline trend
   - Grip CV% - with sparkline trend

2. **Context:**
   - Time-on-Task (min)

3. **State Probabilities:**
   - Normal Prob (%)
   - High Load Prob (%)
   - Lapse Prob (%)

### Columns

| Column | Description |
|--------|-------------|
| **Feature** | Biosignal or state variable name |
| **Value (Live)** | Current value with unit, color-coded by status |
| **Literature (≈95% CI)** | Reference range from literature |
| **Effect Size (Cohen's d)** | Standardized effect size vs. baseline |
| **Status** | Clinical status (Normal ●, Elevated ▲, Critical ⚠) |
| **Trend** | Sparkline showing last 100 samples (~20 seconds) |

## 🎨 Styling Features

### Status Color Coding

- 🟢 **Normal** (`#27ae60`): Value within normal range
- 🟠 **Elevated** (`#f39c12`): Value outside normal range but not critical
- 🔴 **Critical** (`#e74c3c`): Value in alert/critical range

### Effect Size Highlighting

Effect sizes > 0.8 (large effects) are **bolded** to draw attention.

### Sparklines

Sparklines are rendered using `gtExtras::gt_plt_sparkline()`:
- Shows last 100 samples (about 20 seconds at 5Hz)
- Each feature has its own y-axis scale (`same_limit = FALSE`)
- Gracefully falls back to "—" if `gtExtras` is not available

## 🔧 Customization

### Change Snapshot Timing

By default, the snapshot is taken from the middle (50%) of the demo data. To change:

```r
# In scripts/92_export_features_snapshot.R, line ~17:
snapshot_idx <- round(nrow(data) * 0.5)  # Change 0.5 to 0.3 (30%), etc.
```

### Adjust Trend Window

By default, trends show 100 samples. To change:

```r
# In scripts/92_export_features_snapshot.R, line ~20:
trend_start <- max(1, snapshot_idx - 99)  # Change 99 to desired number - 1
```

### Modify Reference Ranges

Edit `data/reference_ranges.csv` to update clinical thresholds:

```csv
Feature,Unit,baseline_mean,baseline_sd,normal_low,normal_high,alert_low,alert_high,direction
Pupil Diameter,mm,3.5,0.2,3.1,3.9,NA,4.8,high_worse
...
```

## 📦 Dependencies

### Required

- `gt` - Table rendering
- `readr` - CSV reading
- `dplyr` - Data manipulation

### Optional (for sparklines)

- `gtExtras` - Sparkline rendering

Install in R:

```r
install.packages(c("gt", "readr", "dplyr", "gtExtras"))
```

## 🐛 Troubleshooting

### "File not found: demo_features_snapshot.rds"

**Solution:** Run `make features-snapshot` to generate the snapshot files.

### Sparklines showing as "—"

**Possible causes:**
1. `gtExtras` package not installed
2. Trend data is empty (check CSV Trend column)
3. `gtExtras` version incompatibility

**Solution:** 
- Install gtExtras: `install.packages("gtExtras")`
- Check snapshot CSV has trend data in the Trend column
- Try updating gtExtras to latest version

### Colors not showing correctly

**Solution:** Ensure your Quarto output format supports HTML (e.g., `html`, `revealjs`). PDF output may not render colors correctly.

## 📚 Related Files

- `scripts/92_export_features_snapshot.R` - Generates snapshot with trends
- `scripts/features_gt_with_trends.R` - Quarto-ready GT table code
- `R/gt_table_utils.R` - App's GT table builder (reference)
- `data/reference_ranges.csv` - Clinical reference ranges
- `data/processed/demo_features_snapshot.csv` - Generated snapshot (CSV)
- `data/processed/demo_features_snapshot.rds` - Generated snapshot (RDS)

## 🎉 Example Output

The table will look like this in your Quarto document:

```
┌──────────────────────┬───────────┬──────────────┬──────────┬──────────┬──────────┐
│ Feature              │ Value     │ Literature   │ Effect   │ Status   │ Trend    │
│                      │ (Live)    │ (≈95% CI)    │ Size     │          │          │
├──────────────────────┼───────────┼──────────────┼──────────┼──────────┼──────────┤
│ Pupil Diameter       │ 3.95 mm   │ 3.11–3.89    │ 2.25     │ ▲ Elev.  │ ╱╲╱╲╱╲  │
│ HRV (RMSSD)          │ 45 ms     │ 20–60        │ 0.50     │ ● Normal │ ╲╱╲╱╲╱  │
│ Tremor RMS (8–12Hz)  │ 78 μm     │ 40–160       │ -0.73    │ ● Normal │ ╱╲╱╲╱   │
│ ...                  │ ...       │ ...          │ ...      │ ...      │ ...      │
└──────────────────────┴───────────┴──────────────┴──────────┴──────────┴──────────┘
```

(Sparklines will render as actual mini line charts in HTML output)

## 💡 Tips

1. **Run `make features-snapshot` before rendering** your Quarto document to ensure fresh data
2. **Commit the snapshot files** to git if you want consistent output across renders
3. **Use the RDS file** for faster loading and automatic trend parsing
4. **Test in HTML output first** - sparklines render best in HTML formats
5. **Check gtExtras compatibility** if sparklines aren't showing

## 🔗 See Also

- [GT Table Empty Data Fix](../status/fixes/GT_TABLE_EMPTY_DATA_FIX.md)
- [GT Table Integration Summary](../status/GT_TABLE_INTEGRATION_SUMMARY.md)
- [Feature Engineering](../implementation/COMPLETE_FEATURE_SUMMARY.md)
