nextflow.enable.dsl = 2

include { BWA_MEM_SORT } from '../modules/local/bwa_mem_sort'

workflow {
    if (!params.test_dir)
        error 'Specify --test_dir'

    def files = [
        'toy.fasta',
        'toy.fasta.64.amb',
        'toy.fasta.64.ann',
        'toy.fasta.64.bwt',
        'toy.fasta.64.pac',
        'toy.fasta.64.sa',
        'toy.fasta.64.alt'
    ].collect { file("${params.test_dir}/${it}") }

    def reads = [
        file("${params.test_dir}/R1.fastq"),
        file("${params.test_dir}/R2.fastq")
    ]

    def rg = '@RG\\tID:TEST\\tSM:TEST\\tLB:TEST_WES\\tPL:ILLUMINA'

    BWA_MEM_SORT(
        Channel.of(tuple('TEST', reads, rg)),
        Channel.value(files)
    )

    BWA_MEM_SORT.out.bam.view { result ->
        "BWA OUTPUTS READY: ${result[0]}"
    }
}
