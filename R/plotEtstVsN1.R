#!/usr/bin/Rscript
# argv: eps_name isClass csv1 name1 csv2 name2 ...

argv <- commandArgs(trailingOnly = TRUE)

# rm(list = ls())
# argv = vector()
# argv[1] = "/tmp/featuresel/images/CONCRETE3_ReliefF_EtrgEstVsN1.eps"
# argv[2] = 0
# argv[3] = "/tmp/featuresel/results/CONCRETE3_ReliefF_EtrgEstVsN1.csv"
# argv[4] = 'Boruta'
# argv[6] = 'CFS'
# argv[7] = '/home/rohit/tmpfs/featuresel/results/WHITEWINEQUALITY4_EtrgEstVsN1.csv'
# argv[8] = 'ReliefF'

# rm(list = ls())
# argv = vector()
# argv[1] = "/home/rohit/tmpfs/featuresel/images/BCANCER9891_Boruta_EtrgEstVsN1.eps" 
# argv[2] = "/home/rohit/tmpfs/featuresel/results/BCANCER9891_Boruta_EtrgEstVsN1.csv"
# argv[3] = 'Boruta'

if (length(argv) < 4) {
  stop("4 or more arguments must be supplied.")
}

linePlot <- function(xCol, yCols, xlabel, ylabel, legendTitles, smoothen = T, subLabel = NULL, output = NULL) {
  if (smoothen) {
    for (i in 1:ncol(yCols)) {
      yCols[, i] <- lowess(yCols[, i], f = 0.1)$y
    }
  }
  
  if(!is.null(output)) {
    setEPS()
    postscript(output, width = 4.5, height = 5, horizontal = FALSE, onefile = FALSE, paper = "special")
  }
  
  print(yCols)
  print(nrow(yCols))
  print(ncol(yCols))
  str(yCols)
  
  ylim1 = NULL
  
  minima = min(yCols)
  
  maxima = max(yCols)
  
  fullRange = maxima - minima
  
  legendAreaClearance = 0; #maxima - min(yCols[1:round(nrow(yCols) / 2), ])
  
  if (legendAreaClearance < 0.2 * fullRange) {
    ylim1 <- c(minima, maxima + 0.2 * fullRange)
    print(ylim1)
    print(c(max(yCols), min(yCols)))
  }
  
  # atop(N[it],paste('(',letters[i],')'))
  matplot(
    xCol,
    yCols,
    type = "l",  # line plot
    lwd = 2,  # line wdith
    lty = 1:ncol(yCols),  # line types
    col = 1:ncol(yCols),  # line colors
    ylim = ylim1,  # y axis limit
    xlab = xlabel, # bquote('Number of features' ~ (N[1]))
    ylab = ylabel  # "Mean squared error"
  )
  legend(
    "topright",  # legend position
    legend = legendTitles, # c(expression(MSE[TESTING])), #, expression(MSE[VALIDATION])),
    lty = 1:ncol(yCols), # same type as the plot
    col = 1:ncol(yCols),
    lwd = 2
  )
  if(!is.null(subLabel)) {
    #u <- paste('(',letters[i],')') # generate tiny (a), (b), (c) to embed in the plot
    mtext(subLabel, side=1, line=4)
  }
  
  if(!is.null(output)) {
    dev.off();
  }
}


output <- argv[1]
isClassification <- as.numeric(argv[2])
plot_files = vector()
legendTitles = vector()
data = list()
for(i in 1:((length(argv)-2)/2)) {
  plot_files[i] <- argv[2*i+1]
  legendTitles[i] <- argv[2*i+2]
  data[[i]] <- read.csv(plot_files[i], header = F)
}
debugging <- 1
if(debugging) {
  print(output)
  print(isClassification)
  print(plot_files);
  print(legendTitles);
  # print(argv)
}


N1Col = 1

tstCol = 3

xCol = as.data.frame(data[[1]][, N1Col])
yCols = data.frame(data[[1]][, tstCol])
if(length(plot_files)>1) {
  for(i in 2:length(plot_files)) {
    yCols = cbind(yCols, data[[i]][, tstCol])
  }
}

# print(data)
# print(data[, N1Col])
# print(tstCol)
# print(data[, tstCol])
if(isClassification) {
  yLabel <-  bquote('Avg. 10-fold' ~ P[e-test])
} else {
  yLabel <- bquote('Avg. 10-fold' ~ MSE[test])
}

linePlot(xCol, yCols, bquote('Number of features' ~ (N[1])), yLabel, legendTitles, output = output)
