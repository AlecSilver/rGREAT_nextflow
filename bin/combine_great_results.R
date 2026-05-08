#!/usr/bin/env Rscript


suppressPackageStartupMessages({
  library(tidyverse)
})

args <- commandArgs(trailingOnly = TRUE)



## -----------------------------------------------------------------------------
# get list of all files. do not include any that do not have any data
files <- args %>%
  set_names(basename(.))

files <- files[lengths(lapply(files, readLines)) > 1]
#id	genome_fraction	observed_region_hits	fold_enrichment	p_value	p_adjust	mean_tss_dist	observed_gene_hits	gene_set_size	fold_enrichment_hyper	p_value_hyper	p_adjust_hyper	genes	regions

#id	description	genome_fraction	observed_region_hits	fold_enrichment	p_value	p_adjust	mean_tss_dist	observed_gene_hits	gene_set_size	fold_enrichment_hyper	p_value_hyper	p_adjust_hyper	genes	regions
col_types <- c()
data <- map_dfr(files, ~ read_tsv(.x , show_col_types = FALSE) %>% mutate(id = as.character(id)), .id = "source_file") %>% 
  mutate(Source = tools::file_path_sans_ext(basename(source_file)) ) %>%
  mutate(Source = str_remove(Source, "_localGREAT")) %>%
  mutate(
    Ontology = str_extract(Source, "[^_]+$"),
    Condition = str_remove(Source, "_[^_]+$")
  ) %>%
  relocate(Condition, Ontology) %>%
  relocate(source_file, .after = last_col()) 

write_csv(data, "out.csv")