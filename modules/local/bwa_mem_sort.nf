process BWA_MEM_SORT {
    tag "${sample_id}"

    cpus 4
    memory '7 GB'

    conda "${params.wes_conda_env}"

    input:
    tuple val(sample_id), path(reads, arity: '2'), val(read_group)
    path reference_bundle, arity: '7', stageAs: 'reference/*'

    output:
    tuple val(sample_id),
          path("${sample_id}.sorted.bam"),
          path("${sample_id}.sorted.bam.bai"),
          emit: bam

    script:
    def fasta = reference_bundle.find { it.name.endsWith('.fasta') }
    assert fasta != null : 'Reference FASTA not found'

    """
    set -euo pipefail

    bwa mem -t 2 \
        -R '${read_group}' \
        '${fasta}' \
        '${reads[0]}' \
        '${reads[1]}' \
        2> ${sample_id}.bwa.log \
    | samtools sort \
        -@ 1 \
        -m 256M \
        -T ${sample_id}.sort.tmp \
        -o ${sample_id}.sorted.bam \
        - \
        2> ${sample_id}.sort.log

    samtools quickcheck -v ${sample_id}.sorted.bam
    samtools index -@ 2 ${sample_id}.sorted.bam
    """

    stub:
    """
    touch ${sample_id}.sorted.bam
    touch ${sample_id}.sorted.bam.bai
    """
}
