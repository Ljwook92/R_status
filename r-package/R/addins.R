.queue_text_with_status <- function(code, name) {
  if (!nzchar(trimws(code))) {
    stop("\uc2e4\ud589\ud560 R \ucf54\ub4dc\uac00 \uc5c6\uc2b5\ub2c8\ub2e4.", call. = FALSE)
  }

  path <- tempfile(pattern = "rstudio-status-", fileext = ".R")
  writeLines(enc2utf8(code), path, useBytes = TRUE)

  command <- sprintf(
    "rstudiostatus::run_file_with_status(%s, name = %s, cleanup = TRUE)",
    encodeString(path, quote = '"'),
    encodeString(enc2utf8(name), quote = '"')
  )

  # Defer until the Addin callback has fully returned. If sendToConsole() is
  # called synchronously, some RStudio versions keep treating the work as an
  # Addin callback and do not expose the normal Console Busy/Stop UI.
  later::later(function() {
    tryCatch({
      rstudioapi::sendToConsole(command, execute = TRUE, focus = TRUE)
    }, error = function(e) {
      unlink(path)
      warning("RStudio Console \uc2e4\ud589 \uc2e4\ud328: ", conditionMessage(e), call. = FALSE)
    })
  }, delay = 0.1)

  invisible(path)
}

#' Run an R file while showing menu bar status
#'
#' This function is used by the RStudio Addins to execute code through the
#' regular RStudio Console. Running through the Console makes RStudio's busy
#' indicator and Stop button behave like a normal user-initiated execution.
#'
#' @param path Path to an R source file.
#' @param name A short task name shown by the menu bar app.
#' @param cleanup Whether to remove `path` after execution.
#' @return The last value evaluated by `source()`, invisibly.
#' @export
run_file_with_status <- function(path, name = basename(path), cleanup = FALSE) {
  path <- normalizePath(path, mustWork = TRUE)
  if (isTRUE(cleanup)) {
    on.exit(unlink(path), add = TRUE)
  }

  rstatus_notify("running", name)
  tryCatch({
    connection <- file(path, open = "r", encoding = "UTF-8")
    on.exit(close(connection), add = TRUE)
    result <- source(connection, local = .GlobalEnv, echo = FALSE, keep.source = TRUE)
    rstatus_notify("complete", name)
    invisible(result$value)
  }, error = function(e) {
    rstatus_notify("fail", name, conditionMessage(e))
    stop(e)
  }, interrupt = function(e) {
    rstatus_notify("interrupted", name, "Interrupted by user")
    stop(e)
  })
}

#' Run the current RStudio selection with menu bar status
#' @export
run_selection_with_status <- function() {
  context <- rstudioapi::getActiveDocumentContext()
  code <- context$selection[[1L]]$text
  label <- if (nzchar(context$path)) basename(context$path) else "RStudio selection"
  .queue_text_with_status(code, label)
}

#' Run the current RStudio document with menu bar status
#' @export
run_current_document_with_status <- function() {
  context <- rstudioapi::getActiveDocumentContext()
  code <- paste(context$contents, collapse = "\n")
  label <- if (nzchar(context$path)) basename(context$path) else "Untitled R document"
  .queue_text_with_status(code, label)
}
