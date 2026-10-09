process COLLECT_HS_METRICS {
    tag "${sample_id}"

    cpus 1
    memory '3 GB'

    conda "${System.getenv('HOME')}/miniconda3/envs/germline-wes"

    input:
    tuple val(sample_id), path(bam), path(bai)
    path intervals, name: 'capture.interval_list'
    path reference_bundle, arity: '3', stageAs: 'reference/*'

    output:
    tuple val(sample_id),
          path("${sample_id}.hs_metrics.txt"),
          path("${sample_id}.per_target_coverage.txt"),
          emit: reports

    script:
    def fasta = reference_bundle.find { it.name.endsWith('.fasta') }
    assert fasta != null : 'Reference FASTA not found'

    """
    set -euo pipefail
    export JAVA_TOOL_OPTIONS="-Xmx2g"

    picard CollectHsMetrics \
        INPUT=${bam} \
        BAIT_INTERVALS=${intervals} \
        TARGET_INTERVALS=${intervals} \
        OUTPUT=${sample_id}.hs_metrics.txt \
        PER_TARGET_COVERAGE=${sample_id}.per_target_coverage.txt \
        REFERENCE_SEQUENCE=${fasta} \
        METRIC_ACCUMULATION_LEVEL=ALL_READS \
        NEAR_DISTANCE=250 \
        MINIMUM_MAPPING_QUALITY=20 \
        MINIMUM_BASE_QUALITY=20 \
        CLIP_OVERLAPPING_READS=true \
        INCLUDE_INDELS=false \
        COVERAGE_CAP=200 \
        SAMPLE_SIZE=10000 \
        ALLELE_FRACTION=0.001 \
        ALLELE_FRACTION=0.005 \
        ALLELE_FRACTION=0.01 \
        ALLELE_FRACTION=0.02 \
        ALLELE_FRACTION=0.05 \
        ALLELE_FRACTION=0.1 \
        ALLELE_FRACTION=0.2 \
        ALLELE_FRACTION=0.3 \
        ALLELE_FRACTION=0.5

    test -s ${sample_id}.hs_metrics.txt
    test -s ${sample_id}.per_target_coverage.txt
    """

    stub:
    """
    touch ${sample_id}.hs_metrics.txt
    touch ${sample_id}.per_target_coverage.txt
    """
}
