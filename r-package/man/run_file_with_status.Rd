\name{run_file_with_status}
\alias{run_file_with_status}
\title{Run an R file while showing menu bar status}
\usage{
run_file_with_status(path, name = basename(path), cleanup = FALSE)
}
\arguments{
\item{path}{Path to an R source file.}
\item{name}{A short task name shown by the menu bar app.}
\item{cleanup}{Whether to remove \code{path} after execution.}
}
\value{The last value evaluated by \code{source()}, invisibly.}
\description{
Executes an R source file in the regular RStudio Console execution path while
reporting running, completion, failure, and interruption to the menu bar app.
}
