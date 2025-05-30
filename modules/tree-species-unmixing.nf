
/*
    Nextflow adaptation of https://github.com/davidklehr/tree-species-unmixing/
    using ghcr.io/forestpulse/tree-species-unmixing:dev, already containing
    a copy of the repository
*/

workflow tree_species_unmixing {
    take:
    input_dummy

    main:
    step1_out = extract_pure(input_dummy)
    step2_out = synth_library(step1_out.out)
    step3_out = train_ANN(step2_out.out)
    step4_out = mapping(step3_out.out)

    emit:
    final_output = step4_out.out
}

// inputs: --dc_folder, --training_points, --year, --working_directory
// outputs: {workingdirectory}/1_pure/samples_n/n_#### , where n : {x, y}
process extract_pure {
    label 'tree-species'

    output:
    path 'step1_output.txt'

    script:
    """
    1_extract_pure.py > step1_output.txt
    """
}

// inputs: --working_directory, --year, --num_libs, --lib_size, --tree_index,
//         --mixture_list, --mixture_weights
// uses workingdirectory to retrieve the inputs from extract_pure
// output: {workingdirectory}/2_mixed_data3/version#/n_mixed_{year}.npy
// where n : {x, y}
process synth_library {
    label 'tree-species'

    input:
    path input_file

    output:
    path 'step2_output.txt'

    script:
    """
    2_synth_library > step2_output.txt
    """
}

// inputs: --working_directory, --num_models, --year, --tree_labels,
//         --num_hidden_layer, --hidden_layer_nodes, --learning_rate
//         --batch_size, --epochs
// uses workingdirectory to retriee the inputs from synth_library
// this is the one that uses tensorflow
// outputs: {workingdirectory}/3_trained_model_test/version#/performance.txt
//          {workingdirectory}/3_trained_model_test/version#/saved_model#.keras
process train_ANN {
    label 'tree-species'

    input:
    path input_file

    output:
    path 'step3_output.txt'

    script:
    """
    3_train_ANN > step3_output.txt
    """
}

//also uses tensorflow
// inputs: --dc_folder, --working_directory, --tree_class_list, --tree_labels,
//         --num_models, --year
// and the models from before (all # of them)
// outputs: {workingdirectory}/4_prediction_test/tile/fraction_{year}.tif
//          {workingdirectory}/4_prediction_test/tile/deviation_{year}.tif
//          {workingdirectory}/4_prediction_test/tile/classification_{year}.tif
// TO DO: modify so parallelization occurs here and not in python
process mapping {
    label 'tree-species'

    input:
    path input_file

    output:
    path 'step4_output.txt'

    script:
    """
    4_mapping > step4_output.txt
    """
}