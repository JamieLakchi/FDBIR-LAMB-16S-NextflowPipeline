# NEXTFLOW-NANOPORE-CONFIG(5)

## NAME
nextflow.config - Configuration file for Nextflow nanopore sequencing pipeline

## SYNOPSIS
```
(NanoporeNFEnv)$ nextflow run pipeline.nf -c nextflow.config
```

## DESCRIPTION
This configuration file defines parameters and settings for a Nextflow pipeline designed to process Oxford Nanopore sequencing data. The pipeline performs basecalling, quality filtering, and taxonomic classification of the 16S gene.

## EXECUTION ENVIRONMENT

### Conda
The pipeline requires the conda environment (from environment.yml) to already be active.
Use `conda activate NanoporeNFEnv` to activate the environment.

### Resource Allocation
Default executor settings are:
- **cpus**: 12 cores
- **memory**: 24 GB RAM
- **SuperHeavy processes**: 3 cores, 6 GB RAM

Can only be changed via .config file.

## PIPELINE ENTRY POINTS

The pipeline supports multiple starting points via the `from_*` parameters. The latest step with a non-empty path is automatically chosen as the starting point:

- **from_pod5**: Directory containing raw POD5 files from nanopore sequencing
- **from_fastq**: Directory containing FASTQ files (post-basecalling)
- **from_clean_fastq**: Directory containing quality- and length-filtered FASTQ files
- **from_tsv**: Directory for combining taxonomic classification outputs
- **from_tidytacos**: Directory containing tidytacos-formatted taxonomic data

Nextflow itself has a resume flag as well so if the pipeline fails it's better to use that flag post-fix.

## PROCESS LIST
- DORADO_BASECALL (<- from_pod5)
- DORADO_DEMULTIPLEX
- PREFILTERING_QC (<- from_fastq)
- FILTLONG_FILTER
- CHOPPER_FILTER
- POSTFILTERING_QC (<- from_clean_fastq)
- EMU_CHECKDB
- EMU_ABUNDANCE
- EMU_COMBINATOR (<- from_tsv)
- TIDYTACOS_CREATOR
- NAIVEANALYSIS
- TIDYTACOS_QC_CREATOR
- TIDYTACOS_QC_COMBINATOR (<- from_tidytacos)

## GENERAL PARAMETERS

- **scripts_dir**: Path to pipeline scripts directory

## BASECALLING (DORADO)

Oxford Nanopore's Dorado basecaller configuration:

- **dorado**: Path to Dorado binary executable
- **dorado_model**: Path to basecalling model directory
- **dorado_kitname**: Sequencing kit identifier
- **dorado_batchsize**: Processing batch size

## QUALITY FILTERING

### Filtlong Parameters
Length and quality-based filtering using Filtlong:

- **filtlong**: Path to Filtlong binary
- **fl_min_length**: Minimum sequence length
- **fl_max_length**: Maximum sequence length
- **fl_min_mean_quality**: Minimum mean base quality score
- **fl_min_window_quality**: Minimum window quality score
- **fl_window_size**: Quality assessment window size

### Chopper Parameters
End-trimming based on quality scores:

- **chopper_cutoff**: Minimum Q-score threshold for trimming
- **chopper_threadc**: Number of processing threads

## TAXONOMIC CLASSIFICATION (EMU)

EMU classifier configuration for 16S rRNA gene identification:

- **emu_dbdir**: Database directory path
- **emu_dbname**: Database name (GTDB_reps)
- **emu_threadc**: Processing thread count (10)
- **emu_gtdblink**: GTDB download URL (e.g. "https://data.ace.uq.edu.au/public/gtdb/data/releases/latest")
- **emu_gtdb_fnapath**: Relative path to 16S sequences in GTDB archive (e.g. "genomic_files_reps/bac120_ssu_reps.fna.gz")
- **emu_on_NoDBPresent**: Database handling behavior
  - `abort`: Terminate if database missing
  - `auto`: Automatically download and setup GTDB database

**Note**: The pipeline will never remove existing files or modify non-empty directories.

## R/TIDYTACOS ANALYSIS

R-based taxonomic analysis configuration:

- **r_site_libraries**: Path to R package library directory
- **tt_objname**: Object name for tidytacos data structure

## OUTPUT DIRECTORIES

All output paths are relative to the base output directory:

- **outdir**: Base output directory
- **dorado_fastq_out**: Basecalled FASTQ files
- **prefiltering_qcreport_outdir**: Pre-filtering QC reports
- **postfiltering_qcreport_outdir**: Post-filtering QC reports
- **filtlong_dir**: Filtlong-processed files
- **chopper_dir**: Chopper-processed files
- **emu_dir**: EMU classification results
- **tidytacos_qcdir**: Tidytacos QC outputs
- **tidytacos_outdir**: Final tidytacos objects

## DEPENDENCIES

- **Conda**: For environment management
- **Dorado**: Oxford Nanopore basecaller
- **Filtlong**: Sequence filtering tool
- **Chopper**: Quality trimming tool (via conda)
- **EMU**: Taxonomic classifier (via conda)
- **biopython's SeqIO**: fasta reading (via conda)
- **R with tidytacos**: For taxonomic data analysis

## PIPELINE FLOW
POD5 → Dorado (basecalling) → FASTQ → Filtlong/Chopper (filtering) → EMU (classification) → Tidytacos/R (analysis)
