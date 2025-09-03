include { force_parameter; force_higher_level; force_higher_level_chain } from '../common/force.nf'

workflow fold_TSA_labels {

  take:
  datacube_tile
  // datacube_tile:: tuple [path datacube, path masks, tile ID, tile ID (X), tile ID (Y)]

  main:
  labels = force_parameter('TSA') // create parameter file
  | combine(datacube_tile) // add parameter file to input tuple
  | combine(Channel.of('fold_labels'))
  | fill_parameter_labels  // fill out the parameter file
  | force_higher_level_chain     // run higher level processing

/*
  labels
  | force_finish // compute pyramids and mosaic
*/

  emit:
  labels

}

// fill out the paramater file
// note: input file is copied to keep cache alive
process fill_parameter_labels {

  input:
  tuple path(parfile), path(datacube), path(maskdir), val(tile_ID), val(tile_X), val(tile_Y), val(product)

  output:
  tuple path("filled_${parfile}"), path(datacube), path(maskdir), val(tile_ID), val(tile_X), val(tile_Y), val(product)

  """
  cp "$parfile" "filled_${parfile}"
  maskfile="${params.forestMask.labels_file}"
  sed -i "/^DIR_LOWER /c\\DIR_LOWER = ${datacube}" "filled_${parfile}"
  sed -i "/^DIR_HIGHER /c\\DIR_HIGHER = ." "filled_${parfile}"
  sed -i "/^DIR_HIGHER /c\\DIR_HIGHER = ${product}" "filled_${parfile}"
  sed -i "/^DIR_PROVENANCE /c\\DIR_PROVENANCE = ${product}" "filled_${parfile}"
  sed -i "/^DIR_MASK /c\\DIR_MASK = ${maskdir}" "filled_${parfile}"
  sed -i "/^BASE_MASK /c\\BASE_MASK = \${maskfile%.*}.tif" "filled_${parfile}"
  #sed -i "/^NTHREAD_READ /c\\NTHREAD_READ = 1" "filled_${parfile}"
  sed -i "/^NTHREAD_COMPUTE /c\\NTHREAD_COMPUTE = ${params.max_cpu}" "filled_${parfile}"
  #sed -i "/^NTHREAD_WRITE /c\\NTHREAD_WRITE = 1" "filled_${parfile}"
  sed -i "/^X_TILE_RANGE /c\\X_TILE_RANGE = ${tile_X} ${tile_X}" "filled_${parfile}"
  sed -i "/^Y_TILE_RANGE /c\\Y_TILE_RANGE = ${tile_Y} ${tile_Y}" "filled_${parfile}"
  sed -i "/^RESOLUTION /c\\RESOLUTION = ${params.resolution}" "filled_${parfile}"
  sed -i "/^SENSORS /c\\SENSORS = ${params.sensors}" "filled_${parfile}"
  sed -i "/^ABOVE_NOISE /c\\ABOVE_NOISE = 3" "filled_${parfile}"
  sed -i "/^BELOW_NOISE /c\\BELOW_NOISE = 0" "filled_${parfile}"
  sed -i "/^DATE_RANGE /c\\DATE_RANGE = ${params.forestMask.reference_start}-01-01 ${params.forestMask.reference_end}-12-31" "filled_${parfile}"
  sed -i "/^DOY_RANGE /c\\DOY_RANGE = ${params.forestMask.season_start} ${params.forestMask.season_end}" "filled_${parfile}"
  sed -i "/^INDEX /c\\INDEX = ${params.forestMask.index}" "filled_${parfile}"
  sed -i "/^OUTPUT_FBD /c\\OUTPUT_FBD = TRUE" "filled_${parfile}"
  """

}