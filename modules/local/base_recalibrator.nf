process BASE_RECALIBRATOR {
    tag "${sample_id}"

    cpus 1
    memory '6 GB'

    conda "${System.getenv('HOME')}/miniconda3/envs/germline-wes"

    input:
    tuple val(sample_id), path(bam), path(bai)
    path reference_bundle, arity: '3', stageAs: 'reference/*'
    path known_sites_bundle, arity: '6', stageAs: 'known_sites/*'

    output:
    tuple val(sample_id),
          path("${sample_id}.recal_data.table"),
          emit: table

    script:
    def fasta = reference_bundle.find {
        it.name.endsWith('.fasta')
    }
    def dbsnp = known_sites_bundle.find {
        it.name.endsWith('dbsnp138.vcf')
    }
    def indels = known_sites_bundle.find {
        it.name.endsWith('known_indels.vcf.gz')
    }
    def mills = known_sites_bundle.find {
        it.name.endsWith('Mills_and_1000G_gold_standard.indels.hg38.vcf.gz')
    }

    assert fasta && dbsnp && indels && mills :
        'Required BQSR resources are missing'

    """
    set -euo pipefail

    gatk --java-options "-Xmx4g" BaseRecalibrator \
        -R "${fasta}" \
        -I "${bam}" \
        --known-sites "${dbsnp}" \
        --known-sites "${indels}" \
        --known-sites "${mills}" \
        -O "${sample_id}.recal_data.table"

    test -s "${sample_id}.recal_data.table"
    """

    stub:
    """
    touch "${sample_id}.recal_data.table"
    """
}
