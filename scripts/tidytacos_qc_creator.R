# Filename: tidytacos_qc_creator.R
# Date Created: 2025/08/05 
# Last Update: 2025/08/06
# Dependencies: None
# Description:
# This R script takes the two resulting files from an emu relative abundance estimation run
# and creates a tidytacos object from it (and writes it back to a given object name)
# example usage: R --slave --no-restore -f tidytacos_creator.R --args $taxons $distributions $tt_objname

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
ttobj_outdir <- args[3]

taxons <- read.delim(taxonstsv)
distributions <- read.delim(distributionstsv, header=FALSE)

left_column <- distributions[-1, 1]
top_row <- distributions[1, -1]
counts_df <- distributions[-1, -1, drop=FALSE]

full_taxonomy_list <- taxons[match(top_row, taxons[, "tax_id"]), "full_taxonomy"]

counts_matrix <- as.matrix(counts_df)
counts_matrix[is.na(counts_matrix)] <- 0

rownames(counts_matrix) <- left_column
colnames(counts_matrix) <- top_row

tt <- tidytacos::create_tidytacos(counts_matrix, taxa_are_columns = TRUE)

taxon_metadata <- taxons[taxons$tax_id %in% top_row, ]
taxonomy <- as_tibble(taxon_metadata)
taxonomy <- select(
  taxonomy,
  taxon = tax_id,
  superkingdom,
  phylum,
  class,
  order,
  family,
  genus,
  species
)

tt <- add_metadata(tt, taxonomy, table_type = "taxa")

tt <- set_rank_names(
  tt, c("superkingdom", "phylum", "class", "order", "family", "genus")
)

tidytacos::write_tidytacos(tt, ttobj_outdir)
