#!/usr/bin/env nextflow
nextflow.enable.dsl=2
nextflow.preview.recursion=true

include { force_parameter } from '../common/force.nf'
include { disturbances_iteration } from "./disturbance-iteration.nf"

// iterating over an aoi for a certain amount of years
// for a single year, we can just run disturbances_iteration over all tiles
workflow {

    aoi = channel.fromPath(params.aoi)
    datacube = channel.fromPath(params.datacube)
    datacube_definition = channel.fromPath( params.datacube + '/datacube-definition.prj' )

    tiles = channel.of("Tile_1_1", "Tile_2_2", "Tile_3_3") 
    //tiles = force_get_tiles(aoi, datacube_definition) | view | count | view
    initial_state = channel.of(params.start_year) | combine(tiles) | makeFile //| collect  
    //initial_state.view {"INITIALSTATE ${it}"}
    //state = initial_state.first()
    //println initial_state.getClass()
    //println state.getClass()

    //This would work without queue channels, i.e. if there was a value instead
    //need to use method (".") notation instead of pipes ("|")
    //final_states = disturbances_iteration.recurse(initial_state).until { it -> it[0] >= params.end_year }
    //final_states.view() // IT ITERATES.
    
    final_states = yearly_step(params.start_year, initial_state)
    final_states | toList | view
}

process makeFile {
    input:
    tuple val(year), val(tile)

    output:
    tuple val(next_year), val(tile), path('mask*.txt'), path('ref_fake.txt'), path('dis_fake.txt')

    script:
    next_year = year + 1
    """
    echo "in the loop for ${year}, mask for ${year-1} - ${tile}" > mask${year-1}.txt
    echo "this is just a dummy reference_prev file" > ref_fake.txt
    echo "this is just a dummy dist_file" > dis_fake.txt
    """
}

// Maybe use this for sets of tiles that aren`t that big?
workflow yearly_step {
    take:
    year
    state

    main:

    clean_state = state.map { _y, tile, mask, ref, dist -> tuple(tile, mask, ref, dist)}
    //disturbances_iteration is a workflow that receives a tuple and then returns the next status of it.
    current = channel.of(year).combine(clean_state) | disturbances_iteration  //| view

    next_year = year + 1
    if (next_year <= params.end_year) {
        future = yearly_step(next_year, current)
        result = current.mix(future)
    } else {
        result = current
    }

    emit:
    result
}