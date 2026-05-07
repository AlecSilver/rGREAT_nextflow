#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(tidyverse)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) {
  stop("Usage: cluster_ontology_results.R <combined.csv> [padj_cutoff] [cluster_height]")
}

input_csv      <- args[1]
padj_cutoff    <- if (length(args) >= 2) as.numeric(args[2]) else 0.05
cluster_height <- if (length(args) >= 3) as.numeric(args[3]) else 0.7

data <- read_csv(input_csv, show_col_types = FALSE)

jaccard_sim <- function(a, b) {
  n_inter <- length(intersect(a, b))
  n_union <- length(union(a, b))
  if (n_union == 0L) 0.0 else n_inter / n_union
}

# For each term, union gene sets across all conditions so clustering uses
# stable gene-set identity rather than condition-specific peak linkage.
aggregate_gene_sets <- function(df) {
  df %>%
    filter(!is.na(genes), nchar(genes) > 0L) %>%
    group_by(id) %>%
    summarise(
      genes_union = list(unique(unlist(str_split(genes, ",\\s*")))),
      best_padj   = min(p_adjust, na.rm = TRUE),
      .groups     = "drop"
    )
}

build_cluster_map <- function(term_stats, h) {
  n <- nrow(term_stats)
  if (n == 0L) return(tibble(id = character(), cluster = integer()))
  if (n == 1L) return(tibble(id = term_stats$id, cluster = 1L))

  gene_lists <- term_stats$genes_union %>% set_names(term_stats$id)
  ids        <- term_stats$id

  sim <- matrix(0.0, n, n, dimnames = list(ids, ids))
  diag(sim) <- 1.0
  for (i in seq_len(n - 1L)) {
    for (j in (i + 1L):n) {
      v         <- jaccard_sim(gene_lists[[i]], gene_lists[[j]])
      sim[i, j] <- v
      sim[j, i] <- v
    }
  }

  hc     <- hclust(as.dist(1.0 - sim), method = "average")
  labels <- cutree(hc, h = h)
  tibble(id = names(labels), cluster = as.integer(labels))
}

add_clusters <- function(df, h) {
  term_stats  <- aggregate_gene_sets(df)
  cluster_map <- build_cluster_map(term_stats, h)

  if (nrow(cluster_map) == 0L) {
    return(df %>% mutate(
      cluster          = NA_integer_,
      cluster_rep      = NA_character_
    ))
  }

  # Representative term per cluster: best p_adjust across any condition,
  # with p_adjust_hyper as tie-breaker
  rep_map <- df %>%
    inner_join(cluster_map, by = "id") %>%
    group_by(cluster) %>%
    slice_min(order_by = tibble(p_adjust, p_adjust_hyper), n = 1L, with_ties = FALSE) %>%
    ungroup() %>%
    select(cluster, cluster_rep = id)

  df %>%
    left_join(cluster_map, by = "id") %>%
    left_join(rep_map, by = "cluster")
}

result <- data %>%
  group_by(Ontology) %>%
  filter(p_adjust <= padj_cutoff, p_adjust_hyper <= padj_cutoff) %>%
  group_modify(~ add_clusters(.x, cluster_height)) %>%
  ungroup()%>%
  relocate(any_of(c("cluster","cluster_rep")), .after = id) 

cluster_summary <- result %>%
  filter(!is.na(cluster)) %>%
  group_by(Ontology, cluster, cluster_rep) %>%
  summarise(
    n_terms              = n_distinct(id),
    n_conditions         = n_distinct(Condition),
    best_p_adjust        = min(p_adjust, na.rm = TRUE),
    best_fold_enrichment = max(fold_enrichment, na.rm = TRUE),
    .groups              = "drop"
  ) %>%
  arrange(Ontology, cluster) 

write_csv(result,          "clustered_results.csv")
write_csv(cluster_summary, "cluster_summary.csv")

cat(sprintf(
  "Done: %d unique terms across %d ontologies grouped into %d clusters\n",
  n_distinct(result$id),
  n_distinct(result$Ontology),
  n_distinct(result$cluster, na.rm = TRUE)
))
