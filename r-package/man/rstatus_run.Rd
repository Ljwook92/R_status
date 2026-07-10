\name{rstatus_run}
\alias{rstatus_run}
\title{Run R code while showing its status}
\usage{
rstatus_run(expr, name = deparse1(substitute(expr), nlines = 1L))
}
\arguments{
\item{expr}{R expression to evaluate.}
\item{name}{A short task name shown by the menu bar app.}
}
\value{The value returned by \code{expr}, invisibly.}
\description{Reports running, completion, and failure around evaluation of an R expression.}
