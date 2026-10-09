process APPLY_BQSR {
    tag "${sample_id}"

    cpus 2
    memory '6 GB'

    conda "${System.getenv('HOME')}/miniconda3/envs/germline-wes"

    input:
    tuple val(sample_id), path(bam), path(bai), path(recal_table)
    path reference_bundle, arity: '3', stageAs: 'reference/*'

    output:
    tuple val(sample_id),
          path("${sample_id}.recal.bam"),
          path("${sample_id}.recal.bam.bai"),
          emit: bam

    script:
    def fasta = reference_bundle.find {
        it.name.endsWith('.fasta')
    }
    assert fasta != null : 'Reference FASTA not found'

    """
    set -euo pipefail

    gatk --java-options "-Xmx4g" ApplyBQSR \
        -R "${fasta}" \
        -I "${bam}" \
        --bqsr-recal-file "${recal_table}" \
        -O "${sample_id}.recal.bam"

    samtools quickcheck -v "${sample_id}.recal.bam"
    samtools index -@ ${task.cpus} "${sample_id}.recal.bam"

    test -s "${sample_id}.recal.bam.bai"
    """

    stub:
    """
    touch "${sample_id}.recal.bam"
    touch "${sample_id}.recal.bam.bai"
    """
}
