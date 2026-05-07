# nf-core/rgreat_local

## Introduction

**nf-core/rgreat_local** is a bioinformatics pipeline for genomic region enrichment analysis of ATAC-seq and ChIP-seq data. It takes peak BED files, runs local [rGREAT](https://bioconductor.org/packages/rGREAT/) enrichment analysis against one or more ontologies or custom gene sets, combines results across all samples and ontologies, and clusters enriched terms by gene-set similarity to reduce redundancy.

**Pipeline steps:**

1. **LOCAL_GREAT** — runs local rGREAT enrichment for each sample × gene-set combination, producing per-run enrichment tables, peak-to-gene linkage files, and serialised rGREAT job objects
2. **COMBINE_GREAT_RESULTS** — merges all per-run enrichment tables into a single CSV annotated with sample, condition, and ontology metadata
3. **CLUSTER_ONTOLOGY_RESULTS** — within each ontology, clusters enriched terms by Jaccard similarity of their linked gene sets and assigns a representative term per cluster

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/get_started/environment_setup/overview) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/get_started/run-your-first-pipeline) with `-profile test` before running the workflow on actual data.

### Samplesheets

**`samplesheet.csv`** — one row per peak BED file (ATAC-seq or ChIP-seq):

```csv
sample,path
young_bias,./data/young_bias_peaks.bed
old_bias,./data/old_bias_peaks.bed
```

**`gene_set_list.csv`** — one row per ontology or custom gene set. `path` is required for `.gmt`/`.rds` files and left empty for built-in rGREAT ontologies (`BP`, `MF`, `CP`). `min_set_size` defaults to 5 if omitted.

```csv
ontology_name,path,min_set_size
BP,,
MF,,
CP,,
MH,./assets/GSEA_gene_sets/mh.all.v2026.1.Mm.entrez.gmt,
MySingleGenes,./assets/my_sets.rds,1
```

| Column | Description |
|---|---|
| `ontology_name` | Identifier used in output filenames and the `Ontology` metadata column |
| `path` | Path to a `.gmt` or `.rds` gene set file; leave empty for built-in ontologies |
| `min_set_size` | Minimum number of genes required in a gene set (default: 5) |

### Running the pipeline

```bash
nextflow run nf-core/rgreat_local \
   -profile singularity \
   --input samplesheet.csv \
   --gene_set_list gene_set_list.csv \
   --background assets/peak_union.bed \
   --outdir results/
```

### Key parameters

| Parameter | Description | Default |
|---|---|---|
| `--input` | Path to sample samplesheet CSV | `samplesheet.csv` |
| `--gene_set_list` | Path to gene set samplesheet CSV | `gene_set_list.csv` |
| `--background` | Background BED file (e.g. consensus peak union) | `./assets/peak_union.bed` |
| `--outdir` | Output directory | `./out` |
| `--container` | Path to Singularity/Apptainer image | — |

## Outputs

| Path | Description |
|---|---|
| `GREAT_results/*_localGREAT.tsv` | Per-run enrichment table with fold enrichment, p-values, and linked genes/regions |
| `gene_region_links/*_gene_region_links.tsv` | Per-run peak-to-gene linkage table with TSS distances |
| `GREAT_objects/*_great_job.rds` | Serialised rGREAT result objects for downstream R analysis |
| `out.csv` | All enrichment results combined, with `Condition`, `Age`, `Bias`, and `Ontology` columns |
| `clustered_results.csv` | Combined results with `cluster`, `cluster_rep`, and `cluster_rep_desc` columns added |
| `cluster_summary.csv` | One row per ontology × cluster with n_terms, n_conditions, best p_adjust, and best fold enrichment |

## Credits

nf-core/rgreat_local was originally written by Alec Silver.

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](docs/CONTRIBUTING.md).

## Citations

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
