nextflow.enable.dsl = 2

// Upstream processes
include { FASTQC } from '../modules/local/fastqc'
include { BWA_MEM_SORT } from '../modules/local/bwa_mem_sort'
include { MARK_DUPLICATES } from '../modules/local/mark_duplicates'
include { COLLECT_HS_METRICS } from '../modules/local/collect_hs_metrics'
include { BASE_RECALIBRATOR } from '../modules/local/base_recalibrator'
include { APPLY_BQSR } from '../modules/local/apply_bqsr'
include { HAPLOTYPE_CALLER } from '../modules/local/haplotype_caller'
include { GENOTYPE_GVCFS } from '../modules/local/genotype_gvcfs'

// Downstream processes
include { NORMALIZE_VARIANTS } from '../modules/local/normalize_variants'
include { SELECT_VARIANT_TYPES } from '../modules/local/select_variant_types'
include { FILTER_SNPS; FILTER_INDELS } from '../modules/local/variant_filtration'
include { COMBINE_PASS_VARIANTS } from '../modules/local/combine_pass_variants'

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

    def input_files = [
        params.r1,
        params.r2,
        params.capture_intervals,
        params.calling_intervals,
        "${params.gatk_ref_dir}/${refname}",
        "${params.gatk_ref_dir}/${refname}.fai",
        "${params.gatk_ref_dir}/" +
            refname.replaceFirst(/\.fasta$/, '.dict')
    ]

    input_files += [
        '', '.64.amb', '.64.ann', '.64.bwt',
        '.64.pac', '.64.sa', '.64.alt'
    ].collect { suffix ->
        "${params.bwa_ref_dir}/${refname}${suffix}"
    }

    input_files += [
        'Homo_sapiens_assembly38.dbsnp138.vcf',
        'Homo_sapiens_assembly38.dbsnp138.vcf.idx',
        'Homo_sapiens_assembly38.known_indels.vcf.gz',
        'Homo_sapiens_assembly38.known_indels.vcf.gz.tbi',
        'Mills_and_1000G_gold_standard.indels.hg38.vcf.gz',
        'Mills_and_1000G_gold_standard.indels.hg38.vcf.gz.tbi'
    ].collect { name ->
        "${params.known_sites_dir}/${name}"
    }

    input_files.each { location ->
        file(location.toString(), checkIfExists: true)
    }

    def reads = Channel.of(
        tuple(sample_id, [
            file(params.r1),
            file(params.r2)
        ])
    )

    def read_group = (
        params.containsKey('read_group') ? params.read_group : null
    ) ?: (
        '@RG\\tID:' + sample_id +
        '\\tSM:' + sample_id +
        '\\tLB:' + sample_id +
        '_WES\\tPL:ILLUMINA'
    )

    def bwa_reference = Channel.value(
        ['', '.64.amb', '.64.ann',
         '.64.bwt', '.64.pac', '.64.sa',
         '.64.alt'].collect { suffix ->
            file("${params.bwa_ref_dir}/${refname}${suffix}")
        }
    )

    def gatk_reference = Channel.value([
        file("${params.gatk_ref_dir}/${refname}"),
        file("${params.gatk_ref_dir}/${refname}.fai"),
        file("${params.gatk_ref_dir}/" +
             refname.replaceFirst(/\.fasta$/, '.dict'))
    ])

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

    // Check reference compatibility before starting the pipeline.
    def validator = file(
        "${projectDir}/../scripts/validate_reference_compatibility.py",
        checkIfExists: true
    )

    def validation_command = [
        'python3',
        validator.toString(),
        '--bwa-fasta', "${params.bwa_ref_dir}/${refname}",
        '--gatk-fasta', "${params.gatk_ref_dir}/${refname}",
        '--fai', "${params.gatk_ref_dir}/${refname}.fai",
        '--dict', "${params.gatk_ref_dir}/" +
            refname.replaceFirst(/\.fasta$/, '.dict'),
        '--capture', params.capture_intervals.toString(),
        '--calling', params.calling_intervals.toString(),
        '--known-sites',
        "${params.known_sites_dir}/Homo_sapiens_assembly38.dbsnp138.vcf",
        "${params.known_sites_dir}/Homo_sapiens_assembly38.known_indels.vcf.gz",
        "${params.known_sites_dir}/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz"
    ]

    def check = new ProcessBuilder(validation_command)
        .redirectErrorStream(true)
        .start()

    def report = check.inputStream.getText('UTF-8')
    def status = check.waitFor()

    if (status != 0)
        error "Reference compatibility validation failed:\n${report}"

    println report.trim()

    // FASTQ QC branch.
    FASTQC(reads)

    // Align, sort and mark duplicates.
    BWA_MEM_SORT(
        reads.map { id, pairs ->
            tuple(id, pairs, read_group)
        },
        bwa_reference
    )

    MARK_DUPLICATES(BWA_MEM_SORT.out.bam)

    // Hybrid-selection QC branch.
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

    // Connect upstream raw VCF to downstream processing.
    NORMALIZE_VARIANTS(
        GENOTYPE_GVCFS.out.vcf,
        gatk_reference
    )

    SELECT_VARIANT_TYPES(
        NORMALIZE_VARIANTS.out.vcf,
        gatk_reference
    )

    FILTER_SNPS(
        SELECT_VARIANT_TYPES.out.snps,
        gatk_reference
    )

    FILTER_INDELS(
        SELECT_VARIANT_TYPES.out.indels,
        gatk_reference
    )

    // Pair SNP and indel files by sample ID.
    def filtered_pairs = FILTER_SNPS.out.vcf.join(
        FILTER_INDELS.out.vcf
    )

    COMBINE_PASS_VARIANTS(filtered_pairs)

    // Completion messages.
    FASTQC.out.reports.view { result ->
        "FASTQC READY: ${result[0]}"
    }

    COLLECT_HS_METRICS.out.reports.view { result ->
        "CAPTURE METRICS READY: ${result[0]}"
    }

    COMBINE_PASS_VARIANTS.out.filtered.view { result ->
        "COMBINED FILTERED VCF READY: ${result[0]}"
    }

    COMBINE_PASS_VARIANTS.out.pass.view { result ->
        "FINAL PASS VCF READY: ${result[0]}"
    }
}
