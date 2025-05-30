#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { tree_species_unmixing } from './modules/tree-species-unmixing.nf'

workflow {
    dummy = Channel.of(true)
    results = tree_species_unmixing(input_dummy: dummy)
    results.final_output.view()
}
