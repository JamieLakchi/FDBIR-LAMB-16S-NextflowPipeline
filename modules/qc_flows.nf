process NANOPLOT_QC { 

    publishDir "$params.outdir/$outdir", mode: 'copy'
    
    input:
    val outdir
    path fastq_files

    output:
    path("*")

    script:
    """
    NanoPlot --fastq ${fastq_files.join(' ')} -o .
    """
}

workflow PREFILTERING_QC {
    take:
    fastq_channel
    
    main:
    NANOPLOT_QC(params.prefiltering_qcreport_outdir, fastq_channel.collect())
    
    emit:
    NANOPLOT_QC.out
}

workflow POSTFILTERING_QC {
    take:
    filtered_fastq_channel
    
    main:
    NANOPLOT_QC(params.postfiltering_qcreport_outdir, filtered_fastq_channel.collect())
    
    emit:
    NANOPLOT_QC.out
}