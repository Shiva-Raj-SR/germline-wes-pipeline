process NORMALIZE_VARIANTS {
    tag "${sample_id}"

    cpus 1
    memory '3 GB'

    conda "${params.wes_conda_env}"

    input:
    tuple val(sample_id), path(raw_vcf), path(raw_index)
    path reference_bundle, arity: '3', stageAs: 'reference/*'

    output:
    tuple val(sample_id),
          path("${sample_id}.autosomes.norm.vcf.gz"),
          path("${sample_id}.autosomes.norm.vcf.gz.tbi"),
          emit: vcf

    script:
    def fasta = reference_bundle.find {
        it.name.endsWith('.fasta')
    }

    assert fasta != null : 'Reference FASTA not found'

    """
    set -euo pipefail

    bcftools norm \
        -f "${fasta}" \
        -m -any \
        -Oz \
        -o "${sample_id}.autosomes.norm.vcf.gz" \
        "${raw_vcf}"

    bcftools index --tbi \
        "${sample_id}.autosomes.norm.vcf.gz"

    test -s "${sample_id}.autosomes.norm.vcf.gz"
    test -s "${sample_id}.autosomes.norm.vcf.gz.tbi"
    """

    stub:
    """
    touch "${sample_id}.autosomes.norm.vcf.gz"
    touch "${sample_id}.autosomes.norm.vcf.gz.tbi"
    """
}
