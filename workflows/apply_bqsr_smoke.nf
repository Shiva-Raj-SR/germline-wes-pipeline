nextflow.enable.dsl = 2

include { APPLY_BQSR } from '../modules/local/apply_bqsr'

workflow {
    if (!params.test_dir)
        error 'Specify --test_dir'

    def dir = params.test_dir

    def refs = [
        'toy.fasta',
        'toy.fasta.fai',
        'toy.dict'
    ].collect { file("${dir}/${it}") }

    APPLY_BQSR(
        Channel.of(tuple(
            'TEST',
            file("${dir}/TEST.markdup.bam"),
            file("${dir}/TEST.markdup.bam.bai"),
            file("${dir}/TEST.recal_data.table")
        )),
        Channel.value(refs)
    )

    APPLY_BQSR.out.bam.view { result ->
        "APPLY_BQSR OUTPUTS READY: ${result[0]}"
    }
}
