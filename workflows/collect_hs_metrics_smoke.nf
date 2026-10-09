nextflow.enable.dsl = 2

include { COLLECT_HS_METRICS } from '../modules/local/collect_hs_metrics'

workflow {
    if (!params.bam || !params.bai || !params.intervals || !params.ref_dir)
        error 'Specify --bam, --bai, --intervals and --ref_dir'

    def ref = [
        'Homo_sapiens_assembly38.fasta',
        'Homo_sapiens_assembly38.fasta.fai',
        'Homo_sapiens_assembly38.dict'
    ].collect { file("${params.ref_dir}/${it}") }

    COLLECT_HS_METRICS(
        Channel.of(tuple('TEST', file(params.bam), file(params.bai))),
        file(params.intervals),
        Channel.value(ref)
    )

    COLLECT_HS_METRICS.out.reports.view { result ->
        "COLLECT_HS_METRICS OUTPUTS READY: ${result[0]}"
    }
}
