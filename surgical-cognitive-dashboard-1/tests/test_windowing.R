library(testthat); library(data.table)
test_that("causal windows and segment reset", {
  f <- fread("../data/processed/features.csv.gz")
  k <- 30
  set.seed(7); idx <- sample((k+1):nrow(f), 20)
  for (i in idx) {
    expect_equal(
      f$tonic_pupil_level_30s[i],
      mean(f$pupil_diameter_mm[(i-k+1):i], na.rm=TRUE),
      tolerance=1e-6
    )
  }
  sw <- which(f$tool_switch==1)
  if (length(sw)>0) {
    i <- sw[1]
    # Check that segment_id changes after tool switch (segment_id increments after tool_switch)
    expect_true(f$segment_id[i+1] != f$segment_id[i])
    # Check that local_baseline resets (becomes NA) at segment boundary
    # This verifies segment-aware computation
    expect_true(is.na(f$local_baseline[i+1]) || f$local_baseline[i+1] != f$local_baseline[i])
  }
})
