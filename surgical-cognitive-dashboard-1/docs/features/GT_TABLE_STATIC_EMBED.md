# Embed Static GT Table with Sparklines in Quarto

## 🎯 The Solution

Since you want the **actual table with sparklines** from the app, not code that generates it, here are two approaches:

---

## ✅ **Approach 1: Direct HTML Embed (Recommended)**

### Step 1: Generate the static table

```bash
Rscript scripts/93_export_gt_table_static.R
```

This creates: `case_study/tables/features_gt_table.html`

### Step 2: Embed in your Quarto document

Add this to your `.qmd` file:

```markdown
## Real-Time Feature Values

::: {.column-page}
```{=html}
<iframe src="case_study/tables/features_gt_table.html" 
        width="100%" 
        height="600px" 
        style="border:none; background: white;">
</iframe>
```
:::
```

**What this does:**
- ✅ Embeds the full HTML table with working sparklines
- ✅ No R execution needed during render
- ✅ Sparklines are fully interactive
- ✅ All styling preserved from app

---

## ✅ **Approach 2: Include as Image (Static)**

### Step 1: Install webshot2 and generate PNG

```r
install.packages("webshot2")
```

Then run:
```bash
Rscript scripts/93_export_gt_table_static.R
```

This will create: `case_study/tables/features_gt_table.png`

### Step 2: Include in Quarto

```markdown
## Real-Time Feature Values

![Feature values table with sparkline trends](case_study/tables/features_gt_table.png){width=100%}
```

**What this does:**
- ✅ Static image (no interactivity)
- ✅ Works in PDF output
- ✅ Consistent appearance
- ❌ Sparklines are static images

---

## ✅ **Approach 3: Screenshot Method (Manual)**

If webshot2 doesn't work:

1. Open `case_study/tables/features_gt_table.html` in Chrome/Firefox
2. Take a screenshot (Cmd+Shift+4 on Mac, or browser DevTools)
3. Save as `case_study/tables/features_gt_table.png`
4. Include in Quarto as shown in Approach 2

---

## 🎨 **What's in the Table**

The exported table includes:

✅ **9 Features:**
- Pupil Diameter (mm) - with sparkline
- HRV (RMSSD, ms) - with sparkline
- Tremor RMS 8-12Hz (μm) - with sparkline
- Grip Force (N) - with sparkline
- Grip CV% - with sparkline
- Time-on-Task (min)
- Normal Prob (%)
- High Load Prob (%)
- Lapse Prob (%)

✅ **Columns:**
- Feature name
- Current value (color-coded by status)
- Literature reference (95% CI + citations)
- Effect size (Cohen's d, bolded if >0.8)
- Status (● Normal, ▲ Elevated, ⚠ Critical)
- **Trend sparkline** (last 100 samples, ~20 seconds)

✅ **Styling:**
- Green highlight for normal values
- Orange/red for elevated/critical
- Clickable literature references (with PMIDs)
- Interactive sparklines (in HTML)

---

## 🔧 **Customize the Snapshot**

Edit `scripts/93_export_gt_table_static.R` to change:

### Change timing
```r
snapshot_idx <- round(nrow(data) * 0.5)  # Change 0.5 to 0.3, 0.7, etc.
```

### Change trend window
```r
trend_start <- max(1, snapshot_idx - 99)  # Change 99 to show more/less history
```

### Change dimensions (for PNG)
```r
gt::gtsave(gt_table, png_path, vwidth = 1400, vheight = 800)  # Adjust size
```

---

## 📦 **Dependencies**

**Always required:**
- `gt`
- `readr`
- `dplyr`
- `gtExtras` (for sparklines)

**For PNG export (optional):**
- `webshot2`

Install:
```r
install.packages(c("gt", "readr", "dplyr", "webshot2"))
# gtExtras from GitHub
remotes::install_github('jthomasmock/gtExtras')
```

---

## 🐛 **Troubleshooting**

### "Sparklines not showing"

**Check:**
1. Is `gtExtras` installed? `install.packages("gtExtras")` or from GitHub
2. Open the HTML file - do sparklines show there?
3. If HTML works but iframe doesn't, try increasing iframe height

### "webshot2 PNG generation fails"

**Solutions:**
1. Use Approach 1 (HTML embed) instead - works great!
2. Use Approach 3 (manual screenshot)
3. Check Chrome is installed (webshot2 needs it)

### "Table looks different from app"

**Verify:**
1. Run `make features-snapshot` to refresh demo data
2. Check `snapshot_idx` in the export script
3. Ensure `gtExtras` is installed for sparklines

---

## 💡 **Recommended Workflow**

```bash
# 1. Generate the static table with sparklines
Rscript scripts/93_export_gt_table_static.R

# 2. Check it looks good
open case_study/tables/features_gt_table.html

# 3. Embed in Quarto using Approach 1 (HTML iframe)
```

Then in your `.qmd`:

```markdown
## Real-Time Feature Monitoring

The dashboard displays live biosignal values with clinical status indicators and sparkline trends:

::: {.column-page}
```{=html}
<iframe src="case_study/tables/features_gt_table.html" 
        width="100%" 
        height="600px" 
        style="border:none; background: white;">
</iframe>
```
:::

*Table shows snapshot at 5-minute mark with 20-second trend history.*
```

---

## 🎉 **Result**

You get the **exact table from the app** with:
- ✅ All formatting and colors
- ✅ Working sparklines
- ✅ Clickable references
- ✅ No R code execution during Quarto render
- ✅ Consistent with live dashboard

Perfect for your case study! 🚀
