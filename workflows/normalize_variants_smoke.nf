nextflow.enable.dsl = 2

include { NORMALIZE_VARIANTS } from '../modules/local/normalize_variants'

workflow {
    if (!params.vcf || !params.vcf_index || !params.ref_dir)
        error 'Specify --vcf, --vcf_index and --ref_dir'

    def refs = [
        'toy.fasta',
        'toy.fasta.fai',
        'toy.dict'
    ].collect { file("${params.ref_dir}/${it}") }

    NORMALIZE_VARIANTS(
        Channel.of(tuple(
            'TEST',
            file(params.vcf),
            file(params.vcf_index)
        )),
        Channel.value(refs)
    )

    NORMALIZE_VARIANTS.out.vcf.view { result ->
        "NORMALIZE_VARIANTS OUTPUTS READY: ${result[0]}"
    }
}
