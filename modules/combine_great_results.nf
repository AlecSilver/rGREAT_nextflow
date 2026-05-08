process COMBINE_GREAT_RESULTS {


    publishDir "${params.outdir}", mode: 'copy'

    container "${params.container}"

    input:
    path files


    output:
    path "*.csv", emit: results


    script:
    """
    combine_great_results.R ${files}
    """
}