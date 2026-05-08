process GENE_LINKAGE_COMPILATION {

    publishDir "${params.outdir}", mode: 'copy'

    container "${params.container}"

    input:
    path files

    output:
    path "regions_per_gene.csv", emit: results

    script:
    """
    Gene_Linkage_compilation.R ${files}
    """
}
