process HAPLOTYPE_CALLER {
    tag "${sample_id}"

    cpus 2
    memory '6 GB'

    conda "${System.getenv('HOME')}/miniconda3/envs/germline-wes"

    input:
    tuple val(sample_id), path(bam), path(bai)
    path reference_bundle, arity: '3', stageAs: 'reference/*'
    path intervals, name: 'calling.interval_list'

    output:
    tuple val(sample_id),
          path("${sample_id}.autosomes.g.vcf.gz"),
          path("${sample_id}.autosomes.g.vcf.gz.tbi"),
          emit: gvcf

    script:
    def fasta = reference_bundle.find {
        it.name.endsWith('.fasta')
    }

    assert fasta != null : 'Reference FASTA not found'

    """
    set -euo pipefail

    gatk --java-options "-Xmx4g" HaplotypeCaller \
        -R "${fasta}" \
        -I "${bam}" \
        -O "${sample_id}.autosomes.g.vcf.gz" \
        -ERC GVCF \
        -L "${intervals}" \
        -ip 100 \
        --native-pair-hmm-threads ${task.cpus}

    test -s "${sample_id}.autosomes.g.vcf.gz"
    test -s "${sample_id}.autosomes.g.vcf.gz.tbi"
    """

    stub:
    """
    touch "${sample_id}.autosomes.g.vcf.gz"
    touch "${sample_id}.autosomes.g.vcf.gz.tbi"
    """
}
