
process split_samples {
    label 'tree_mask'

    input:
    path('2_FORCE_samples/*') //to stage files conveniently

    output:
    path "3_train_test_data/"
    
    script:
    """
    3_split_to_2D_array.py --working_directory .
    """
}

process augment {
    label 'tree_mask'
    
    input:
    path train_test_data

    output:
    tuple path(train_test_data), path("4_augmented_data/")

    script:
    """
    4_data_augmentation.py --working_directory .
    """
}

process aggregate_weekly {
    label 'tree_mask'
    
    input:
    tuple path(train_test_data), path(augmented)

    output:
    tuple path(train_test_data), path(augmented), path("5_folded_data/")

    script:
    """
    5_weekly_folding.py --working_directory .
    """
}

process train {
    label 'tree_mask'
    
    input:
    tuple path(train_test_data), path(augmented), path(folded)

    output:
    tuple path(train_test_data), path(augmented), path(folded), path("6_trained_model/")

    script:
    """
    6_train_CNN.py --working_directory .
    """
}

process validation {
    label 'tree_mask'
    
    input:
    path(train_test_data), path(augmented), path(folded), path(models)

    publishDir "${params.publish}/${params.project}",
        mode: 'copy', overwrite: true, failOnError: true
    
    output:
    path "7_validation/confusion_matrix_report.txt"

    script:
    """
    7_validation.py --working_directory .
    """
}

process predict {
    label 'tree_mask'
    label 'multithread'
    maxForks 2

    input:
    tuple path(datacube), val(tile), path(models) // models for staging purposes

    publishDir "${params.publish}/${params.project}",
        mode: 'copy', overwrite: true, failOnError: true

    output:
    tuple val(tile), path("8_prediction/${tile}/")

    script:
    """
    9_DC_predict.py --working_directory . \
        --year ${params.forestMask.year} \
        --tile ${tile} \
        --name_list "${params.forestMask.name_list}" \
        --version 3
    """
}