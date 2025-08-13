required_packages <- c("dplyr", "cli", "tidyverse", "devtools")

missing_packages <- required_packages[!sapply(required_packages, require, character.only = TRUE, quietly = TRUE)]

if (length(missing_packages) > 0) {
  install.packages(missing_packages, dependencies = TRUE)
  sapply(missing_packages, require, character.only = TRUE)
}

if (!require("tidytacos", character.only = TRUE, quietly = TRUE)) {
  devtools::install_github("LebeerLab/tidytacos")
}

library(dplyr) 
library(tidyverse)
library(tidytacos)

args <- commandArgs(trailingOnly=TRUE)

required_packages <- c("dplyr", "cli", "tidyverse", "devtools")

missing_packages <- required_packages[!sapply(required_packages, require, character.only = TRUE, quietly = TRUE)]

if (length(missing_packages) > 0) {
  install.packages(missing_packages, dependencies = TRUE)
  sapply(missing_packages, require, character.only = TRUE)
}

if (!require("tidytacos", character.only = TRUE, quietly = TRUE)) {
  devtools::install_github("LebeerLab/tidytacos")
}

library(dplyr) 
library(tidyverse)
library(tidytacos)

args <- commandArgs(trailingOnly=TRUE)

taxonstsv <- args[1]
distributionstsv <- args[2]
outdir <- args[3]

taxons <- read.delim(taxonstsv, header=TRUE)
distributions <- read.delim(distributionstsv, header=FALSE)

readids <- distributions[-1, 1]
taxids <- distributions[1, -1]

if(length(readids) == 0){
  return(0)
}

full_taxonomy <- map(taxids, function(taxid){
  return(taxons[taxons$tax_id == taxid, ]$full_taxonomy)
})

counts <- distributions[-1, -1, drop=FALSE]
counts[is.na(counts)] <- 0
colnames(counts) <- full_taxonomy
counts$read_id <- readids

sampleanalysis_df <- data.frame(
  high_confidence_count = rep(0, length(full_taxonomy)),
  best_guess_count = rep(0, length(full_taxonomy)),
  low_confidence_count = rep(0, length(full_taxonomy)),
  full_taxonomy = full_taxonomy
)

readanalysis_data <- apply(counts, 1, function(read) {
  readid <- read["read_id"]
  
  numeric_vals <- as.numeric(read[names(read) != "read_id"])
  sorted_vals <- sort(numeric_vals, decreasing = TRUE)
  
  max_val <- sorted_vals[1]
  max_colname <- names(read)[names(read) != "read_id"][which.max(numeric_vals)]
  diff_max_second <- sorted_vals[1] - sorted_vals[2]
  
  if(0.02 <= max_val & max_val < 0.98) {
    for(j in 1:length(numeric_vals)) {
      current_val <- numeric_vals[j]
      current_colname <- full_taxonomy[j]
      
      if(current_val == max_val) {
        relevant_row <- sampleanalysis_df[sampleanalysis_df$full_taxonomy == current_colname,]
        sampleanalysis_df[sampleanalysis_df$full_taxonomy == current_colname, "best_guess_count"] <<- 
          sampleanalysis_df[sampleanalysis_df$full_taxonomy == current_colname, "best_guess_count"] + 1
      } else if(current_val > 0.02) {
        relevant_row <- sampleanalysis_df[sampleanalysis_df$full_taxonomy == current_colname,]
        sampleanalysis_df[sampleanalysis_df$full_taxonomy == current_colname, "low_confidence_count"] <<- 
          sampleanalysis_df[sampleanalysis_df$full_taxonomy == current_colname, "low_confidence_count"] + 1
      }
    }
  } else {
    relevant_row <- sampleanalysis_df[sampleanalysis_df$full_taxonomy == max_colname,] 
    sampleanalysis_df[sampleanalysis_df$full_taxonomy == max_colname, "high_confidence_count"] <<- 
      sampleanalysis_df[sampleanalysis_df$full_taxonomy == max_colname, "high_confidence_count"] + 1
  }
  
  return(c(
    read_id=readid,
    best_guess=max_val,
    best_guess_full_taxonomy=max_colname,
    best_guess_min_seperation=diff_max_second
  ))
})

readanalysis_df <- as.data.frame(t(readanalysis_data), stringsAsFactors=FALSE)

dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
write.csv(sampleanalysis_df, paste0(outdir, "/sample_analysis.csv"), row.names=FALSE)
write.csv(readanalysis_df, paste0(outdir, "/read_analysis.csv"), row.names=FALSE)