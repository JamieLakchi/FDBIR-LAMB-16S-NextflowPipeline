
process EMU_CHECKDB {
    output:
    val true, emit: dbchecked

    script:
    """
    DB_DIR="${params.emu_dbdir}/${params.emu_dbname}"
    EMU_ON_NODBPRESENT="${params.emu_on_NoDBPresent}"

    DB_MISSING=false

    if [ ! -d "\$DB_DIR" ]; then
        echo "Directory '\$DB_DIR' does not exist"
        DB_MISSING=true
    fi

    if [ "\$DB_MISSING" = false ]; then
        TSV_COUNT=\$(find "\$DB_DIR" -maxdepth 1 -name "*.tsv" -type f | wc -l)
        FASTA_COUNT=\$(find "\$DB_DIR" -maxdepth 1 -name "*.fasta" -type f | wc -l)
        if [ \$TSV_COUNT -eq 0 ] || [ \$FASTA_COUNT -eq 0 ] || [ -z "\$(ls -A "\$DB_DIR" 2>/dev/null)" ]; then
            DB_MISSING=true
        fi
    fi


    if [ "\$DB_MISSING" = true ]; then
        if [ "\$EMU_ON_NODBPRESENT" = "auto" ]; then
            echo "Database missing but emu_on_NoDBPresent is set to auto - creating db"

            python $params.scripts_dir/gtdb_auxilary_helpers.py\
            --fasta_fetch $params.emu_gtdblink/$params.emu_gtdb_fnapath\
            --fasta_name f.fasta\
            --map_name m.map\
            --tsv_name t.tsv

            emu build-database $params.emu_dbname --sequences f.fasta --seq2tax m.map --taxonomy-list t.tsv

            mkdir -p \$DB_DIR

            mv $params.emu_dbname $params.emu_dbdir
        else
            echo "No database found at \$DB_DIR" 1>&2
            exit 1
        fi
    fi
    """
}


process EMU_ABUNDANCE { 
    
    publishDir "$params.outdir/$params.emu_dir", mode: 'copy'
    
    label 'SuperHeavy'

    input:
    val check_result
    path fastq_file

    output:
    path("results/*abundance.tsv"), emit: taxons, optional: true
    path("results/*distributions.tsv"), emit: distributions, optional: true

    script:
    """
    emu abundance "$fastq_file" --db "$params.emu_dbdir/$params.emu_dbname" --keep-counts --keep-read-assignments --threads $params.emu_threadc
    """
}

process EMU_COMBINATOR {
    publishDir "$params.outdir/$params.emu_dir", mode: 'copy'

    input:
    path all_rels

    output:
    path("¨*.tsv") ,emit: combined_rels

    script:
    """
    emu combine-outputs $params.outdir/$params.emu_dir/results species
    """

}