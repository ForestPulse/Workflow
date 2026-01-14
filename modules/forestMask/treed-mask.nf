#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { force_get_tiles; force_analysis_masks; force_finish } from '../common/force.nf'

include { fold_TSA_labels } from './fold-TSA-labels.nf'
include { obtain_samples } from './obtain-samples.nf'
include { split_samples; augment; aggregate_weekly; train; predict; validation } from './model.nf'
include { fold_TSA_aoi } from './fold-TSA-aoi.nf'

/*
    Nextflow adaptation of https://github.com/ForestPulse/tree-mask
    using ghcr.io/forestpulse/tree-mask:latest, with its required libraries and
    already containing a copy of said repository
*/

workflow {
    treed_mask()
}

workflow treed_mask {

    main:
    labels = Channel.fromPath(params.forestMask.labels)
    aoi = Channel.fromPath(params.aoi)
    datacube = Channel.fromPath(params.datacube)
    datacube_definition = Channel.fromPath( params.datacube + '/datacube-definition.prj' )

    // Evaluate if mask needs conversion to tiles
    if (params.forestMask.labels_is_vector) {
        labels_mask = make_processing_mask("training_point_mask", labels, datacube_definition)
    } else {
        labels_mask = labels
    }

    tiles = force_get_tiles(aoi, datacube_definition)
    
    // note: samples does not return a data cube nor tiles, but .txt files
    samples = datacube
        | combine(labels_mask)
        | combine(tiles)
        | fold_TSA_labels
        | obtain_samples
    
    // Renaming the output files in `obtain_samples` saves so much trouble
    files = samples.multiMap{
        dir, mask, tile, x, y, _ ->
            coord:       file("${dir}/*coord.txt")
            sample:      file("${dir}/*sample.txt")
            response:    file("${dir}/*response.txt")
    }

    coord_ch    = files.coord.collect().map { files -> tuple('coord', files) }
    sample_ch   = files.sample.collect().map { files -> tuple('sample', files) }
    response_ch = files.response.collect().map { files -> tuple('response', files) }
    
    // Nextflow will not handle running the same task with different parameters explicitly
    all_files = (coord_ch.concat(sample_ch).concat(response_ch)) | concatenateFiles

    // Returns a convenient tuple of paths (3_split, 4_augmented, 5_fold, 6_models)
    models = all_files
        | collect
        | split_samples
        | augment
        | aggregate_weekly
        | train

    //TODO: Validation publication
    // models | validation    

    // Assuming legal_mask is already cubed, else:
    //legal_mask_cube = make_processing_mask("legal_forest_mask", legal_mask, datacube_definition)
    ch_legal = Channel.fromPath("${params.forestMask.legal_mask}/*/legal_forest_mask.tif")
        | map { path -> tuple(path.parent.name, path) }

    // AOI is sampled using the area of Germany as mask (most general case)
    de_mask = Channel.fromPath(params.forestMask.de_mask)
    fold_aoi = datacube
        | combine(de_mask)
        | combine(tiles)
        | fold_TSA_aoi

    //every tile is a datacube, thus the methods can be used directly
    //what happens if we have mask, but no tile? fails on previous combine, it should
    model_directory = models.map{it[-1]}
    prediction = fold_aoi.map{tuple(it[0], it[2], it[3], it[4])}
        | combine(model_directory)
        | predict

    if (!params.forestMask.use_prev_year) {
        ch_proc = Channel.empty() //no mask
    } else {
        ch_proc = Channel.fromPath("${params.processing_mask_dir}/*/processing_mask_${params.forestMask.year - 1}.tif")
        .map { path -> tuple(path.parent.name, path) }
    }

    final_mask = prediction
    | combine(ch_legal, by:0)
    | join(ch_proc, remainder:true) // if there's no previous year processing mask
    | merge_masks

    //if this works, we can remove the publishDir on merge_masks
    final_mask.map{tuple(it[3], it[0], it[1], it[2], "processing_mask")}
    | force_finish

    emit:
    final_mask

}

process merge_masks {
    label 'tree_mask'
    label 'multithread'
    label 'intensive'

    input:
    tuple val(id), val(tile_X), val(tile_Y), path(prediction), path(legal), val(prev_year)

    //publishDir "${params.processing_mask_dir}", mode: 'copy', overwrite: true

    output:
    tuple val(id), val(tile_X), val(tile_Y), path("${id}/processing_mask*.tif")
    //tuple val(id), path("${id}/processing_mask_${params.forestMask.year}.tif")

    script:
    if( !prev_year ) {
        """
        mkdir -p "${id}"
        gdal_calc.py \
            -A $prediction/LC_forest_${params.forestMask.year}.tif \
            -B $legal \
            --outfile="${id}/processing_mask_${params.forestMask.year}.tif" \
            --calc="A*(A>=B) + B*(B>A)"
        """
    }
    else {
        """
        mkdir -p "${id}"
        gdal_calc.py \
            -A $prediction/LC_forest_${params.forestMask.year}.tif \
            -B $legal \
            -C $prev_year \
            --outfile="${id}/processing_mask_${params.forestMask.year}.tif" \
            --calc="A*(A>=B)*(A>=C) + B*((B>A)*(B>=C)) + C*((C>A)*(C>B))"
        """
    }
}

// TODO: generalization of force/force_analysis_masks
process make_processing_mask{
    label 'force'

    input:
    val tag
    path origin
    path datacube_definition

    output:
    path "${tag}"

    """
    mkdir "${tag}"
    cp "${datacube_definition}" -t "${tag}"
    force-cube \
        -o "${tag}" \
        "${origin}"
    """

}

process concatenateFiles {
    input:
    tuple val(name), path(files)

    output:
    path("${name}.txt")

    script:
    """
    cat ${files.join(' ')} > ${name}.txt
    """
}