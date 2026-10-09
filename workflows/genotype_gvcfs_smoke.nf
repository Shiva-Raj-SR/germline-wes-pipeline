nextflow.enable.dsl = 2

include { GENOTYPE_GVCFS } from '../modules/local/genotype_gvcfs'

workflow {
    if (!params.gvcf || !params.gvcf_index ||
        !params.ref_dir || !params.intervals)
        error 'Specify --gvcf, --gvcf_index, --ref_dir and --intervals'

    def refs = [
        'toy.fasta',
        'toy.fasta.fai',
        'toy.dict'
    ].collect { file("${params.ref_dir}/${it}") }

    GENOTYPE_GVCFS(
        Channel.of(tuple(
            'TEST',
            file(params.gvcf),
            file(params.gvcf_index)
        )),
        Channel.value(refs),
        file(params.intervals)
    )

    GENOTYPE_GVCFS.out.vcf.view { result ->
        "GENOTYPE_GVCFS OUTPUTS READY: ${result[0]}"
    }
}
