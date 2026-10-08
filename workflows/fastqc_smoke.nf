nextflow.enable.dsl = 2

include { FASTQC } from '../modules/local/fastqc'

workflow {
    if (!params.r1 || !params.r2) {
        error 'Both --r1 and --r2 are required'
    }

    FASTQC(
        Channel.of(
            tuple('TEST', [file(params.r1), file(params.r2)])
        )
    )

    FASTQC.out.reports.view { result ->
        "FASTQC OUTPUTS READY: ${result[0]}"
    }
}
