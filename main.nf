include { DORADO_BASECALL} from './modules/basecall_demultiplex.nf'
include { DORADO_DEMULTIPLEX} from './modules/basecall_demultiplex.nf'
include { PREFILTERING_QC } from './modules/qc_flows.nf'
include { POSTFILTERING_QC } from './modules/qc_flows.nf'
include { FILTLONG_FILTER } from './modules/filtering.nf'
include { CHOPPER_FILTER } from './modules/filtering.nf'
include { EMU_ABUNDANCE } from './modules/emu_abundance.nf'
include { EMU_COMBINATOR } from './modules/emu_abundance.nf'
include { EMU_CHECKDB } from './modules/emu_abundance.nf'
include { TIDYTACOS_CREATOR } from './modules/tidytacos_conversion.nf'
include { TIDYTACOS_QC_CREATOR } from './modules/tidytacos_qc.nf'
include { TIDYTACOS_QC_COMBINATOR } from './modules/tidytacos_qc.nf'
include { NAIVEANALYSIS } from './modules/tidytacos_qc.nf'


workflow {
    def start_point = params.from_tidytacos ? "tidytacos" :
                    params.from_tsv ? "tsv" :
                    params.from_clean_fastq ? "clean_fastq" :
                    params.from_fastq ? "fastq" :
                    "pod5"

    pod5_ch = params.from_pod5 && start_point == "pod5" ? 
            Channel.fromPath(params.from_pod5.tokenize(' ')) : 
            Channel.empty()
              
    fastq_ch = params.from_fastq && start_point == "fastq" ? 
               Channel.fromPath("${params.from_fastq}/*.fastq") : 
               Channel.empty()
               
    clean_fastq_ch = params.from_clean_fastq && start_point == "clean_fastq" ? 
                     Channel.fromPath("${params.from_clean_fastq}/*.fastq") : 
                     Channel.empty()

    tsv_ch = params.from_tsv && start_point == "tsv" ?
             Channel.fromPath("${params.from_tsv}", type: 'dir') : 
             Channel.empty()

    taxons_tsv_ch = params.from_tsv && start_point == "tsv" ?
                    Channel.fromPath("${params.from_tsv}/*abundance.tsv") : 
                    Channel.empty()

    distributions_tsv_ch = params.from_tsv && start_point == "tsv" ?
                           Channel.fromPath("${params.from_tsv}/*distributions.tsv") : 
                           Channel.empty()
        
                     
    tidytacos_ch = params.from_tidytacos && start_point == "tidytacos" ? 
                   Channel.fromPath("${params.from_tidytacos}/*", type: 'dir') : 
                   Channel.empty()

    // dorado batch analyse pod5 files
    bams = DORADO_BASECALL(pod5_ch)
    fastq = DORADO_DEMULTIPLEX(bams.bam)

    all_fastq = fastq.fastq.mix(fastq_ch)

    // nanoplot as quality control (before filtering)
    PREFILTERING_QC(all_fastq)

    // use filtlong and chopper to remove any undesirable reads
    filtlong_filtered_fastq = FILTLONG_FILTER(all_fastq.flatten())
    chopper_filtered_fastq = CHOPPER_FILTER(filtlong_filtered_fastq.filtered)
    
    all_clean_fastq = chopper_filtered_fastq.filtered.mix(clean_fastq_ch)

    // nanoplot as quality control (for comparison with pre)
    POSTFILTERING_QC(all_clean_fastq)

    // first check if a db exists at given dir
    dbch = EMU_CHECKDB()

    // relative abundance estimation with emudb
    estimation_tsv = EMU_ABUNDANCE(dbch.dbchecked, all_clean_fastq)
    
    all_taxons_tsv = estimation_tsv.taxons.mix(taxons_tsv_ch)
    all_distributions_tsv = estimation_tsv.distributions.mix(distributions_tsv_ch)

    combined_tsv = EMU_COMBINATOR(estimation_tsv.taxons.toList(), tsv_ch.toList())

    TIDYTACOS_CREATOR(combined_tsv.combineddir, params.tt_objname)
    NAIVEANALYSIS(all_taxons_tsv, all_distributions_tsv, params.tt_objname)

    ttqc_obj = TIDYTACOS_QC_CREATOR(all_taxons_tsv, all_distributions_tsv, params.tt_objname)

    all_ttqc_obj = ttqc_obj.mix(tidytacos_ch)
    TIDYTACOS_QC_COMBINATOR(all_ttqc_obj.collect(), params.tt_objname)
}
