nextflow.enable.dsl = 2

include { FASTQC } from '../modules/local/fastqc'
include { BWA_MEM_SORT } from '../modules/local/bwa_mem_sort'
include { MARK_DUPLICATES } from '../modules/local/mark_duplicates'
include { COLLECT_HS_METRICS } from '../modules/local/collect_hs_metrics'
include { BASE_RECALIBRATOR } from '../modules/local/base_recalibrator'
include { APPLY_BQSR } from '../modules/local/apply_bqsr'
include { HAPLOTYPE_CALLER } from '../modules/local/haplotype_caller'
include { GENOTYPE_GVCFS } from '../modules/local/genotype_gvcfs'

workflow {
    def required = [
        'r1', 'r2', 'reference_name',
        'bwa_ref_dir', 'gatk_ref_dir',
        'known_sites_dir',
        'capture_intervals', 'calling_intervals'
    ]

    required.each { name ->
        if (!params[name])
            error "Missing required parameter: --${name}"
    }

    def sample_id = params.sample_id ?: 'TEST'
    def refname = params.reference_name.toString()

    if (!refname.endsWith('.fasta'))
        error 'Reference name must end with .fasta'

    // Preserve sample identity throughout the workflow.
    def reads = Channel.of(
        tuple(sample_id, [
            file(params.r1),
            file(params.r2)
        ])
    )

    def read_group = (params.containsKey('read_group') ? params.read_group : null) ?: (
        '@RG\\tID:' + sample_id +
        '\\tSM:' + sample_id +
        '\\tLB:' + sample_id +
        '_WES\\tPL:ILLUMINA'
    )

    // BWA reference and its five .64 indexes plus ALT file.
    def bwa_reference = Channel.value(
        ['', '.64.amb', '.64.ann',
         '.64.bwt', '.64.pac', '.64.sa',
         '.64.alt'].collect { suffix ->
            file("${params.bwa_ref_dir}/${refname}${suffix}")
        }
    )

    // Reference FASTA, FASTA index, and sequence dictionary.
    def gatk_reference = Channel.value([
        file("${params.gatk_ref_dir}/${refname}"),
        file("${params.gatk_ref_dir}/${refname}.fai"),
        file("${params.gatk_ref_dir}/" +
             refname.replaceFirst(/\.fasta$/, '.dict'))
    ])

    // Three known-sites VCFs and their indexes.
    def known_sites = Channel.value([
        'Homo_sapiens_assembly38.dbsnp138.vcf',
        'Homo_sapiens_assembly38.dbsnp138.vcf.idx',
        'Homo_sapiens_assembly38.known_indels.vcf.gz',
        'Homo_sapiens_assembly38.known_indels.vcf.gz.tbi',
        'Mills_and_1000G_gold_standard.indels.hg38.vcf.gz',
        'Mills_and_1000G_gold_standard.indels.hg38.vcf.gz.tbi'
    ].collect { name ->
        file("${params.known_sites_dir}/${name}")
    })

    // Quality control and alignment.
    FASTQC(reads)

    BWA_MEM_SORT(
        reads.map { id, pairs ->
            tuple(id, pairs, read_group)
        },
        bwa_reference
    )

    // Duplicate marking.
    MARK_DUPLICATES(BWA_MEM_SORT.out.bam)

    // Capture metrics QC branch.
    COLLECT_HS_METRICS(
        MARK_DUPLICATES.out.bam,
        file(params.capture_intervals),
        gatk_reference
    )

    // Base quality score recalibration.
    BASE_RECALIBRATOR(
        MARK_DUPLICATES.out.bam,
        gatk_reference,
        known_sites
    )

    // Match BAM and recalibration table by sample ID.
    def bam_with_table = MARK_DUPLICATES.out.bam.join(
        BASE_RECALIBRATOR.out.table
    )

    APPLY_BQSR(bam_with_table, gatk_reference)

    // Germline calling and genotyping.
    HAPLOTYPE_CALLER(
        APPLY_BQSR.out.bam,
        gatk_reference,
        file(params.calling_intervals)
    )

    GENOTYPE_GVCFS(
        HAPLOTYPE_CALLER.out.gvcf,
        gatk_reference,
        file(params.calling_intervals)
    )

    // Report completed output channels.
    FASTQC.out.reports.view { result ->
        "FASTQC READY: ${result[0]}"
    }

    COLLECT_HS_METRICS.out.reports.view { result ->
        "CAPTURE METRICS READY: ${result[0]}"
    }

    GENOTYPE_GVCFS.out.vcf.view { result ->
        "UPSTREAM RAW VCF READY: ${result[0]}"
    }
}
