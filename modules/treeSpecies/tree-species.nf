#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { force_get_tiles; force_analysis_masks } from '../common/force.nf'

include { thermal_time_spline } from './thermal-time.nf'
//TODO: Thermal Time
include { extract_pure; make_library; train_ANN; predict_species; normalization; coloring } from './species-model.nf'

/*
    Nextflow adaptation of https://github.com/ForestPulse/tree-species-unmixing
    using ghcr.io/forestpulse/tree-species-unmixing:dev, with its required libraries and
    already containing a copy of said repository
*/

workflow {
  tree_species_unmixing()
}

workflow tree_species_unmixing {
    take:
    forest_mask //assuming both masks use the same area, tiles should match
    disturbance_mask

    main:
    training_points = Channel.path(params.treeSpecies.training_points)
    datacube = thermal_time_spline(params.datacube)//Special Spline Data Cube
    /*
    divide into tiles
    apply spline udf for thermal time
    gather them up
    */

    //final output is a '3_trained_model' directory storing n models
    models = extract_pure(datacube, training_points)
    | make_library
    | train_ANN

    tiles = force_get_tiles(aoi, datacube_definition)
    
    ch_legal = Channel.fromPath("${params.forestMask.legal_mask}/*/legal_forest_mask.tif")
    | map { path -> tuple(path.parent.name, path) }

    //from here on, cube can be divided into tiles, thus use our new masks
    samples = tiles
    | combine(models)
    | combine(datacube)
    | predict_species //tuple(id, prediction)
    | combine(forest_mask) //pre-process so you can join by ID
    | combine(disturbance_mask) //pre-process so you can join by ID
    | normalization
    | coloring

    emit:
    samples

}