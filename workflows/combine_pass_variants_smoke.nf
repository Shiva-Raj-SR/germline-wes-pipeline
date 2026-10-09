nextflow.enable.dsl = 2

include { COMBINE_PASS_VARIANTS } from '../modules/local/combine_pass_variants'

workflow {
    if (!params.snps || !params.snps_index ||
        !params.indels || !params.indels_index)
        error 'Specify SNP and indel VCFs and their indexes'

    COMBINE_PASS_VARIANTS(
        Channel.of(tuple(
            'TEST',
            file(params.snps),
            file(params.snps_index),
            file(params.indels),
            file(params.indels_index)
        ))
    )

    COMBINE_PASS_VARIANTS.out.filtered.view { result ->
        "COMBINED FILTERED VCF READY: ${result[0]}"
    }

    COMBINE_PASS_VARIANTS.out.pass.view { result ->
        "PASS VCF READY: ${result[0]}"
    }
}
