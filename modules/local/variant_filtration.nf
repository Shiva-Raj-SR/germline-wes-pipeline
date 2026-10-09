process FILTER_SNPS {
    tag "${sample_id}"

    cpus 1
    memory '6 GB'

    conda "${params.wes_conda_env}"

    input:
    tuple val(sample_id), path(vcf), path(vcf_index)
    path reference_bundle, arity: '3', stageAs: 'reference/*'

    output:
    tuple val(sample_id),
          path("${sample_id}.autosomes.snps.filtered.vcf.gz"),
          path("${sample_id}.autosomes.snps.filtered.vcf.gz.tbi"),
          emit: vcf

    script:
    def fasta = reference_bundle.find {
        it.name.endsWith('.fasta')
    }
    assert fasta != null : 'Reference FASTA not found'

    """
    set -euo pipefail

    gatk --java-options "-Xmx4g" VariantFiltration \
        -R "${fasta}" \
        -V "${vcf}" \
        -O "${sample_id}.autosomes.snps.filtered.vcf.gz" \
        --filter-expression 'QD < 2.0' \
        --filter-expression 'QUAL < 30.0' \
        --filter-expression 'FS > 60.0' \
        --filter-expression 'SOR > 3.0' \
        --filter-expression 'MQ < 40.0' \
        --filter-expression 'MQRankSum < -12.5' \
        --filter-expression 'ReadPosRankSum < -8.0' \
        --filter-name QD2 \
        --filter-name QUAL30 \
        --filter-name FS60 \
        --filter-name SOR3 \
        --filter-name MQ40 \
        --filter-name MQRankSum-12.5 \
        --filter-name ReadPosRankSum-8

    test -s "${sample_id}.autosomes.snps.filtered.vcf.gz"
    test -s "${sample_id}.autosomes.snps.filtered.vcf.gz.tbi"
    """

    stub:
    """
    touch "${sample_id}.autosomes.snps.filtered.vcf.gz"
    touch "${sample_id}.autosomes.snps.filtered.vcf.gz.tbi"
    """
}


process FILTER_INDELS {
    tag "${sample_id}"

    cpus 1
    memory '6 GB'

    conda "${params.wes_conda_env}"

    input:
    tuple val(sample_id), path(vcf), path(vcf_index)
    path reference_bundle, arity: '3', stageAs: 'reference/*'

    output:
    tuple val(sample_id),
          path("${sample_id}.autosomes.indels.filtered.vcf.gz"),
          path("${sample_id}.autosomes.indels.filtered.vcf.gz.tbi"),
          emit: vcf

    script:
    def fasta = reference_bundle.find {
        it.name.endsWith('.fasta')
    }
    assert fasta != null : 'Reference FASTA not found'

    """
    set -euo pipefail

    gatk --java-options "-Xmx4g" VariantFiltration \
        -R "${fasta}" \
        -V "${vcf}" \
        -O "${sample_id}.autosomes.indels.filtered.vcf.gz" \
        --filter-expression 'QD < 2.0' \
        --filter-expression 'QUAL < 30.0' \
        --filter-expression 'FS > 200.0' \
        --filter-expression 'SOR > 10.0' \
        --filter-expression 'ReadPosRankSum < -20.0' \
        --filter-name QD2 \
        --filter-name QUAL30 \
        --filter-name FS200 \
        --filter-name SOR10 \
        --filter-name ReadPosRankSum-20

    test -s "${sample_id}.autosomes.indels.filtered.vcf.gz"
    test -s "${sample_id}.autosomes.indels.filtered.vcf.gz.tbi"
    """

    stub:
    """
    touch "${sample_id}.autosomes.indels.filtered.vcf.gz"
    touch "${sample_id}.autosomes.indels.filtered.vcf.gz.tbi"
    """
}
