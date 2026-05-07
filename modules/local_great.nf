process LOCAL_GREAT {

    tag "${meta.sample}_${meta.name}"

    publishDir "${params.outdir}/GREAT_results", mode: 'copy', pattern: "*_localGREAT.tsv"
    publishDir "${params.outdir}/gene_region_links", mode: 'copy', pattern: "*_gene_region_links.tsv"
    publishDir "${params.outdir}/GREAT_objects", mode: 'copy', pattern: "*great_job.rds"

    container "${params.container}"

    input:
    tuple val(meta), path(fg_bed), path(set_path)
    path bg_bed



    output:
    tuple val(meta), path("${meta.sample}_${meta.name}_localGREAT.tsv"), emit: results
    path "${meta.sample}_${meta.name}_gene_region_links.tsv"
    path "${meta.sample}_${meta.name}_great_job.rds"



    script:
    """
    local_rGREAT.R \
        ${fg_bed} \
        ${bg_bed} \
        ${meta.name} \
        ${meta.sample} \
        ./ \
        ${set_path}
    """
}