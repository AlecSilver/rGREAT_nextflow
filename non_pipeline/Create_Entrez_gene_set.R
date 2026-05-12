library(AnnotationDbi)
library(org.Mm.eg.db)

all_entrez <- keys(org.Mm.eg.db, keytype = "ENTREZID")
all_entrez <- unique(all_entrez[!is.na(all_entrez)])

# Map Entrez IDs to gene symbols
symbols <- mapIds(org.Mm.eg.db,
                  keys       = all_entrez,
                  column     = "SYMBOL",
                  keytype    = "ENTREZID",
                  multiVals  = "first"
)

# Drop any that didn't map
valid <- !is.na(symbols)
all_entrez <- all_entrez[valid]
symbols    <- symbols[valid]

# Create sets: name = gene symbol, value = Entrez ID
gene_sets <- setNames(
  lapply(all_entrez, function(x) x),
  symbols
)

saveRDS(gene_sets, file = "ref/mm9_all_symbol_one_gene_per_set.rds")

print("number of Genes:")
length(gene_sets)

print("First 3:")
head(gene_sets, 3)
