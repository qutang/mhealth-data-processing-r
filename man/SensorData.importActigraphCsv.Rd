% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/SensorData.R
\name{SensorData.importActigraphCsv}
\alias{SensorData.importActigraphCsv}
\title{Import and convert Actigraph raw csv files and load into data frame as in mhealth format.}
\usage{
SensorData.importActigraphCsv(filename, ad_convert = FALSE,
  ts_provided = TRUE, header_provided = TRUE)
}
\arguments{
\item{filename}{full file path of input Actigraph raw csv file.}

\item{ad_convert}{set as TRUE only when the input Actigraph csv file is in analog quantized format and need to be converted into g value}

\item{ts_provided}{set as TRUE only when timestamp is provided as the first column}

\item{header_provided}{set as TRUE only when column header is provided}
}
\note{
Please make sure the Actigraph raw csv file has timestamp included. The Actigraph raw csv file is not IMU csv file supported by GT9X.
}
\seealso{
[`SensorData.importCsv`](SensorData.importCsv.html), [`SensorData.importGT3X`](SensorData.importGT3X.html), [`SensorData.importBinary`](SensorData.importBinary.html)
}
