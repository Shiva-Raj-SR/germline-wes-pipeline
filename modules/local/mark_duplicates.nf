process MARK_DUPLICATES {
    tag "${sample_id}"

    cpus 2
    memory '4 GB'

    conda "${System.getenv('HOME')}/miniconda3/envs/germline-wes"

    input:
    tuple val(sample_id), path(bam), path(bai)

    output:
    tuple val(sample_id),
          path("${sample_id}.markdup.bam"),
          path("${sample_id}.markdup.bam.bai"),
          emit: bam

    tuple val(sample_id),
          path("${sample_id}.markdup.metrics.txt"),
          emit: metrics

    script:
    """
    set -euo pipefail
    export JAVA_TOOL_OPTIONS="-Xmx2g"

    picard MarkDuplicates \
        INPUT=${bam} \
        OUTPUT=${sample_id}.markdup.bam \
        METRICS_FILE=${sample_id}.markdup.metrics.txt \
        CREATE_INDEX=true \
        REMOVE_DUPLICATES=false \
        DUPLICATE_SCORING_STRATEGY=SUM_OF_BASE_QUALITIES \
        VALIDATION_STRINGENCY=STRICT \
        MAX_SEQUENCES_FOR_DISK_READ_ENDS_MAP=50000 \
        MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=8000 \
        SORTING_COLLECTION_SIZE_RATIO=0.25 \
        COMPRESSION_LEVEL=2 \
        TMP_DIR=.

    samtools quickcheck -v ${sample_id}.markdup.bam

    if [[ -s ${sample_id}.markdup.bai ]]; then
        mv ${sample_id}.markdup.bai ${sample_id}.markdup.bam.bai
    fi

    test -s ${sample_id}.markdup.bam.bai
    """

    stub:
    """
    touch ${sample_id}.markdup.bam
    touch ${sample_id}.markdup.bam.bai
    touch ${sample_id}.markdup.metrics.txt
    """
}
