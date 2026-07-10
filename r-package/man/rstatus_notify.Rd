\name{rstatus_notify}
\alias{rstatus_notify}
\title{Send an R execution status to the menu bar app}
\usage{
rstatus_notify(
  status,
  name = "R task",
  message = NULL,
  host = "127.0.0.1",
  port = 47821L
)
}
\arguments{
\item{status}{One of \code{idle}, \code{running}, \code{complete}, or \code{fail}.}
\item{name}{A short task name.}
\item{message}{Optional detail or error message.}
\item{host}{Local app host.}
\item{port}{Local app port.}
}
\value{Invisibly returns \code{TRUE} when the event was sent, otherwise \code{FALSE}.}
\description{Sends a status event to the locally running RStudio Status app.}
