library(shiny)
library(shinyFiles)
library(ggplot2)
library(shinyjs)
library(lubridate)

server = function(input, output, session) {
  if(exists("appFolder")){
    source(file.path(appFolder, "serverhandler.R"), local = TRUE)
  }else{
    source("serverhandler.R", local = TRUE)
  }

  switch(Sys.info()[['sysname']],
         Windows= {root = "C:\\"},
         Linux  = {root = "~"},
         Darwin = {root = file.path("~", "Desktop")})
  if(!exists("volumes") || is.null(volumes)){
    warning(paste("No root folder is provided, using the default root:" , root))
    volumes <- c(root = file.path(root))
  }else{
      volumes <- c(root = volumes)
  }

  shinyDirChoose(
    input, 'datasetFolder', roots = volumes, hidden = TRUE, session = session
  )

  rValues <- reactiveValues(xlim = NULL,
                             currentAnnotations = NULL,
                             currentAnnotations2 = NULL,
                             masterFolder = NULL,
                             summaryData = NULL,
                             summaryPlot = NULL,
                             annotationData = NULL,
                             rawData = NULL,
                             rawPlot = NULL,
                             begin_xrange = NULL,
                             begin_xrange_raw = NULL,
                             raw_xlim = NULL)

  output$plot1 <- renderPlot({
    input$refreshPlot
    withProgress(message = "Generate summary plot", value = 0.1, {
      Sys.sleep(0.25)
      if(!is.null(rValues$summaryData)){
        if(input$summaryMethod != "SamplingRate"){
          p = SummaryData.ggplot(rValues$summaryData)
        }else{
          p = SamplingRate.ggplot(rValues$summaryData, unit = "Count")
        }
        if(!is.null(rValues$xlim)){
          p = p + coord_cartesian(xlim = rValues$xlim)
          p = p + scale_x_datetime()
        }
        if(!is.null(rValues$annotationData)){
          p = AnnotationData.addToGgplot(p, rValues$annotationData)
        }
        rValues$summaryPlot = p
        rValues$summaryPlot
      }
    })
  })

  output$plot2 <- renderPlot({
    input$refreshRawPlot
    withProgress(message = "Generate raw plot", value = 0.1, {
      Sys.sleep(0.25)
      if(!is.null(rValues$rawData)){
        shinyjs::show("raw_plot_box")
        p = SensorData.ggplot(rValues$rawData)
        if(!is.null(rValues$raw_xlim)){
          p = p + coord_cartesian(xlim = rValues$raw_xlim)
          p = p + scale_x_datetime()
        }
        if(!is.null(rValues$annotationData)){
          p = AnnotationData.addToGgplot(p, AnnotationData.clip(rValues$annotationData,
                                                                rValues$raw_xlim[1],
                                                                rValues$raw_xlim[2]))
        }
        rValues$rawPlot = p
        rValues$rawPlot
      }
    })
  })

  output$info <- renderText({
    paste0(
      "begin=", as.POSIXct(rValues$xlim[1], origin = "1970-01-01"),
      "\nend=", as.POSIXct(rValues$xlim[2], origin = "1970-01-01")

    )
  })

  output$annotationBox = renderInfoBox({
    infoBox(
      title = "Current Annotations",
      value = paste(str_trim(rValues$currentAnnotations), collapse = ","),
      icon = icon("tag")
      )
  })

  output$annotationBox2 = renderInfoBox({
    infoBox(
      title = "Current Annotations",
      value = paste(str_trim(rValues$currentAnnotations2), collapse = ","),
      icon = icon("tag")
    )
  })

  observe(x = generalHandler(input))

  handlePlotDoubleClick(input)

  handlePlotHover(input)

  handlePlotBrush(input)

  handleDatasetFolderChosen(input, session, volumes = volumes)

  handleYearSelection(input, session)

  handleMonthSelection(input, session)

  handleDaySelection(input, session)

  handleHourSelection(input, session)
  
  handleRawDataOffsetSaveClicked(input, session)

  handleComputeSummaryClicked(input, session)

  handleAnnotationSelect(input, session)

  handleSaveImageAsPdf(input, output)

  handleSaveSummaryDataAsCsv(input, output)

  handleShowRawPlot(input, session)
}
