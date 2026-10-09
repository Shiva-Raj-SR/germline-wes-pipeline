nextflow.enable.dsl = 2

include { HAPLOTYPE_CALLER } from '../modules/local/haplotype_caller'

workflow {
    if (!params.bam || !params.bai ||
        !params.ref_dir || !params.intervals)
        error 'Specify --bam, --bai, --ref_dir and --intervals'

    def refs = [
        'toy.fasta',
        'toy.fasta.fai',
        'toy.dict'
    ].collect { file("${params.ref_dir}/${it}") }

    HAPLOTYPE_CALLER(
        Channel.of(tuple(
            'TEST',
            file(params.bam),
            file(params.bai)
        )),
        Channel.value(refs),
        file(params.intervals)
    )

    HAPLOTYPE_CALLER.out.gvcf.view { result ->
        "HAPLOTYPE_CALLER OUTPUTS READY: ${result[0]}"
    }
}
