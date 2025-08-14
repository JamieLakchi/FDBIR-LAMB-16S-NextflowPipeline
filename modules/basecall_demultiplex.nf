
process DORADO_BASECALL { 

    publishDir "$params.outdir/$params.dorado_fastq_out", mode: 'copy'

    label 'SuperHeavy'

    input:
    path(pod5dir)

    output:
    path("*_calls.bam"), emit: bam

    script:
    """
    FOLDERNAME=0
    if [[ -d $pod5dir ]]; then
        FOLDERNAME="\$(realpath $pod5dir | xargs basename)"
    elif [[ -f $pod5dir ]]; then
        FOLDERNAME="\$(realpath $pod5dir | xargs dirname | xargs basename)"
    else 
        echo "Given path does not exist: $pod5dir" 1>&2
        exit 1
    fi


    $params.dorado basecaller \
    "$params.dorado_model" \
    "$pod5dir" \
    --kit-name "$params.dorado_kitname" \
    --no-trim \
    --batchsize $params.dorado_batchsize \
     > "\${FOLDERNAME}_calls.bam"
    """

}

process DORADO_DEMULTIPLEX {

    publishDir "$params.outdir/$params.dorado_fastq_out", mode: 'copy'

    input: path(bam)

    output: path("*.fastq"), emit: fastq

    script:
    """
    $params.dorado demux \
    --output-dir . \
    --kit-name "$params.dorado_kitname" \
    --threads $task.cpus \
    --emit-fastq \
    "$bam"

    SUFFIX="_calls.bam"
    WORD="$bam"
    RUNNAME=\${WORD%"\$SUFFIX"}

    for fastq in ./*.fastq; do
        echo \$fastq
        BARCODE=\$(echo "\$fastq" | tr '_' '\n' | tail -n -1)
        mv "\$fastq" "\${RUNNAME}_\${BARCODE}"
    done
    """

}
