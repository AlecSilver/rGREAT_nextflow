#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(openxlsx)
})

args <- commandArgs(trailingOnly = TRUE)
results_csv          <- args[1]
clustered_csv        <- args[2]
cluster_summary_csv  <- args[3]
regions_per_gene_csv <- args[4]
ontology_desc_xlsx   <- args[5]
column_desc_csv      <- args[6]

results          <- read_csv(results_csv,          show_col_types = FALSE)
clustered        <- read_csv(clustered_csv,        show_col_types = FALSE)
cluster_summary  <- read_csv(cluster_summary_csv,  show_col_types = FALSE)
regions_per_gene <- read_csv(regions_per_gene_csv, show_col_types = FALSE)
ontology_desc    <- read.xlsx(ontology_desc_xlsx)
column_desc      <- read_csv(column_desc_csv,      show_col_types = FALSE)

wb <- createWorkbook()

addWorksheet(wb, "Results")
writeData(wb, "Results", results)

addWorksheet(wb, "Clustered Results")
writeData(wb, "Clustered Results", clustered)

addWorksheet(wb, "Cluster Summary")
writeData(wb, "Cluster Summary", cluster_summary)

addWorksheet(wb, "Regions Per Gene")
writeData(wb, "Regions Per Gene", regions_per_gene)

addWorksheet(wb, "Ontology Descriptions")
writeData(wb, "Ontology Descriptions", ontology_desc)

addWorksheet(wb, "Column Descriptions")
writeData(wb, "Column Descriptions", column_desc)

saveWorkbook(wb, "results_report.xlsx", overwrite = TRUE)
