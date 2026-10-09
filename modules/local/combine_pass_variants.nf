process COMBINE_PASS_VARIANTS {
    tag "${sample_id}"

    cpus 1
    memory '3 GB'

    conda "${params.wes_conda_env}"

    input:
    tuple val(sample_id),
          path(snp_vcf),
          path(snp_index),
          path(indel_vcf),
          path(indel_index)

    output:
    tuple val(sample_id),
          path("${sample_id}.autosomes.filtered.vcf.gz"),
          path("${sample_id}.autosomes.filtered.vcf.gz.tbi"),
          emit: filtered

    tuple val(sample_id),
          path("${sample_id}.autosomes.PASS.vcf.gz"),
          path("${sample_id}.autosomes.PASS.vcf.gz.tbi"),
          emit: pass

    script:
    """
    set -euo pipefail

    # Combine SNP and indel records, including failed variants.
    # Sort because the two inputs may cover overlapping positions.
    bcftools concat -a -Ou \
        "${snp_vcf}" \
        "${indel_vcf}" \
        | bcftools sort \
            -m 256M \
            -T ./bcftools_sort_tmp \
            -Oz \
            -o "${sample_id}.autosomes.filtered.vcf.gz"

    bcftools index --tbi \
        "${sample_id}.autosomes.filtered.vcf.gz"

    # Match the original HG002 PASS extraction methodology.
    bcftools view -f PASS -Oz \
        -o "${sample_id}.autosomes.PASS.vcf.gz" \
        "${sample_id}.autosomes.filtered.vcf.gz"

    bcftools index --tbi \
        "${sample_id}.autosomes.PASS.vcf.gz"

    test -s "${sample_id}.autosomes.filtered.vcf.gz"
    test -s "${sample_id}.autosomes.filtered.vcf.gz.tbi"
    test -s "${sample_id}.autosomes.PASS.vcf.gz"
    test -s "${sample_id}.autosomes.PASS.vcf.gz.tbi"
    """

    stub:
    """
    touch "${sample_id}.autosomes.filtered.vcf.gz"
    touch "${sample_id}.autosomes.filtered.vcf.gz.tbi"
    touch "${sample_id}.autosomes.PASS.vcf.gz"
    touch "${sample_id}.autosomes.PASS.vcf.gz.tbi"
    """
}
