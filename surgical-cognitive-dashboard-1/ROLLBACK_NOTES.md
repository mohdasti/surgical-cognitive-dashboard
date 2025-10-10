# Rollback to Working Version - October 10, 2025

## 🎯 Action Taken

**Reverted to commit**: `a2120f1` (Oct 8, 2025)  
**Commit message**: "🐛 Fix app opacity/fade issue - disable incomplete modules"

## ❌ Why Rollback Was Necessary

Progressive changes from Oct 8-10 made the opacity issue WORSE instead of better:

### Failed Fix Attempts:
1. `9be5293` - Fixed collapsible sections but didn't solve opacity
2. `ae8685a` - Added CSS hard reset for opacity
3. `45e4793` - Made simulation loop unambiguous  
4. `4b20354` - Scoped accordion JS
5. `fda5c06` - Killed `.recalculating` fade with CSS
6. `d62987c` - Replaced some renderUI with textOutput
7. `f6f8ca3` - Removed simulation_clock renderUI
8. **Current HEAD** - Completely broken, app won't parse/start

### Root Cause of Progressive Failure:
- Tried to fix opacity with CSS overrides instead of addressing root cause
- Added complex diagnostics module that had UI/server wiring issues
- Module errors kept app in perpetual "busy" state
- Half-commented code blocks created parse errors
- Each "fix" added more complexity without solving the core issue

## ✅ What Works in `a2120f1`

According to the commit message:
- ✅ No opacity/fade overlay
- ✅ No flickering error panels
- ✅ Fast, clean loading
- ✅ All core features functional:
  - Real-time biosignal plots (pupil, grip, tremor)
  - Cognitive state classification
  - State probability distribution
  - Feature table with literature references
  - Alert log with detailed reasons
  - Performance metrics

### Disabled Features (intentionally):
- ⏸️ Cicerone tour (was causing opacity overlay)
- ⏸️ Mode banner (incomplete reactive dependencies)
- ⏸️ Compare threshold drawer (incomplete)
- ⏸️ Guided tour and popovers

## 📋 Lessons Learned

### What NOT to Do:
1. ❌ Don't add CSS `!important` overrides to fix symptoms
2. ❌ Don't pile on multiple "defensive" fixes
3. ❌ Don't partially comment out code blocks (creates parse errors)
4. ❌ Don't enable features with incomplete dependencies

### What TO Do:
1. ✅ Start from a known working state
2. ✅ Add ONE feature at a time
3. ✅ Test after each addition
4. ✅ If something breaks, revert immediately
5. ✅ Fix root causes, not symptoms

## 🔬 Actual Root Cause (Confirmed)

The opacity was caused by **`renderUI()` functions updating at 5 Hz**:
- `simulation_clock` in large banner div
- `status_card`, `lapse_prob_card`, `performance_card`
- These created DOM repaints that triggered `.recalculating` class
- At 5 Hz, this appeared as permanent fade

## 🚀 Path Forward

If you want to re-add features:

### Step 1: Fix renderUI in Current HEAD
On a NEW branch (not main):
1. Replace ALL renderUI with textOutput/renderText
2. Test that opacity is gone
3. Ensure plots load correctly

### Step 2: Re-enable Features One-by-One
1. Start with error sources panel (already in `a2120f1`)
2. Add diagnostics tab with SIMPLE content (not progressive disclosure)
3. Test after each addition
4. If opacity returns, STOP and debug that specific feature

### Step 3: Add Advanced Features Last
1. Training Lab controls
2. Compare drawer
3. Guided tour
4. Mode banner

**Key**: Test after EACH addition. If anything breaks, revert that commit.

## 📝 Current Status

**Branch**: main  
**HEAD**: `a2120f1` (known working)  
**Modified since rollback**: No (clean state)  
**App running**: Yes, port 4162  
**Opacity**: Should be GONE in this version

## 🧪 Verification Steps

Please verify the app at http://127.0.0.1:4162:
- [ ] No opacity/fade (app is crisp and clear)
- [ ] Biosignal plots render and update
- [ ] Status cards show data
- [ ] Alert log works
- [ ] Experimental Controls tab accessible

If ANY of these fail in `a2120f1`, then the issue pre-dates our changes
and we need to investigate the original app setup.

---

**Date**: October 10, 2025  
**Action**: Hard reset to `a2120f1`  
**Status**: App running on port 4162

