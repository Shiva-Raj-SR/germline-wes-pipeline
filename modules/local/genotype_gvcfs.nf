process GENOTYPE_GVCFS {
    tag "${sample_id}"

    cpus 1
    memory '6 GB'

    conda "${params.wes_conda_env}"

    input:
    tuple val(sample_id), path(gvcf), path(gvcf_index)
    path reference_bundle, arity: '3', stageAs: 'reference/*'
    path intervals, name: 'calling.interval_list'

    output:
    tuple val(sample_id),
          path("${sample_id}.autosomes.raw.vcf.gz"),
          path("${sample_id}.autosomes.raw.vcf.gz.tbi"),
          emit: vcf

    script:
    def fasta = reference_bundle.find {
        it.name.endsWith('.fasta')
    }

    assert fasta != null : 'Reference FASTA not found'

    """
    set -euo pipefail

    gatk --java-options "-Xmx4g" GenotypeGVCFs \
        -R "${fasta}" \
        -V "${gvcf}" \
        -L "${intervals}" \
        -O "${sample_id}.autosomes.raw.vcf.gz"

    test -s "${sample_id}.autosomes.raw.vcf.gz"
    test -s "${sample_id}.autosomes.raw.vcf.gz.tbi"
    """

    stub:
    """
    touch "${sample_id}.autosomes.raw.vcf.gz"
    touch "${sample_id}.autosomes.raw.vcf.gz.tbi"
    """
}
