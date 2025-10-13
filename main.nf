#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { treed_mask } from './modules/forestMask/treed-mask.nf'
include { beetle } from './modules/disturbances/beetle.nf'
//include { tree_species_unmixing } from './modules/treeSpecies/tree-species.nf'

workflow {

    aoi = Channel.fromPath(params.aoi)
    //datacube_definition = Channel.fromPath( params.datacube + '/datacube-definition.prj' )

    // do we need a year as input? It is a parameter
    // mask returns a tuple (id, path(mask))
    // it is not a data cube but a "federation" of tiles
    // add aoi and datacube as inputs?
    mask = treed_mask()
    //mask.final_mask.view()
    print "mask done!"

    // needs datacube, mask, aoi
    beetle = beetle(aoi, mask)
    
    // needs datacube, mask, aoi and disturbance_year from hungry-beetle
    //tree_species_unmixing(datacube, mask)

}