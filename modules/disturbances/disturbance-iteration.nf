#!/usr/bin/env nextflow

nextflow.enable.dsl=2

//we may need to include a tile_id indicator


workflow disturbances_iteration {

    take:
    prev_state

    main:
    prev_state.view { "ITERATION INPUT ${it}" }
    next_state = prev_state
    | reference_period
    | spectral_index
    | disturbance_detection
    | update_mask

    emit:
    next_state
}

process reference_period {
    label 'disturbances'

    //mask(year), coef(year-1), ref_per(year-1)
    input:
    tuple path(mask), path(coefficients), path(reference_period)

    //mask(year), coef(year), ref_per(year)
    output:
    tuple path(mask), path('output/coefficients*.tif'), path('output/reference_period*.tif')

    script:
    """
    mkdir output
    reference_period...
    """
}

process spectral_index {
    label 'disturbances'

    //mask(year), coef(year), ref_per(year)
    input:
    tuple path(mask), path(coefficients), path(reference_period)

    //mask(year), coef(year), ref_per(year), crem_folder
    output:
    tuple path(mask), path(coefficients), path(reference_period), path(crem_folder)
    
    script:
    """
    # get BOA
    # get QAI
    spectral_index...
    """
}

process disturbance_detection {
    label 'disturbances'

    //mask(year), coef(year), ref_per(year), crem_folder (which is a known location?)
    input:
    tuple path(mask), path(coefficients), path(reference_period), path(crem_folder)

    //mask(year), coef(year), ref_per(year), disturbances(year)
    output:
    tuple path(mask), path(coefficients), path(reference_period), path('disturbances*.tif')
    
    script:
    """
    disturbance_detection...
    """
}

process update_mask {
    label 'disturbances'

    //mask(year), coef(year), ref_per(year), crem_folder (which is a known location?)
    input:
    tuple path(mask), path(coefficients), path(reference_period), path(crem_folder)

    //mask(year), coef(year), ref_per(year), disturbances(year)
    output:
    tuple path(mask), path(coefficients), path(reference_period), path('disturbances*.tif')
    
    script:
    """
    update_mask...
    """
}