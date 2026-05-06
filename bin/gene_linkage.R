# this script contains functions in order to link genes and sites to GO-terms

library(GenomicRanges)
library(S4Vectors)
library(tidyverse)

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

