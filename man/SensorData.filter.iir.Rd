% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/SensorData.filter.R
\name{SensorData.filter.iir}
\alias{SensorData.filter.iir}
\title{Apply iir filter to the input sensor data frame each column over a certain break (e.g. hour, sec, min and etc.).}
\usage{
SensorData.filter.iir(sensorData, breaks, Fs, Fc, order, type = "high",
  filter = "butter")
}
\arguments{
\item{sensorData}{the input dataframe that matches mhealth specification.}

\item{breaks}{"sec","min","hour","day","week","month","quarter" or "year"; or preceded by integer and space.}

\item{Fs}{sampling rate of the input signal}

\item{Fc}{cut off frequencies of butterworth filter, if more than one store as c(low, high)}

\item{order}{formula order of butterworth filter}

\item{type}{"low", "high", "stop", "pass"}

\item{filter}{"butter", "chebyI", "chebyII", "ellip"}
}
\value{
list of filtered dataframes.
}
\note{
If "breaks" is missing, filter will be applied on the whole sequence and return a list with a single dataframe.
}
