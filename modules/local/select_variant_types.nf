process SELECT_VARIANT_TYPES {
    tag "${sample_id}"

    cpus 1
    memory '6 GB'

    conda "${params.wes_conda_env}"

    input:
    tuple val(sample_id), path(norm_vcf), path(norm_index)
    path reference_bundle, arity: '3', stageAs: 'reference/*'

    output:
    tuple val(sample_id),
          path("${sample_id}.autosomes.snps.vcf.gz"),
          path("${sample_id}.autosomes.snps.vcf.gz.tbi"),
          emit: snps

    tuple val(sample_id),
          path("${sample_id}.autosomes.indels.vcf.gz"),
          path("${sample_id}.autosomes.indels.vcf.gz.tbi"),
          emit: indels

    script:
    def fasta = reference_bundle.find {
        it.name.endsWith('.fasta')
    }

    assert fasta != null : 'Reference FASTA not found'

    """
    set -euo pipefail

    gatk --java-options "-Xmx4g" SelectVariants \
        -R "${fasta}" \
        -V "${norm_vcf}" \
        --select-type-to-include SNP \
        -O "${sample_id}.autosomes.snps.vcf.gz"

    gatk --java-options "-Xmx4g" SelectVariants \
        -R "${fasta}" \
        -V "${norm_vcf}" \
        --select-type-to-include INDEL \
        -O "${sample_id}.autosomes.indels.vcf.gz"

    test -s "${sample_id}.autosomes.snps.vcf.gz"
    test -s "${sample_id}.autosomes.snps.vcf.gz.tbi"

    test -s "${sample_id}.autosomes.indels.vcf.gz"
    test -s "${sample_id}.autosomes.indels.vcf.gz.tbi"
    """

    stub:
    """
    touch "${sample_id}.autosomes.snps.vcf.gz"
    touch "${sample_id}.autosomes.snps.vcf.gz.tbi"
    touch "${sample_id}.autosomes.indels.vcf.gz"
    touch "${sample_id}.autosomes.indels.vcf.gz.tbi"
    """
}
