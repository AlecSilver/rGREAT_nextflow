#!/usr/bin/env bash

# runs the nextflow pipeline with the specified config file
module load miniconda
module load nextflow
#conda activate nf-core-env
nextflow run -profile singularity main.nf -resume