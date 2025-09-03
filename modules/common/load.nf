
process checkAndCopyFile {
    input:
    path inputFile

    output:
    path outputFile

    script:
    """
    # Check if the file can be read with ogrinfo
    ogrinfo -so \$inputFile > /dev/null 2>&1

    # Check the exit status of ogrinfo
    if [[ \$? -ne 0 ]]; then
        # ogrinfo failed, copy file to the working directory
        cp \$inputFile ./
        outputFile=\$(basename \$inputFile)  # Get the filename (just the base name)
    else
        # ogrinfo succeeded, return the original file
        outputFile=\$inputFile
    fi

    # Output the result
    echo \$outputFile
    """
}