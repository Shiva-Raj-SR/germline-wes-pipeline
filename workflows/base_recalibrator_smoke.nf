nextflow.enable.dsl = 2

include { BASE_RECALIBRATOR } from '../modules/local/base_recalibrator'

workflow {
    if (!params.test_dir)
        error 'Specify --test_dir'

    def dir = params.test_dir

    def refs = [
        'toy.fasta',
        'toy.fasta.fai',
        'toy.dict'
    ].collect { file("${dir}/${it}") }

    def sites = [
        'Homo_sapiens_assembly38.dbsnp138.vcf',
        'Homo_sapiens_assembly38.dbsnp138.vcf.idx',
        'Homo_sapiens_assembly38.known_indels.vcf.gz',
        'Homo_sapiens_assembly38.known_indels.vcf.gz.tbi',
        'Mills_and_1000G_gold_standard.indels.hg38.vcf.gz',
        'Mills_and_1000G_gold_standard.indels.hg38.vcf.gz.tbi'
    ].collect { file("${dir}/${it}") }

    BASE_RECALIBRATOR(
        Channel.of(tuple(
            'TEST',
            file("${dir}/TEST.markdup.bam"),
            file("${dir}/TEST.markdup.bam.bai")
        )),
        Channel.value(refs),
        Channel.value(sites)
    )

    BASE_RECALIBRATOR.out.table.view { result ->
        "BASE_RECALIBRATOR OUTPUT READY: ${result[0]}"
    }
}
