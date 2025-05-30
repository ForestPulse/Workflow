
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

process extract_pure {
    label 'tree-species'

    output:
    path 'step1_output.txt'

    script:
    """
    1_extract_pure.py > step1_output.txt
    """
}

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