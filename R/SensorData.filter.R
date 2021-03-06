#' @name SensorData.filter.averageRemovalFIR
#' @title Apply average removal FIR filter to the input sensor data frame each column over certain breaks (e.g. hour, sec, min and etc.)
#' @export
#' @import signal matlab plyr
#' @param sensorData the input dataframe that matches mhealth specification.
#' @param breaks "sec","min","hour","day","week","month","quarter" or "year"; or preceded by integer and space.
#' @param Fs sampling rate of the input signal
#' @param order window size (in seconds) of filter
#' @note If "breaks" is missing, filter will be applied on the whole sequence and return a list with a single dataframe.
SensorData.filter.averageRemovalFIR = function(sensorData, breaks, Fs, order){
  nCols = ncol(sensorData)
  
  window = round(order * Fs);
  
  b = c((window - 1)/window, -ones(1, window - 1)/window);
  a = 1;
  
  if(missing(breaks) || is.null(breaks)){
    sensorData$breaks = .SummaryData.getBreaks(ts = sensorData[,MHEALTH_CSV_TIMESTAMP_HEADER])
  }else{
    sensorData$breaks = .SummaryData.getBreaks(ts = sensorData[,MHEALTH_CSV_TIMESTAMP_HEADER], breaks = breaks)
  }
  result = dlply(sensorData,.(breaks), function(rows){
    colFilter = colwise(.fun = function(x, filt, a){
      filtered = filter(filt, a, x)
      result = as.numeric(filtered)
    }, filt = b, a = a)
    filteredValue = colFilter(rows[2:nCols])
    colnames(filteredValue) = paste0("AVERAGEREMOVALFIR_",colnames(filteredValue))
    filteredValue = cbind(rows[MHEALTH_CSV_TIMESTAMP_HEADER], filteredValue)
    return(filteredValue)
  })
  return(result)
}

#' @name SensorData.filter.bessel
#' @title Apply low pass bessel filter to the input sensor data frame each column over certain breaks (e.g. hour, sec, min and etc.)
#' @export
#' @import signal matlab plyr
#' @param sensorData the input dataframe that matches mhealth specification.
#' @param breaks "sec","min","hour","day","week","month","quarter" or "year"; or preceded by integer and space.
#' @param Fs sampling rate of the input signal
#' @param Fc cut off frequency of bessel filter
#' @param order formula order of bessel filter
#' @note If "breaks" is missing, filter will be applied on the whole sequence and return a list with a single dataframe.
SensorData.filter.bessel = function(sensorData, breaks, Fs, Fc, order){
  # real bessel filter design based on the implementation of matlab
  armaCoeffs = .besself(Fs = Fs, Fc = Fc, order = order)

  nCols = ncol(sensorData)
  if(missing(breaks) || is.null(breaks)){
    sensorData$breaks = .SummaryData.getBreaks(ts = sensorData[,MHEALTH_CSV_TIMESTAMP_HEADER])
  }else{
    sensorData$breaks = .SummaryData.getBreaks(ts = sensorData[,MHEALTH_CSV_TIMESTAMP_HEADER], breaks = breaks)
  }
  result = dlply(sensorData,.(breaks), function(rows){
    colFilter = colwise(.fun = function(x, filt){
      filtered = filter(filt, x)
      return(as.numeric(filtered))
    }, filt = armaCoeffs)
    filteredValue = colFilter(rows[2:nCols])
    colnames(filteredValue) = paste0("BESSEL_",colnames(filteredValue))
    filteredValue = cbind(rows[MHEALTH_CSV_TIMESTAMP_HEADER], filteredValue)

    return(filteredValue)
  })

  return(result)
}

