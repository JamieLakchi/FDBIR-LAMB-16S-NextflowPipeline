# Filename: tidytacos_qc_combinator.R
# Date Created: 2025/08/05 
# Last Update: 2025/08/06
# Dependencies: None
# Description:
# This R script takes a list of folder names (created by tidytaco::write_tidytacos(...)) and an outname (all positional arguments)
# and merges all the given tidytaco objects into one, then writes that object back to outname

required_packages <- c("dplyr", "cli", "tidyverse", "devtools")

missing_packages <- required_packages[!sapply(required_packages, require, character.only = TRUE, quietly = TRUE)]

if (length(missing_packages) > 0) {
  install.packages(missing_packages, dependencies = TRUE)
  sapply(missing_packages, require, character.only = TRUE)
}

devtools::install_github("LebeerLab/tidytacos")

library(dplyr) 
library(tidyverse)
library(tidytacos)

args <- commandArgs(trailingOnly = TRUE)
output_name <- args[length(args)]
input_files <- args[-length(args)]

tt_objects <- list()

for (i in seq_along(input_files)) {
  file <- input_files[i]
  if (file.exists(file)) {
    try({
      tt_obj <- tidytacos::read_tidytacos(file)
      tt_objects[[i]] <- tt_obj
    }, silent = TRUE)
  }
}

tt_final <- tt_objects[[1]]

if(length(tt_objects) >= 2) {
  for (i in 2:length(tt_objects)) {
    tt_final <- tidytacos::merge_tidytacos(tt_final, tt_objects[[i]], taxon)
  }
}

tidytacos::write_tidytacos(tt_final, output_name)