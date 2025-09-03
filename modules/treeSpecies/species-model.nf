//unlike tree-mask, we only require output from the "previous step"
//no need to carry over previous steps

process extract_pure {
    label 'tree_species'

    input:
    tuple path(datacube), path(training_points)

    output:
    path("1_pure/")
    
    script:
    """
    1_extract_pure.py --working_directory . \
        --dc_folder "${datacube}" \
        --training_points "${training_points}" \
        --year ${params.treeSpecies.year}
    """
}

process make_library {
    label 'tree_species'
    
    input:
    path(pure_samples)

    output:
    path("2_mixed_data/")

    script:
    """
    2_synth_library.py --working_directory . \
        --year ${params.treeSpecies.year} \
        --num_libs ${params.treeSpecies.num_libs} \
        --lib_size ${params.treeSpecies.lib_size} \
        --tree_index ${params.treeSpecies.tree_index} \
        --tree_class_weights ${params.treeSpecies.tree_class_weights} \
        --mixture_list ${params.treeSpecies.mixutre_list} \
        --mxiture_weights ${params.treeSpecies.mixture_weights}
    """
}

process train_ANN {
    label 'tree_species'
    
    input:
    path(mixed_data)

    output:
    path("3_trained_model/")

    script:
    """
    3_train_ANN.py --working_directory . \
        --num_models ${params.treeSpecies.num_models} \
        --year ${params.treeSpecies.year} \
        --tree_labels ${params.treeSpecies.tree_labels} \
        --num_hidden_layer ${params.treeSpecies.num_hidden_layer} \
        --hidden_layer_nodes ${params.treeSpecies.hidden_layer_nodes} \
        --learning_rate ${params.treeSpecies.learning_rate} \
        --batch_size ${params.treeSpecies.batch_size} \
        --epochs ${params.treeSpecies.epochs}
    """
}

process predict_species {
    label 'tree_species'
    
    input:
    tuple val(id), path(mixed_data), path(datacube)

    output:
    tuple val(id), path("4_prediction/")

    script:
    """
    4_mapping.py --working_directory . \
        --dc_folder "${datacube}" \
        --tree_class_list ${params.treeSpecies.tree_class_list} \
        --tree_labels ${params.treeSpecies.tree_labels} \
        --num_models ${params.treeSpecies.num_models} \
        --year ${params.treeSpecies.year} \
        --tile ${id}
    """
}

process normalization {
    label 'tree_species'
    
    input:
    tuple val(id), path(prediction), path(mask), path(disturbance_mask)

    output:
    path("5_prediction_normalized/")

    script:
    """
    5_normalize_fractions.py --working_directory . \
        --noisy_th ${params.treeSpecies.noisy_th} \
        --use_shadow_th ${params.treeSpecies.use_shadow_th} \
        --shadow_th ${params.treeSpecies.shadow_th} \
        --forest_mask_folder ${mask} \
        --forest_mask_name ${params.treeSpecies.forest_mask_name} \
        --use_disturbance_mask ${params.treeSpecies.use_disturbance_mask} \
        --disturbance_mask_folder ${disturbance_mask} \
        --disturbance_mask_name ${params.treeSpecies.disturbance_mask_name} \
        --tree_class_list ${params.treeSpecies.tree_class_list} \
        --tree_labels ${params.treeSpecies.tree_labels} \
        --num_models ${params.treeSpecies.num_models} \
        --year ${params.treeSpecies.year} \
        --tile ${id}
    """
}

process coloring {
    label 'tree_species'
    
    input:
    path(pred_norm)

    output:
    path("5_prediction_normalized/")

    script:
    """
    6_coloring.py --working_directory . \
        --tree_labels ${params.treeSpecies.tree_labels}
        --tile ${id}
    """
}