workflow spline_coefficients {
    take:
    DWD_data

    main:
    yearly_recollection = DWD_data | calculate_thermal_time

    tiles = yearly_recollection
    | combine(params.spline.tilelist)
    | warp_file_to_tiles

    spline_coefs = tiles | combine(params.aoi)
    | thermal_spline_coefs

    emit:
    spline_coefs
}

process calculate_thermal_time {
    label 'tree_species'

    input:
    path(DWD_data) 

    output:
    path "thermal_time/*" // assuming it returns a list of items, not a queue channel
    
    script:
    """
    1_calculate_thermal_time.py --working_directory .
    """

    stub:
    """
    mkdir -p thermal_time
    touch thermal_time/test.txt
    """
}

process warp_file_to_tiles {
    label 'tree_species'

    input:
    tuple path(thermal_time), path(tile_list) 

    output:
    path "thermal_time_tiles/*"
    
    script:
    """
    2_warp_file_to_tiles.sh --working_directory .
    """
}

process thermal_spline_coefs {
    label 'tree_species'

    input:
    tuple path(thermal_tiles), path(level2)

    output:
    path("coefficients/*")

    script:
    """
    thermal_spline_coefs.py?
    """
}