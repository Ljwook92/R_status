.rstatus_json_escape <- function(x) {
  x <- enc2utf8(as.character(x %||% ""))
  x <- gsub("\\\\", "\\\\\\\\", x)
  x <- gsub('"', '\\\\"', x)
  x <- gsub("\r", "\\\\r", x, fixed = TRUE)
  x <- gsub("\n", "\\\\n", x, fixed = TRUE)
  x <- gsub("\t", "\\\\t", x, fixed = TRUE)
  x
}

`%||%` <- function(x, y) if (is.null(x)) y else x

#' Send an R execution status to the menu bar app
#'
#' @param status One of `idle`, `running`, `complete`, `fail`, or `interrupted`.
#' @param name A short task name.
#' @param message Optional detail or error message.
#' @param host Local app host.
#' @param port Local app port.
#' @return Invisibly returns `TRUE` when the event was sent, otherwise `FALSE`.
#' @export
rstatus_notify <- function(status, name = "R task", message = NULL,
                           host = "127.0.0.1", port = 47821L) {
  status <- match.arg(status, c("idle", "running", "complete", "fail", "interrupted"))
  fields <- c(
    sprintf('"status":"%s"', .rstatus_json_escape(status)),
    sprintf('"name":"%s"', .rstatus_json_escape(name))
  )
  if (!is.null(message)) {
    fields <- c(fields, sprintf('"message":"%s"', .rstatus_json_escape(message)))
  }
  body <- paste0("{", paste(fields, collapse = ","), "}")
  body_raw <- charToRaw(enc2utf8(body))
  request <- paste0(
    "POST /status HTTP/1.1\r\n",
    "Host: ", host, ":", port, "\r\n",
    "Content-Type: application/json; charset=utf-8\r\n",
    "Content-Length: ", length(body_raw), "\r\n",
    "Connection: close\r\n\r\n"
  )

  connection <- tryCatch(
    socketConnection(host = host, port = port, open = "w+b", blocking = TRUE,
                     timeout = 1, encoding = "bytes"),
    error = function(e) NULL
  )
  if (is.null(connection)) {
    warning("RStudio Status \uc571\uc5d0 \uc5f0\uacb0\ud560 \uc218 \uc5c6\uc2b5\ub2c8\ub2e4. \uc571\uc774 \uc2e4\ud589 \uc911\uc778\uc9c0 \ud655\uc778\ud558\uc138\uc694.", call. = FALSE)
    return(invisible(FALSE))
  }
  on.exit(close(connection), add = TRUE)
  tryCatch({
    writeBin(c(charToRaw(request), body_raw), connection)
    flush(connection)
    response <- readLines(connection, n = 1L, warn = FALSE, encoding = "UTF-8")
    ok <- length(response) == 1L && grepl("^HTTP/1\\.[01] 200 ", response)
    if (!ok) {
      warning("RStudio Status \uc571\uc774 \uc694\uccad\uc744 \uc218\ub77d\ud558\uc9c0 \uc54a\uc558\uc2b5\ub2c8\ub2e4.", call. = FALSE)
    }
    invisible(ok)
  }, error = function(e) {
    warning("RStudio Status \uc804\uc1a1 \uc2e4\ud328: ", conditionMessage(e), call. = FALSE)
    invisible(FALSE)
  })
}

#' Run R code while showing its status in the macOS menu bar
#'
#' @param expr R expression to evaluate.
#' @param name A short task name shown in the menu bar app.
#' @return The value returned by `expr`, invisibly.
#' @export
rstatus_run <- function(expr, name = deparse1(substitute(expr), nlines = 1L)) {
  expression <- substitute(expr)
  rstatus_notify("running", name)
  tryCatch({
    value <- eval(expression, envir = parent.frame())
    rstatus_notify("complete", name)
    invisible(value)
  }, error = function(e) {
    rstatus_notify("fail", name, conditionMessage(e))
    stop(e)
  }, interrupt = function(e) {
    rstatus_notify("interrupted", name, "Interrupted by user")
    stop(e)
  })
}
