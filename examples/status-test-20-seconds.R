# RStudio Status 20-second verification
#
# 1. Select this entire file in RStudio (Cmd + A).
# 2. Open Addins in the top menu.
# 3. Click "Run Selection with Status".
#
# Expected menu-bar flow:
# RStudio logo -> Running -> Complete

message("20-second RStudio Status test started")

for (second in seq_len(20)) {
  if (second %% 5 == 0) {
    message(second, " seconds elapsed")
  }
  Sys.sleep(1)
}

message("20-second RStudio Status test complete")
