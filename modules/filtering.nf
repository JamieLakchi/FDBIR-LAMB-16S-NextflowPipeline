process FILTLONG_FILTER{

    publishDir "$params.outdir/$params.filtlong_dir", mode: 'copy'

    input:
    path fastq_file

    output:
    path("filtered_*.fastq"), emit: filtered, optional: true

    script:
    """
    $params.filtlong $fastq_file\
    --min_length 5\
    --max_length $params.fl_max_length\
    --min_mean_q $params.fl_min_mean_quality\
    --min_window_q $params.fl_min_window_quality\
    --window_size $params.fl_window_size\
    > temp_output.tmp

    if [ -s temp_output.tmp ]; then
        mv temp_output.tmp filtered_${fastq_file}
    else
        rm -f temp_output.tmp
    fi
    """
}

process CHOPPER_FILTER{

    publishDir "$params.outdir/$params.chopper_dir", mode: 'copy'

    input:
    path fastq_file

    output:
    path("filtered_*.fastq"), emit: filtered, optional: true

    script:
    """
    chopper \
    --input $fastq_file\
    --trim $params.chopper_cutoff\
    --threads $params.chopper_threadc\
    > temp_output.tmp

    if [ -s temp_output.tmp ]; then
        mv temp_output.tmp filtered_${fastq_file}
    else
        rm -f temp_output.tmp
    fi
    """
}