#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/rgreat_local
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/nf-core/rgreat_local
----------------------------------------------------------------------------------------
*/

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS / WORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//include { RGREAT_LOCAL  } from './workflows/rgreat_local'
include { fromSamplesheet } from 'plugin/nf-validation'
include { LOCAL_GREAT  } from './modules/local_great.nf'
include { COMBINE_GREAT_RESULTS  } from './modules/combine_great_results.nf'
include { CLUSTER_ONTOLOGY_RESULTS } from './modules/cluster_ontology_results.nf'
include { GENE_LINKAGE_COMPILATION } from './modules/gene_linkage_compilation.nf'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NAMED WORKFLOWS FOR PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// WORKFLOW: Run main analysis pipeline depending on type of input
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {

    main:

    // Load the sample bed files
    fg_channel = Channel.fromSamplesheet("input")
    //fg_channel.view()

    // Get list of additioinal gene sets to use
    gene_set_channel = Channel.fromSamplesheet("gene_set_list")
    //gene_set_channel.view()

    // combine the two channels
    // so that each bed file is run with every ontology
    fg_channel.combine(gene_set_channel)
    .map { meta1, fg, meta2, ont ->
        tuple(meta1 + meta2, fg, ont)
    }
    .set { combined_input }
    


    bg_channel = Channel.value(file(params.background))
    
    LOCAL_GREAT(
        combined_input,
        bg_channel
    )

    
    // combine the output into a string
    all_results = LOCAL_GREAT.out.results
        .map { meta, res -> res}
        .collect()

    
    COMBINE_GREAT_RESULTS(all_results)

    CLUSTER_ONTOLOGY_RESULTS(COMBINE_GREAT_RESULTS.out.results)

    all_gene_region_links = LOCAL_GREAT.out.gene_region_links
        .collect()

    GENE_LINKAGE_COMPILATION(all_gene_region_links)

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
