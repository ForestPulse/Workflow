// all names are currently placeholders and subject to change
// all functions could even be merged into one

process augment {
    input:
    path train

    output:
    path "train_augmented.npy"

    script:
    """
    python augment.py ${train}
    """
}

process aggregate_weekly {
    input:
    path file

    output:
    path "${file}_aggregated.npy"

    script:
    """
    python aggregate_weekly.py ${file}
    """
}

process train {
    input:
    path train_aggregated

    output:
    path "model.keras"

    script:
    """
    python train.py ${train_aggregated}
    """
}

process predict {
    input:
    path tile
    path model

    output:
    path "${tile}_predicted.tif"

    script:
    """
    python predict.py ${tile} ${model}
    """
}

process binarize {
    input:
    path tile

    //TODO: more sensible naming convention
    output:
    path "${tile}_binarized"

    script:
    """
    python binarize.py ${tile}
    """
}

process binary_tile_max{
    input:
    path legal_forest_mask
    path old_mask
    path predicted

    output:
    path "predicted.tif"

    script:
    """
    python tileMax.py ${legal_forest_mask} ${old_mask} ${predicted}
    """
}