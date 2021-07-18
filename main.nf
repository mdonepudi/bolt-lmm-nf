#!/usr/bin/env nextflow

def helpMessage() {
    log.info """
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run main.nf --bams sample.bam [Options]
    
    Inputs Options:
    --input         Input file

    Resource Options:
    --max_cpus      Maximum number of CPUs (int)
                    (default: $params.max_cpus)  
    --max_memory    Maximum memory (memory unit)
                    (default: $params.max_memory)
    --max_time      Maximum time (time unit)
                    (default: $params.max_time)
    See here for more info: https://github.com/lifebit-ai/hla/blob/master/docs/usage.md
    """.stripIndent()
}

// Show help message
if (params.help) {
  helpMessage()
  exit 0
}

// Define channels from repository files
projectDir = workflow.projectDir
ch_run_sh_script = Channel.fromPath("${projectDir}/bin/run.sh")

// Define Process
process bolt_lmm {
    tag "$sample_name"
    label 'low_memory'
    publishDir "${params.outdir}", mode: 'copy'

    input:
    file(run_sh_script) from ch_run_sh_script
    
    output:
    file "/BOLT-LMM_v2.3.5/example/example.stats" into ch_out

    script:
    """
    run.sh
    """
  }

process report {
    publishDir "${params.outdir}/MultiQC", mode: 'copy'

    input:
    file (table) from ch_out
    
    output:
    file "bolt_lmm_report.html" into ch_bolt_lmm_report

    script:
    """
    cp -r ${params.report_dir}/* .
    Rscript -e "rmarkdown::render('report.Rmd',params = list(res_table='$table'))"
    mv report.html bolt_lmm_report.html
    """
}