#' @name SensorData.filter.iir
#' @title Apply iir filter to the input sensor data frame each column over a certain break (e.g. hour, sec, min and etc.).
#' @export
#' @import signal matlab plyr
#' @param sensorData the input dataframe that matches mhealth specification.
#' @param breaks "sec","min","hour","day","week","month","quarter" or "year"; or preceded by integer and space.
#' @param Fs sampling rate of the input signal
#' @param Fc cut off frequencies of butterworth filter, if more than one store as c(low, high)
#' @param order formula order of butterworth filter
#' @param type "low", "high", "stop", "pass"
#' @param filter "butter", "chebyI", "chebyII", "ellip"
#' @return list of filtered dataframes.
#' @note If "breaks" is missing, filter will be applied on the whole sequence and return a list with a single dataframe.
SensorData.filter.iir = function(sensorData, breaks, Fs, Fc, order, type = "high", filter = "butter"){
  nyquist=Fs/2;

  coeffs = switch(filter, 
         butter = butter(order,Fc/nyquist,type),
         chebyI = cheby1(order, 0.05, W = Fc/nyquist, type, plane = "z"),
         chebyII = cheby2(order, 0.05, W = Fc/nyquist, type, plane = "z"),
         ellip = signal::ellip(order, 0.05, 50, W = Fc/nyquist, type, plane = "z")
        )

  nCols = ncol(sensorData)

  if(missing(breaks) || is.null(breaks)){
    sensorData$breaks = .SummaryData.getBreaks(ts = sensorData[,MHEALTH_CSV_TIMESTAMP_HEADER])
  }else{
    sensorData$breaks = .SummaryData.getBreaks(ts = sensorData[,MHEALTH_CSV_TIMESTAMP_HEADER], breaks = breaks)
  }
  result = dlply(sensorData,.(breaks), function(rows){
    colFilter = colwise(.fun = function(x, filt, a){
      filtered = filter(filt, a, x)
      result = as.numeric(filtered)
    }, filt = coeffs$b, a = coeffs$a)
    filteredValue = colFilter(rows[2:nCols])
    colnames(filteredValue) = paste0("IIR_",colnames(filteredValue))
    filteredValue = cbind(rows[MHEALTH_CSV_TIMESTAMP_HEADER], filteredValue)
    return(filteredValue)
  })
  return(result)
}

#' @name SensorData.filter.resample
#' @title Apply bandlimited interpolation filter to the input sensor data frame each column over a certain break (e.g. hour, sec, min and etc.).
#' @export
#' @import signal plyr dplyr
#' @param sensorData the input dataframe that matches mhealth specification.
#' @param breaks "sec","min","hour","day","week","month","quarter" or "year"; or preceded by integer and space.
#' @param origSr original sampling rate of each column
#' @param newSr the desired sampling rate for each column
#' @return list of filtered dataframes.
#' @note If "breaks" is missing, filter will be applied on the whole sequence and return a list with a single dataframe.
SensorData.filter.resample = function(sensorData, breaks, origSr, newSr){
  nCols = ncol(sensorData)
  if(missing(breaks) || is.null(breaks)){
    sensorData$breaks = .SummaryData.getBreaks(ts = sensorData[,MHEALTH_CSV_TIMESTAMP_HEADER])
  }else{
    sensorData$breaks = .SummaryData.getBreaks(ts = sensorData[,MHEALTH_CSV_TIMESTAMP_HEADER], breaks = breaks)
  }
  result = sensorData %>% dlply(.(breaks), function(rows){
    colFilter = colwise(.fun = function(x){
      resampled = x %>% signal::resample(p = newSr, q = origSr) %>% as.numeric
    })
    resampledValue = colFilter(rows[2:nCols])
    resampledTs = seq(from = rows[1, MHEALTH_CSV_TIMESTAMP_HEADER], to = rows[, MHEALTH_CSV_TIMESTAMP_HEADER] %>% last, length = nrow(resampledValue))
    resampledValue = cbind(resampledTs, resampledValue)
    colnames(resampledValue)[1] = MHEALTH_CSV_TIMESTAMP_HEADER
    return(resampledValue)
  }, .progress = "none", .inform = TRUE)
  return(result)
}

