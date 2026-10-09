nextflow.enable.dsl = 2

include { MARK_DUPLICATES } from '../modules/local/mark_duplicates'

workflow {
    if (!params.bam || !params.bai)
        error 'Specify --bam and --bai'

    MARK_DUPLICATES(
        Channel.of(
            tuple('TEST', file(params.bam), file(params.bai))
        )
    )

    MARK_DUPLICATES.out.bam.view { result ->
        "MARK_DUPLICATES OUTPUTS READY: ${result[0]}"
    }
}
