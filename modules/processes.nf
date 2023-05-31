process NANOQC {
    tag "$meta"
    publishDir "${params.output_dir}", mode:'copy'

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("${meta}/*.html")                , emit: html_ch
    path  "versions.yml"                                   , emit: versions_ch

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir $meta
    nanoQC $reads -o $params.output_dir

    mv $params.output_dir/*.html ${meta}/${meta}.nanoQC.html

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoQC: \$(echo \$(nanoQC --version 2>&1) | sed 's/^.*NanoPlot //; s/ .*\$//')
    END_VERSIONS
    """
}
