params.reads = 'reads/*.fastq.gz'
params.output_dir = 'output_dir'

process NANOQC {
    tag "$meta"
    publishDir "${params.output_dir}", mode:'copy'
        
    input:
    tuple val(meta), path(reads)

    output:
    path("${meta}"),                                         emit: nanoqc_dir_ch
    tuple val(meta), path("${meta}/*.html")                , emit: html_ch
    path  "versions.yml"                                   , emit: versions_ch

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    """
    mkdir $meta
    nanoQC $reads -o $params.output_dir
    
    mv $params.output_dir/*.html ${meta}/
		
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoQC: \$(echo \$(nanoQC --version 2>&1) | sed 's/^.*NanoPlot //; s/ .*\$//')
    END_VERSIONS
    """
}

// NANOQC MultiQC
process NANOQC_MULTIQC {
  tag { 'multiqc for nanoqc' }
  memory { 4.GB * task.attempt }

  publishDir "${params.output_dir}/quality_reports",
    mode: 'copy',
    pattern: "multiqc_report.html",
    saveAs: { "nanoqc_multiqc_report.html" }

  input:
  path(nanoqc_files) 

  output:
  path("multiqc_report.html")

  script:
  """
  multiqc --interactive .
  """
}

workflow {
         reads_ch = channel
                          .fromPath( params.reads, checkIfExists: true )
                          .map { file -> tuple(file.simpleName, file) }
			  
	 NANOQC(reads_ch)
	 
	 NANOQC_MULTIQC(NANOQC.out.nanoqc_dir_ch.collect())
}
