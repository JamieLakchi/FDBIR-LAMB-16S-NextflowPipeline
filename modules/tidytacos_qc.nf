
process TIDYTACOS_QC_CREATOR { 
    errorStrategy 'ignore'
    tag "${task.index}"
    publishDir "$params.outdir/$params.tidytacos_qcdir", mode: 'copy'

    input:
    path taxons
    path distributions
    val tt_objname

    output:
    path("${tt_objname}+tmp${task.index}"), emit: tt_obj, optional: true

    script:
    """
    export R_LIBS_USER=$params.r_site_libraries
    mkdir -p \$R_LIBS_USER
    R --slave --no-restore -f $params.scripts_dir/tidytacos_qc_creator.R --args $taxons $distributions "${tt_objname}+tmp${task.index}" || {
        REALPATH=\$(realpath "${distributions}")
        echo "Object creation for tidytacos library failed (possibly because emu tool created an empty counts matrix)" 1>&2
        echo "check \${REALPATH}" 1>&2
        exit 1
    }
    """
}

process TIDYTACOS_QC_COMBINATOR { 
    publishDir "$params.outdir/$params.tidytacos_qcdir", mode: 'copy'

    input:
    path ttobj_list
    val tt_objname

    output:
    path("$tt_objname"), emit: final_taco, optional: true

    script:
    """
    export R_LIBS_USER=$params.r_site_libraries
    mkdir -p \$R_LIBS_USER
    R --slave --no-restore -f $params.scripts_dir/tidytacos_qc_combinator.R --args ${ttobj_list.join(' ')} $tt_objname
    """
}