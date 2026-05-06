process LOCAL_GREAT {

    tag "${meta.my_sample}_${ont}"

    container "${params.container}"

    publishDir "${params.outdir}", mode: 'copy'

    container "${params.container}"

    input:
    tuple val(meta), path(fg_bed)
    path bg_bed
    val ont


    output:
    path "${meta.my_sample}_${ont}_localGREAT.tsv"
    path "${meta.my_sample}_${ont}_gene_region_links.tsv"
    path "${meta.my_sample}_${ont}_great_job.rds"

    script:
    """


    local_rGREAT.R \
        ${fg_bed} \
        ${bg_bed} \
        ${ont} \
        ${meta.my_sample} \
        ./ 
    """
}