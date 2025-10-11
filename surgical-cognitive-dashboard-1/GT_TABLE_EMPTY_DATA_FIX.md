# GT Table Empty Data Fix - Clean Solution

## Context

After reverting 9 commits that attempted to show the table immediately with baseline values (which caused complications), we implemented a clean, simple solution to handle empty data gracefully.

## Problem

**Before the fix:**
- GT table would not render when no data was available
- Users saw blank space on app startup
- No clear feedback that data was loading
- Empty tibbles passed to `build_features_gt()` caused rendering issues

## Solution

### 1. Handle Empty Data in `build_features_gt()` (R/gt_table_utils.R)

Added a check at the start of the function:

```r
if (nrow(features_now) == 0) {
  placeholder_df <- tibble::tibble(
    Message = "⏳ Waiting for data...",
    Info = "The table will populate once biosignal data starts streaming."
  )
  return(
    placeholder_df %>%
      gt() %>%
      # ... styled placeholder table
  )
}
```

**Why this works:**
- Creates a simple, user-friendly placeholder table
- Styled with appropriate colors and fonts
- Returns immediately without complex processing
- No fake/baseline data needed

### 2. Simplify Module Logic (R/mod_gt_live_table.R)

Removed blocking logic for empty data:

```r
# If empty, return it as-is (build_features_gt will handle)
if (nrow(df) == 0) {
  return(df)
}
```

**Why this works:**
- Delegates empty data handling to the build function
- Cleaner separation of concerns
- No need for multiple empty data checks

## Benefits

✅ **Immediate rendering** - Table shows placeholder message instantly  
✅ **Clear feedback** - Users know data is loading  
✅ **Smooth transition** - Once data arrives, table updates seamlessly  
✅ **Simple code** - No complicated workarounds or fake data  
✅ **Maintainable** - Easy to understand and modify  

## User Experience Flow

1. **App starts** → Placeholder message appears immediately
2. **Data streams** → Table populates with real values
3. **Data continues** → Live updates with sparklines and colors

## Testing

To verify the fix:

1. Start the app: `Rscript -e "shiny::runApp('shiny_app/app_working.R')"`
2. Navigate to Live Monitor tab
3. Check "Show feature values" checkbox
4. **Expected:** See placeholder message immediately
5. **Expected:** Within 200ms, table populates with live data

## Commits

- **Reverted to:** `60cb429` - Fix: Replace validate() with req() in GT module
- **New commits:**
  1. `4986ba6` - Fix: GT table now shows placeholder message when no data available
  2. `e917e32` - Fix: Vectorize effect size calculation for GT table
  3. `8352134` - Fix: Handle gtExtras sparkline version compatibility

## Additional Fixes Applied

While reverting, we also cherry-picked important bug fixes that were independent of the "show immediately" feature:

### 1. Vectorized Effect Size Calculation (Commit e917e32)

**Problem:** 
- `effect_size_d()` used scalar `||` operator instead of vector `|`
- `map2_dbl()` didn't properly pass `baseline_sd` per row

**Fix:**
- Vectorized `effect_size_d()` using `ifelse()` 
- Changed to `pmap_dbl()` for proper row-by-row calculation
- Each feature now gets correct Cohen's d value

### 2. gtExtras Sparkline Version Compatibility (Commit 8352134)

**Problem:**
- Newer gtExtras renamed `gt_sparkline()` to `gt_plt_sparkline()`
- Code would fail with "function not found" error
- Our installation has only the newer function

**Fix:**
- Runtime check for which function exists
- Try `gt_plt_sparkline()` first (newer), then `gt_sparkline()` (older)
- Graceful error handling with dash (—) fallback
- Works with all gtExtras versions

## Lessons Learned

1. **Keep it simple** - Don't overcomplicate with fake baseline data
2. **Handle edge cases gracefully** - Empty data should show helpful messages, not errors
3. **Separate concerns** - Let build functions handle presentation logic
4. **User feedback matters** - A loading message is better than a blank screen
5. **Cherry-pick wisely** - When reverting, preserve independent bug fixes

## Future Enhancements (Optional)

If desired, could add:
- Animated loading indicator
- Countdown timer showing when data is expected
- Progress bar showing data accumulation
- Link to help documentation

But the current solution is clean, simple, and effective! ✨

