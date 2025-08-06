include { DORADO_BASECALL} from './modules/basecall_demultiplex.nf'
include { DORADO_DEMULTIPLEX} from './modules/basecall_demultiplex.nf'
include { PREFILTERING_QC } from './modules/qc_flows.nf'
include { POSTFILTERING_QC } from './modules/qc_flows.nf'
include { FILTLONG_FILTER } from './modules/filtering.nf'
include { CHOPPER_FILTER } from './modules/filtering.nf'
include { EMU_ABUNDANCE } from './modules/emu_abundance.nf'
include { EMU_CHECKDB } from './modules/emu_abundance.nf'
include { TIDYTACOS_CREATOR } from './modules/tidytacos_conversion.nf'
include { TIDYTACOS_COMBINATOR } from './modules/tidytacos_conversion.nf'

workflow {
    // dorado batch analyse pod5 files
    DORADO_BASECALL()
    fastq = DORADO_DEMULTIPLEX(DORADO_BASECALL.out.bam)

    // nanoplot as quality control (before filtering)
    PREFILTERING_QC(fastq.fastq)

    // use filtlong and chopper to remove any undesirable reads
    filtlong_filtered_fastq = FILTLONG_FILTER(fastq.fastq.flatten())
    chopper_filtered_fastq = CHOPPER_FILTER(filtlong_filtered_fastq.filtered)

    // nanoplot as quality control (for comparison with pre)
    POSTFILTERING_QC(chopper_filtered_fastq.filtered)

    // first check if a db exists at given dir
    dbch = EMU_CHECKDB()
    // relative abundance estimation with emudb
    estimation_tsv = EMU_ABUNDANCE(dbch.dbchecked, chopper_filtered_fastq.filtered)

    // conversion to tidytacos object with R
    tt_obj = TIDYTACOS_CREATOR(estimation_tsv.taxons, estimation_tsv.distributions, params.tt_objname)
    TIDYTACOS_COMBINATOR(tt_obj.collect(), params.tt_objname)
}