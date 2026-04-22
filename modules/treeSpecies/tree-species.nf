#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { spline_coefficients }                             from '../common/spline-coefficients.nf'
include { extract_pure; make_library; make_library_tile }   from './species-model.nf'
include { train_ANN; predict_species }                      from './species-model.nf'
include { normalization; coloring; validation }             from './species-model.nf'

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
    datacube = spline_coefficients(params.spline.DWD_data) //Special Spline Data Cube
    tiles = force_get_tiles(aoi, datacube_definition)

    pure_elements = extract_pure(datacube, training_points)

    model_full = make_library(pure_elements)
    | train_ANN

    //tentative approach
    model_per_tile = pure_elements
    | combine(datacube)
    | make_library_tile
    | train_ANN

    samples = tiles //or we use the datacube tiles as pairs [id, coef]
    | combine(datacube)
    | combine(model_per_tile)
    | combine(model)
    | predict_species
    | normalization
    | coloring

    samples | validation

    emit:
    samples

}