
process DORADO_BASECALL { 

    publishDir "$params.outdir/$params.dorado_fastq_out", mode: 'copy'

    label 'SuperHeavy'

    output:
    path("calls.bam"), emit: bam

    script:
    """
    $params.dorado basecaller \
    $params.dorado_model \
    $params.pod5_dir \
    --kit-name $params.dorado_kitname \
    --no-trim \
    --batchsize $params.dorado_batchsize \
     > calls.bam
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
    --kit-name $params.dorado_kitname \
    --threads $task.cpus \
    --emit-fastq \
    $bam
    """

}