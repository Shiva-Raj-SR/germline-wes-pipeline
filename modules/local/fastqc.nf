process FASTQC {
    tag "${sample_id}"

    cpus 2
    memory '2 GB'

    conda "${params.wes_conda_env}"

    input:
    tuple val(sample_id), path(reads, arity: '2')

    output:
    tuple val(sample_id),
          path("*_fastqc.zip"),
          path("*_fastqc.html"),
          emit: reports

    script:
    """
    fastqc --threads ${task.cpus} \
        --outdir . \
        ${reads.join(' ')}
    """

    stub:
    """
    touch ${sample_id}_R1_fastqc.zip
    touch ${sample_id}_R2_fastqc.zip
    touch ${sample_id}_R1_fastqc.html
    touch ${sample_id}_R2_fastqc.html
    """
}
