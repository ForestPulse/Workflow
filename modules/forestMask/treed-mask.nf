#!/usr/bin/env nextflow
nextflow.enable.dsl=2

/*
to do: how to automate nextflow with future web app parameters
performance tests for pixel-wise operations
validations via "project name" like Hungry-Beetle
*/

workflow {
    treed_mask()
}

workflow treed_mask {
    
    load_treed() //TODO
/*
    "labels.gpkg"
    "legal.forest.gpkg"
    "aoi.gpkg"
    "old-mask.gpkg" //if exists, is already in a digestible format
    "datacube_definition.prj"
*/

    //assuming Geopackages on both cases
    labels_mask = make_processing_mask("labels", load_treed.out.labels, params.datacube_definition)
    legal_forest_mask = make_processing_mask("legal-forest", load_treed.out.legal_forest, params.datacube_definition)

    //AOI tiles
    tiles = force_get_tiles(
        load_treed.out.aoi, 
        load_treed.out.datacube_definition
    )

    // generate samples and split them in train and test
    samples = load.out.datacube
        | combine(labels_mask)
        | combine(tiles)
        | fold_TSA_labels
        | obtain_samples //has an internal conversion to fit force_higher_level
        | collect
        | export_csv
        //TODO test if parameter is being sent correctly, else combine
        | split_samples(ratio: 0.7)

    // train model. returns model path (assuming a single one)
    model = samples.train
        | augment
        | aggregate_weekly
        | train

    // for future use
    validations = samples.test | aggregate_weekly

    // perform predictions on weekly aggregates for AOI
    predictions = load_treed.out.datacube
        | combine(tiles) //assuming no mask here
        | fold_TSA_aoi
        | map(it[0]) //we only need the .tif routes
        | combine(model)
        | predict //gets fed a tuple (.tif, model)
        | binarize

    // merge results with already existing masks. returns a location
    final_mask = binary_tile_max(legal_forest_mask, old_mask, predictions) //TODO

    emit:
    final_mask
}

// there is an argument to move these two to obtain-samples.nf
process export_csv {
    input:
    val values

    output:
    path "samples.csv"

    script:
    """
    {
      echo "value"
      printf "%s\\n" "${values[@]}"
    } > samples.csv
    """
}

process split_samples {
    input:
    path input_csv
    val ratio

    output:
    path "train.npy" into train
    path "test.npy" into test

    script:
    //split data to be implemented
    """
    split_data.py $input_csv $ratio //for example
    """
}