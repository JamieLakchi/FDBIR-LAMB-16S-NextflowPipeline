
process TIDYTACOS_CREATOR { 
    publishDir "$params.outdir/$params.tidytacos_outdir", mode: 'copy'

    input:
    val combineddir
    val tt_objname

    output:
    path("${tt_objname}"), emit: tt_obj, optional: true

    script:
    """
    export R_LIBS_USER=$params.r_site_libraries
    mkdir -p \$R_LIBS_USER
    R --slave --no-restore -f $params.scripts_dir/tidytacos_creator.R --args $combineddir/emu-combined-species.tsv $tt_objname
    """
}
