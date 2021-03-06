% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/test.R
\name{manageTestPlots}
\alias{manageTestPlots}
\title{Visually inspect new/failed test plots.}
\usage{
manageTestPlots(name = NULL)
}
\arguments{
\item{name}{Optional string name of the analysis whose plots should be
tested.}
}
\value{
A Shiny app that shows all new/failed/orphaned cases. The app allows
test plots to be validated, at which point they are placed in the figs
directory and used as a reference for future tests.
}
\description{
This function is a wrapper around \code{vdiffr::manage_cases()}. It allows
visual inspection of the plots in the unit tests that were newly added or
produced an error. If no analysis is specified it will iterate over all test
cases.
}
\examples{

# manageTestPlots("Anova")

}
