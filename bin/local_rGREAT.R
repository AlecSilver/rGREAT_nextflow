#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
  library(rGREAT)
  library(rtracklayer)
  library(TxDb.Mmusculus.UCSC.mm9.knownGene)
  library(org.Mm.eg.db)
  #source("bin/gene_linkage.R") 
})

#' creates a dataframe that links ATAC sites to genes
#'
#' @param great_job the great job
#' @returns dataframe of linkages
get_expanded_gene_associations <- function(great_job ) {
  gr <- getRegionGeneAssociations(great_job , use_symbols = F)
  gr_symbols <- getRegionGeneAssociations(great_job)
  
  # columns
  genes <- mcols(gr)$annotated_genes
  gene_symbols <- mcols(gr_symbols)$annotated_genes
  dist  <- mcols(gr)$dist_to_TSS
  
  # how many genes per peak
  n <- elementNROWS(genes)
  
  # repeat each GRanges row appropriately
  gr_expanded <- rep(gr, n) 
  
  # flatten lists
  mcols(gr_expanded)$gene <- unlist(genes)
  mcols(gr_expanded)$gene_symbol <- unlist(gene_symbols)
  mcols(gr_expanded)$dist_to_TSS <- as.numeric(unlist(dist))
  
  return(as.data.frame(gr_expanded) %>%
           dplyr::select(-annotated_genes, - strand))
}

#' creates a dataframe representing GO terms
get_ontology_df <- function(res){
  ontology_set <- res@gene_sets
  
  go_df <- enframe(ontology_set,
                   name = "GO_term",
                   value = "gene") %>%
    unnest(gene) |>
    unique()
  return(go_df)
}

#' links GO terms to genes
#' @param gr_df from get_expanded_gene_associations
#' @param go_df from get_ontology_df
#' @returns dataframe showing genes linked to GO term
link_genes <- function(gr_df, go_df ) {
  peak_go <- gr_df %>%
    inner_join(go_df, by= join_by(gene)) %>%
    distinct(gene_symbol, GO_term) %>%
    group_by(GO_term) %>%
    summarize(
      genes = paste(gene_symbol, collapse = ", "),
      .groups = 'drop' # Recommended to drop the grouping structure afterward
    )
  return(peak_go)
}

# will get all linked regions to a GO term
link_regions <- function(gr_df, go_df ) {
  gr_df <- gr_df %>%
    mutate(region = paste(seqnames, start,end, sep = "_"))
  
  peak_go <- gr_df %>%
    inner_join(go_df, by= join_by(gene)) %>%
    distinct(region, GO_term) %>%
    group_by(GO_term) %>%
    summarize(
      regions = paste(region, collapse = ", "),
      .groups = 'drop' # Recommended to drop the grouping structure afterward
    )
}

args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {
  stop("Usage: run_local_great.R <foreground.bed> <background.bed> <BP|CP|MF|SG> <output_prefix> <out_folder>")
}
# SG stands for single gene, and will test all genes that had differential expression p<= 0.05
fg_file      <- args[1]
bg_file      <- args[2]
ont_str      <- args[3]
out_prefix   <- args[4]
out_path     <- args[5]
ont_path     <- args[6]
min_set_size <- if (length(args) >= 7 && nchar(args[7]) > 0) as.integer(args[7]) else 5L


# file paths are loaded by extension (.rds or .gmt).
ext <- tools::file_ext(ont_path)
ont <- if (ext == "rds") readRDS(ont_path) else read_gmt(ont_path)



cat("Loading regions...\n")

fg <- import(fg_file)
bg <- import(bg_file) %>% # remove sex chromosomes if present
  dropSeqlevels( c("chrX", "chrY"), pruning.mode = "coarse")

txdb <- TxDb.Mmusculus.UCSC.mm9.knownGene

cat("Running GREAT locally...\n")


res <- great(
  gr                = fg,
  background        = bg,
  gene_sets         = ont,
  tss_source        = "mm9",
  min_gene_set_size = min_set_size
)


df <- getEnrichmentTables(res)
cat("Adding connected genes...\n")


gr_df <- get_expanded_gene_associations(res)
go_df <- get_ontology_df(res)
linked_genes <- link_genes(gr_df, go_df )
linked_regions <- link_regions(gr_df, go_df )
df <- df %>%
  left_join(linked_genes, join_by(id == GO_term)) %>%
  left_join(linked_regions, join_by(id == GO_term))

cat("Saving results...\n")

write.table(
  df,
  paste0(out_path, out_prefix,"_", ont_str, "_localGREAT.tsv"),
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

write.table(
  gr_df,
  paste0(out_path, out_prefix,"_", ont_str, "_gene_region_links.tsv"),
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

saveRDS(res, file = paste0(out_path, out_prefix,"_" , ont_str, "_great_job.rds"))

cat("Done!")