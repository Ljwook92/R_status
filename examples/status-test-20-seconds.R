# RStudio Status 20-second computation test
#
# 1. Select this entire file in RStudio (Cmd + A).
# 2. Open Addins in the top menu.
# 3. Click "Run Selection with Status".
# 4. To test interruption, click RStudio's Stop button while it is running.
#
# Expected menu-bar flow:
# RStudio logo -> Running -> Complete
#                        `-> Interrupted (when Stop is clicked)

message("20-second matrix computation started")

started_at <- proc.time()[["elapsed"]]
iteration <- 0L
last_report <- 0L
checksum <- 0

while (proc.time()[["elapsed"]] - started_at < 20) {
  # Repeated matrix multiplication keeps the R session genuinely busy while
  # leaving frequent opportunities for RStudio's Stop button to interrupt it.
  matrix_size <- 600L
  values <- matrix(rnorm(matrix_size * matrix_size), nrow = matrix_size)
  gram_matrix <- crossprod(values)
  checksum <- checksum + sum(diag(gram_matrix))
  iteration <- iteration + 1L

  elapsed <- floor(proc.time()[["elapsed"]] - started_at)
  if (elapsed >= last_report + 5L) {
    last_report <- elapsed
    message(elapsed, " seconds elapsed (", iteration, " iterations)")
  }
}

message(
  "20-second matrix computation complete: ",
  iteration,
  " iterations; checksum = ",
  format(checksum, scientific = TRUE, digits = 4)
)
