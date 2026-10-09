nextflow.enable.dsl = 2

include { SELECT_VARIANT_TYPES } from '../modules/local/select_variant_types'

workflow {
    if (!params.vcf || !params.vcf_index || !params.ref_dir)
        error 'Specify --vcf, --vcf_index and --ref_dir'

    def refs = [
        'toy.fasta',
        'toy.fasta.fai',
        'toy.dict'
    ].collect { file("${params.ref_dir}/${it}") }

    SELECT_VARIANT_TYPES(
        Channel.of(tuple(
            'TEST',
            file(params.vcf),
            file(params.vcf_index)
        )),
        Channel.value(refs)
    )

    SELECT_VARIANT_TYPES.out.snps.view { result ->
        "SNP OUTPUTS READY: ${result[0]}"
    }

    SELECT_VARIANT_TYPES.out.indels.view { result ->
        "INDEL OUTPUTS READY: ${result[0]}"
    }
}
