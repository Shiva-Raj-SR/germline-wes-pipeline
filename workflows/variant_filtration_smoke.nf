nextflow.enable.dsl = 2

include {
    FILTER_SNPS
    FILTER_INDELS
} from '../modules/local/variant_filtration'

workflow {
    if (!params.snps || !params.snps_index ||
        !params.indels || !params.indels_index ||
        !params.ref_dir)
        error 'Specify SNP/indel VCFs, indexes and --ref_dir'

    def refs = [
        'toy.fasta',
        'toy.fasta.fai',
        'toy.dict'
    ].collect { file("${params.ref_dir}/${it}") }

    FILTER_SNPS(
        Channel.of(tuple(
            'TEST',
            file(params.snps),
            file(params.snps_index)
        )),
        Channel.value(refs)
    )

    FILTER_INDELS(
        Channel.of(tuple(
            'TEST',
            file(params.indels),
            file(params.indels_index)
        )),
        Channel.value(refs)
    )

    FILTER_SNPS.out.vcf.view { result ->
        "FILTER_SNPS OUTPUTS READY: ${result[0]}"
    }

    FILTER_INDELS.out.vcf.view { result ->
        "FILTER_INDELS OUTPUTS READY: ${result[0]}"
    }
}