.besselap = function(n){
  z = c()
  k = 1
  if(n == 0){
    p = c()
  }else if(n == 1){
    p = c(-1)
  }else if(n == 2){
    p = c(complex(real = -0.8660254037844386467637229, imaginary = 0.4999999999999999999999996),
          complex(real = -0.8660254037844386467637229, imaginary = -0.4999999999999999999999996))
  }else if(n == 3){
    p = c(-0.9416000265332067855971980,
          complex(real = -0.7456403858480766441810907, imaginary = -0.7113666249728352680992154),
          complex(real = -0.7456403858480766441810907, imaginary = 0.7113666249728352680992154))
  }else if(n == 4){
    p = c(complex(real = -0.6572111716718829545787781, imaginary = -0.8301614350048733772399715),
          complex(real = -0.6572111716718829545787781, imaginary = 0.8301614350048733772399715),
          complex(real = -0.9047587967882449459642637, imaginary = -0.2709187330038746636700923),
          complex(real = -0.9047587967882449459642637, imaginary = 0.2709187330038746636700923))
  }else if(n == 5){
    p = c(-.9264420773877602247196260,
          complex(real = -0.8515536193688395541722677, imaginary = -0.4427174639443327209850002),
          complex(real = -0.8515536193688395541722677, imaginary = 0.4427174639443327209850002),
          complex(real = -.5905759446119191779319432, imaginary = -0.9072067564574549539291747),
          complex(real = -.5905759446119191779319432, imaginary = 0.9072067564574549539291747))
  }else if(n == 6){
    p = c(
      complex(real = -.9093906830472271808050953, imaginary = -0.1856964396793046769246397),
      complex(real = -.9093906830472271808050953, imaginary = 0.1856964396793046769246397),
      complex(real = -.7996541858328288520243325, imaginary = -0.5621717346937317988594118),
      complex(real = -.7996541858328288520243325, imaginary = 0.5621717346937317988594118),
      complex(real = -.5385526816693109683073792, imaginary = -.9616876881954277199245657),
      complex(real = -.5385526816693109683073792, imaginary = .9616876881954277199245657))
  }else if(n == 7){
    p = c(
      -.9194871556490290014311619,
      complex(real = -.8800029341523374639772340, imaginary = - .3216652762307739398381830),
      complex(real = -.8800029341523374639772340, imaginary = .3216652762307739398381830),
      complex(real = -.7527355434093214462291616, imaginary = - .6504696305522550699212995),
      complex(real = -.7527355434093214462291616, imaginary = .6504696305522550699212995),
      complex(real = -.4966917256672316755024763, imaginary = - 1.002508508454420401230220),
      complex(real = -.4966917256672316755024763, imaginary = 1.002508508454420401230220))
  }else if(n == 8){
    p = c(
      complex(real = -.9096831546652910216327629, imaginary = - .1412437976671422927888150),
      complex(real = -.9096831546652910216327629, imaginary = .1412437976671422927888150),
      complex(real = -.8473250802359334320103023, imaginary = - .4259017538272934994996429),
      complex(real = -.8473250802359334320103023, imaginary = .4259017538272934994996429),
      complex(real = -.7111381808485399250796172, imaginary = -.7186517314108401705762571),
      complex(real= -.7111381808485399250796172, imaginary = .7186517314108401705762571),
      complex(real = -.4621740412532122027072175, imaginary = - 1.034388681126901058116589),
      complex(real = -.4621740412532122027072175, imaginary = 1.034388681126901058116589)
    )
  }
  return(list(z = z,p = p,k = k))
}

.bilinear = function(z, p, k, Fs){
  Fs = 2*Fs
  pd = (1 + p/Fs)/(1 - p/Fs)
  zd = (1 + z/Fs)/(1 - z/Fs)
  kd = k*prod(Fs - z)/prod(Fs - p)
  zd = c(zd, -rep(1, length(pd) - length(zd)))
  return(list(zd = zd, pd = pd, kd = kd))
}

.besself = function(Fs, Fc, order){
  zpkPrototype = .besselap(order)
  zpkPrototype = sftrans(Zpg(zpkPrototype$z, zpkPrototype$p, zpkPrototype$k), W = Fc*2*pi)
  zpkPrototype = .bilinear(zpkPrototype$zero, zpkPrototype$pole, zpkPrototype$gain, Fs)
  armaCoeffs = as.Arma(Zpg(zpkPrototype$z, zpkPrototype$p, zpkPrototype$k))
  return(armaCoeffs)
}
