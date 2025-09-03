#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { treed_mask } from './modules/forestMask/treed-mask.nf'
//include { tree_species_unmixing } from './modules/treeSpecies/tree-species.nf'
//include { beetle } from './modules/disturbances/beetle.nf'

workflow {

    aoi = Channel.fromPath(params.aoi)
    datacube = Channel.fromPath(params.datacube)
    datacube_definition = Channel.fromPath( params.datacube + '/datacube-definition.prj' )

    // do we need a year as input? It is a parameter
    // mask returns a tuple (id, path(mask))
    // it is not a data cube but a "federation" of tiles
    // add aoi and datacube as inputs?
    mask = treed_mask()
    mask.final_mask.view()

    // needs datacube, mask, aoi
    // however, disturbances / hungry-beetle and treed_mask use tiles = force_get_tiles() too
    //beetle = beetle(aoi, mask, datacube)
    //beetle.disturbances.view()
    
    // needs datacube, mask, aoi and disturbance_year from hungry-beetle
    //tree_species_unmixing(datacube, mask)

}