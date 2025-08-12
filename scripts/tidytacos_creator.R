# Filename: tidytacos_creator.R
# Date Created: 2025/08/05 
# Last Update: 2025/08/06
# Dependencies: None
# Description:
# This R script takes the resulting file from emu combine-output
# and creates a tidytacos object from it (and writes it back to a given object name)
# example usage: R --slave --no-restore -f tidytacos_creator.R --args $combined $tt_objname

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

args <- commandArgs(trailingOnly=TRUE)

combined <- args[1]
objname <- args[2]

tsv <- read.delim(combined)

tsv[is.na(tsv)] <- 0

taxonomy <- select(
  tsv,
  kingdom=superkingdom,
  phylum,
  class,
  order,
  family,
  genus,
  species
)

taxonomy$taxon <- taxonomy$species

taxonomy <- as.tibble(taxonomy)

counts <- select(tsv,
                superkingdom:last_col(),
                -superkingdom)

counts <- as.matrix(counts)

rownames(counts) <- taxonomy$species

tt <- tidytacos::create_tidytacos(counts, taxa_are_columns = FALSE)

tt <- tidytacos::add_metadata(tt, taxonomy, table_type = "taxa")

tt <- tidytacos::set_rank_names(tt,  c("kingdom", "phylum", "class", "order", "family", "genus", "species"))

tidytacos::write_tidytacos(tt, objname)