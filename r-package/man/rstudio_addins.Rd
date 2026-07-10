\name{rstudio_addins}
\alias{run_selection_with_status}
\alias{run_current_document_with_status}
\title{Run RStudio code with menu bar status}
\usage{
run_selection_with_status()

run_current_document_with_status()
}
\value{The queued temporary source-file path, invisibly.}
\description{
RStudio Addin bindings that queue the active selection or current document for
execution in the regular RStudio Console and report running, completion, failure,
and interruption to the menu bar app.
}
