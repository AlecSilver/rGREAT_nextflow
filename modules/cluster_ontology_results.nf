process CLUSTER_ONTOLOGY_RESULTS {

    publishDir "${params.outdir}", mode: 'copy'

    container "${params.container}"

    input:
    path combined_csv

    output:
    path "clustered_results.csv", emit: clustered
    path "cluster_summary.csv",   emit: summary

    script:
    """
    cluster_ontology_results.R ${combined_csv} ${params.padj_cutoff} ${params.cluster_height}
    """
}
