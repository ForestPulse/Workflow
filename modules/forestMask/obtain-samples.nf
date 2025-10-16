include { force_parameter; force_higher_level; force_higher_level_chain } from '../common/force.nf'

workflow obtain_samples {

  take:
  datacube_tile

  main:
  refined_tile = datacube_tile.map{ cube, mask, tile, x, y, _ -> [cube, mask, tile, x, y] }
  //alternatively: refined_tile = datacube_tile.map{ [it[0], it[1], it[2], it[3]] }

  mask = force_parameter('SMP') // create parameter file
  | combine(refined_tile)// add parameter file to input tuple
  | combine(Channel.of('tree_mask')) //add product
  | fill_parameter_stats   // fill out the parameter file
  | force_higher_level_chain     // run higher level processing
  // note: 'Samples (SMP)' does not generate a data cube structure, just files

  emit:
  mask
  
}

// fill out the paramater file
// note: input file is copied to keep cache alive
process fill_parameter_stats {

  input:
  tuple path(parfile), path(datacube), path(maskdir), val(tile_ID), val(tile_X), val(tile_Y), val(product)

  output:
  tuple path("filled_${parfile}"), path(datacube), path(maskdir), val(tile_ID), val(tile_X), val(tile_Y), val(product)

// TODO: maybe a more sensible method for adding INPUT_FEATUREs
/* added special name to FILE_SAMPLE, FILE_RESPONSE and FILE_COORDINATES to make
   subsequent operations easier, as the repeated filenames can cause conflict
*/

  """
  cp "$parfile" "filled_${parfile}"
  maskfile="${params.forestMask.labels_file}"
  sed -i "/^DIR_LOWER /c\\DIR_LOWER = ${datacube}" "filled_${parfile}"
  sed -i "/^DIR_HIGHER /c\\DIR_HIGHER = ${product}" "filled_${parfile}"
  sed -i "/^DIR_PROVENANCE /c\\DIR_PROVENANCE = ${product}" "filled_${parfile}"
  sed -i "/^DIR_MASK /c\\DIR_MASK = ${maskdir}" "filled_${parfile}"
  sed -i "/^BASE_MASK /c\\BASE_MASK = \${maskfile%.*}.tif" "filled_${parfile}"
  #sed -i "/^NTHREAD_READ /c\\NTHREAD_READ = 1" "filled_${parfile}"
  sed -i "/^NTHREAD_COMPUTE /c\\NTHREAD_COMPUTE = ${params.max_cpu}" "filled_${parfile}"
  #sed -i "/^NTHREAD_WRITE /c\\NTHREAD_WRITE = 1" "filled_${parfile}"
  sed -i "/^X_TILE_RANGE /c\\X_TILE_RANGE = ${tile_X} ${tile_X}" "filled_${parfile}"
  sed -i "/^Y_TILE_RANGE /c\\Y_TILE_RANGE = ${tile_Y} ${tile_Y}" "filled_${parfile}"
  sed -i "/^CHUNK_SIZE /c\\CHUNK_SIZE = ${params.chunk_size} ${params.chunk_size}" "filled_${parfile}"
  sed -i "/^FEATURE_NODATA /c\\FEATURE_NODATA = 0" "filled_${parfile}"
  sed -i "/^FILE_POINTS /c\\FILE_POINTS = ${params.forestMask.file_points}" "filled_${parfile}"

  sed -i "/^FILE_SAMPLE /c\\FILE_SAMPLE = ${product}/${tile_X}_${tile_Y}_sample.txt" "filled_${parfile}"
  sed -i "/^FILE_RESPONSE /c\\FILE_RESPONSE = ${product}/${tile_X}_${tile_Y}_response.txt" "filled_${parfile}"
  sed -i "/^FILE_COORDINATES /c\\FILE_COORDINATES = ${product}/${tile_X}_${tile_Y}_coord.txt" "filled_${parfile}"
  
  sed -i "/^PROJECTED /c\\PROJECTED = TRUE" "filled_${parfile}"
  
  awk -v repl='${params.forestMask.input_feature}' '
    BEGIN {
      n = split(repl, newlines, "\\\\n")
      inserted = 0
    }
    /^INPUT_FEATURE / {
      if (!inserted) {
        for (i = 1; i <= n; i++) {
          line = newlines[i]
          sub(/^[ \t]+/, "", line)
          if (line != "") print line
        }
        inserted = 1
      }
      next
    }
    { print }
  ' "filled_${parfile}" > tmp && mv tmp "filled_${parfile}"
  """
}