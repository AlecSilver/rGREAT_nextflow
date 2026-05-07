#!/usr/bin/env Rscript


suppressPackageStartupMessages({
  library(tidyverse)
  #library(readxl)

  library(TxDb.Mmusculus.UCSC.mm9.knownGene)
  library(org.Mm.eg.db)
  library(GenomicRanges)
})

args <- commandArgs(trailingOnly = TRUE)



## -----------------------------------------------------------------------------
# get list of all files. do not include any that do not have any data
files <- args %>%
  set_names(basename(.)) %>%
  keep(~ length(readLines(.x)) > 1)
#id	genome_fraction	observed_region_hits	fold_enrichment	p_value	p_adjust	mean_tss_dist	observed_gene_hits	gene_set_size	fold_enrichment_hyper	p_value_hyper	p_adjust_hyper	genes	regions

#id	description	genome_fraction	observed_region_hits	fold_enrichment	p_value	p_adjust	mean_tss_dist	observed_gene_hits	gene_set_size	fold_enrichment_hyper	p_value_hyper	p_adjust_hyper	genes	regions
col_types <- c()
data <- map_dfr(files, ~ read_tsv(.x , show_col_types = FALSE) %>% mutate(id = as.character(id)), .id = "source_file") %>% 
  mutate(Condition = tools::file_path_sans_ext(basename(source_file)) ) %>%
  mutate(Condition = str_remove(Condition, "_localGREAT")) %>%
  mutate(Condition = str_remove(Condition, "local_great_results")) %>%
  mutate(Condition = str_remove(Condition, "_STRONG")) %>%
  separate(Condition,
           into = c("Age", "Bias", "Ontology"),
           sep = "_",
           remove = F) %>%
  mutate(Condition = paste0(Age,"_", Bias)) %>%
  relocate(Condition, Age, Bias, Ontology) %>%
  relocate(source_file, .after = last_col()) 

write_csv(data, "out.csv")