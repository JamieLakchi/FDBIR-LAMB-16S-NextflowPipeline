
process TIDYTACOS_CREATOR { 
    publishDir "$params.outdir/$params.tidytacos_outdir", mode: 'copy'

    input:
    path combined_tsv
    val tt_objname

    output:
    path("${tt_objname}"), emit: tt_obj, optional: true

    script:
    """
    export R_LIBS_USER=$params.r_site_libraries
    mkdir -p \$R_LIBS_USER
    R --slave --no-restore -f $params.scripts_dir/tidytacos_creator.R --args $combined_tsv $tt_objname"
    """
}