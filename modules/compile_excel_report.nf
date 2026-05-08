process COMPILE_EXCEL_REPORT {

    publishDir "${params.outdir}", mode: 'copy'

    container "${params.container_excel}"

    input:
    path results_csv
    path clustered_csv
    path cluster_summary_csv
    path regions_per_gene_csv
    path ontology_descriptions
    path column_descriptions

    output:
    path "results_report.xlsx", emit: report

    script:
    """
    compile_excel_report.R \
        ${results_csv} \
        ${clustered_csv} \
        ${cluster_summary_csv} \
        ${regions_per_gene_csv} \
        ${ontology_descriptions} \
        ${column_descriptions}
    """
}
