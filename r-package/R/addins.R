.run_text_with_status <- function(code, name) {
  if (!nzchar(trimws(code))) {
    stop("\uc2e4\ud589\ud560 R \ucf54\ub4dc\uac00 \uc5c6\uc2b5\ub2c8\ub2e4.", call. = FALSE)
  }

  rstatus_notify("running", name)
  tryCatch({
    connection <- textConnection(code, open = "r", local = TRUE)
    on.exit(close(connection), add = TRUE)
    result <- source(connection, local = .GlobalEnv, echo = FALSE, keep.source = TRUE)
    rstatus_notify("complete", name)
    invisible(result$value)
  }, error = function(e) {
    rstatus_notify("fail", name, conditionMessage(e))
    stop(e)
  }, interrupt = function(e) {
    rstatus_notify("fail", name, "Interrupted by user")
    stop(e)
  })
}

#' Run the current RStudio selection with menu bar status
#' @export
run_selection_with_status <- function() {
  context <- rstudioapi::getActiveDocumentContext()
  code <- context$selection[[1L]]$text
  label <- if (nzchar(context$path)) basename(context$path) else "RStudio selection"
  .run_text_with_status(code, label)
}

#' Run the current RStudio document with menu bar status
#' @export
run_current_document_with_status <- function() {
  context <- rstudioapi::getActiveDocumentContext()
  code <- paste(context$contents, collapse = "\n")
  label <- if (nzchar(context$path)) basename(context$path) else "Untitled R document"
  .run_text_with_status(code, label)
}
