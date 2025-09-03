#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { force_get_tiles; force_analysis_masks } from '../common/force.nf'

include { stats_reference_period } from './reference-statistics.nf'
include { residuals_monitoring_period } from './monitoring-residuals.nf'
include { disturbances_monitoring_period } from './monitoring-disturbances.nf'

/*
    Nextflow adaptation of https://github.com/ForestPulse/hungry-beetle-core
    using ghcr.io/forestpulse/hungry-beetle-core:latest, with its required libraries and
    already containing a copy of said repository. 
    
    Workflow is an based on https://github.com/ForestPulse/hungry-beetle
*/

workflow {
  //add defaults.. or demand aoi, mask and datacube values on CLI
  aoi = Channel.fromPath(params.aoi)
  datacube = Channel.fromPath(params.datacube)
  datacube_definition = Channel.fromPath( datacube + '/datacube-definition.prj' )

  mask = Channel.fromPath(params.mask)
  if (params.disturbances.mask_is_vector) {
    masks = force_analysis_masks(mask, datacube_definition)
  } else {
    masks = mask
  }
  
  beetle(aoi, masks, datacube)
}

workflow beetle{
  take:
  aoi
  mask //assume we receive a properly tiled mask already
  datacube

  main:
  datacube_definition = Channel.fromPath( datacube + '/datacube-definition.prj' )

  // retrieve processing extent and spatial processing units (tiles)
  tiles = force_get_tiles(aoi, datacube_definition)
  // | view

  combined_input = datacube
    | combine(mask)
    | combine(tiles)

  // compute statistics (std dev.) in reference period
  stats = combined_input
    | stats_reference_period
    //| view

  // compute residuals in monitoring period
  residuals = combined_input
    | residuals_monitoring_period
    //| view

  // detect disturbances, and do some postprocessing-analysis
  disturbances_monitoring_period(stats, residuals)

}
