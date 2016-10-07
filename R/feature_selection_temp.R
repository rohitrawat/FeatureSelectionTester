#!/usr/bin/Rscript
# argv: trg_fname N M type method [val_file] [output_file] [N1_values]

argv <- commandArgs(trailingOnly=TRUE);

rm(list = ls())
argv = vector();
argv[1] = '/home/rohit/Dropbox/Research/DataFiles/Classification/bc_probe_liu_989_2c.train'
argv[2] = '989'
argv[3] = '2'
argv[4] = '1'
argv[5] = 'mRMRe'
# rm(list = ls())
# argv = vector();
# argv[1] = '/tmp/featuresel/data/REDWINEQUALITY-tra-set-1.train'
# argv[2] = '11'
# argv[3] = '1'
# argv[4] = '0'
# argv[5] = 'CFS'
# rm(list = ls())
# argv = vector();
# argv[1] = '/home/rohit/Dropbox/Research/DataFiles/Classification/Gongtrn.dat'
# argv[2] = '16'
# argv[3] = '10'
# argv[4] = '1'
# argv[5] = 'CFS'
# rm(list = ls())
# argv = vector();
# argv[1] = '/home/rohit/Dropbox/Research/DataFiles/Approximation/winequality_red.txt'
# argv[2] = '11'
# argv[3] = '1'
# argv[4] = '0'
# argv[5] = 'EFS'

valArg <- 6;

if (length(argv)<valArg-1) {
  stop("At least 4 arguments must be supplied.")
}

training_file <- argv[1];
data <- read.delim(training_file, header = F);
if (length(argv) >= valArg) {
  validation_file <- argv[valArg];
  data_val <- read.delim(validation_file, header = F);
} else {
  data_val <- data.frame();
}

doCFS <- function(data, isClassification) {
  library(FSelector);
  cat('R: CFS\n')
  names(data)[ncol(data)] <- 'VOUT';

  set.seed(0);
  result <- relief('VOUT ~ .', data);
  print(result);

  o <- order(result$attr_importance, decreasing = T);
  cat('Order function:\n')
  print(o);

  return(o);
}

doRelief <- function(data, isClassification) {
  library(CORElearn);
  cat('R: ReliefFexpRank\n')
  names(data)[ncol(data)] <- 'VOUT';
  
  set.seed(0);
  if(isClassification) {
    method <- 'ReliefFexpRank';
  } else {
    method <- 'RReliefFexpRank';
  }
  estReliefF <- attrEval('VOUT', data,
                         estimator=method, ReliefIterations=30)

  o <- order(estReliefF, decreasing = T);
  cat('Order function:\n')
  print(o);
  
  return(o);
}

doBoruta <- function(data, isClassification) {
  library(Boruta);
  cat('R: Boruta\n')
  names(data)[ncol(data)] <- 'VOUT';
  
  set.seed(0);
  Boruta.result <- Boruta(VOUT~.,data=data,doTrace=2)
  Boruta_imp <- colMeans(Boruta.result$ImpHistory[,1:(ncol(data)-1)])
  # print(Boruta.result$ImpHistory)
  print(Boruta_imp)
  
  o <- order(Boruta_imp, decreasing = T);
  cat('Order function:\n')
  print(o);
  
  return(o);
}

doEFS <- function(data, isClassification) {
  library(EFS);
  cat('R: EFS\n')
  names(data)[ncol(data)] <- 'VOUT';
  
  if(length(unique(data$VOUT))!=2) {
    cat('EFS only works for BINARY-CLASSIFICATION problems.\n');
  }
  
  set.seed(0);
  efs <- ensemble_fs(data, 5, runs=2)
  EFS_imp <- colSums(efs)
  # print(Boruta.result$ImpHistory)
  print(EFS_imp)
  
  o <- order(EFS_imp, decreasing = T);
  cat('Order function:\n')
  print(o);
  
  return(o);
}

domRMRe <- function(data, isClassification) {
  library(mRMRe);
  cat('R: mRMRe\n')
  names(data)[ncol(data)] <- 'VOUT';
  data[,ncol(data)] <- as.numeric(data[,ncol(data)]);
  
  for(N1 in seq(1,ncol(data),10)) {
  set.seed(0);
  filter <- mRMR.classic("mRMRe.Filter", data = mRMR.data(data = data), target_indices = ncol(data),
                         feature_count = N1)
  # scores1 <- scores(filter)[as.character(ncol(data))]
  o1 = solutions(filter);
  print(o1);
  }
  
  o <- order(scores1, decreasing = T);
  cat('Order function:\n')
  print(o);
  
  return(o);
}
# > print(mRMR.classic)
# function (feature_count, ...) 
# {
#   return(new("mRMRe.Filter", levels = rep(1, feature_count), 
#              ...))
# }

data <- rbind(data, data_val);
#print(data);

N <- as.integer(argv[2]);
M <- as.integer(argv[3]);
isClassification <- as.integer(argv[4]);
method <- tolower(argv[5]);

if(isClassification) {
  
  print('Classification file');
  data[,ncol(data)] <- as.factor(data[,ncol(data)]);
  dim(data);
  
  if(method == 'relieff') {
    o <- doRelief(data, isClassification);
  } else if(method == 'boruta') {
    o <- doBoruta(data, isClassification);
  } else if(method == 'cfs') {
    o <- doCFS(data, isClassification);
  } else if(method == 'efs') {
    o <- doEFS(data, isClassification);
  } else if(method == 'mrmre') {
    o <- domRMRe(data, isClassification);
  } else {
    cat('Bad method in feature_selection.R.\n')
  }
  
} else {
  
  print('Regression file');
  x <- data[,1:N];
  o = vector();
  if(M>1) {
    stop('M > 1 is not supported yet.');
  }
  for(i in 1:M) {
    data1 <- cbind(x, data[,N+i])
    if(method == 'relieff') {
      o1 <- doRelief(data1, isClassification);
    } else if(method == 'boruta') {
      o1 <- doBoruta(data1, isClassification);
    } else if(method == 'cfs') {
      o1 <- doCFS(data1, isClassification);
    } else if(method == 'efs') {
      o1 <- doEFS(data1, isClassification);
    } else if(method == 'mrmre') {
      o1 <- domRMRe(data1, isClassification);
    } else {
      cat('Bad method in feature_selection.R.\n')
    }
    o <- union(o, o1);
  }
  
}

if (length(argv) >= 7) {
  output_file = argv[7];
} else {
  output_file = 'feature_order.txt';
}

write.table(o, output_file, sep = '\n', row.names = F,
            col.names = F)
# q()

