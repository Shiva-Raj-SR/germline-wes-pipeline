nextflow.enable.dsl = 2

include { NORMALIZE_VARIANTS } from '../modules/local/normalize_variants'
include { SELECT_VARIANT_TYPES } from '../modules/local/select_variant_types'
include { FILTER_SNPS; FILTER_INDELS } from '../modules/local/variant_filtration'
include { COMBINE_PASS_VARIANTS } from '../modules/local/combine_pass_variants'

workflow {
    if (!params.raw_vcf || !params.raw_index || !params.reference_fasta)
        error 'Specify --raw_vcf, --raw_index and --reference_fasta'

    def sample_id = params.sample_id ?: 'TEST'
    def fasta = params.reference_fasta.toString()

    if (!fasta.endsWith('.fasta'))
        error 'Reference filename must end with .fasta'

    def reference_bundle = Channel.value([
        file(fasta),
        file("${fasta}.fai"),
        file(fasta.replaceFirst(/\.fasta$/, '.dict'))
    ])

    def raw_variants = Channel.of(tuple(
        sample_id,
        file(params.raw_vcf),
        file(params.raw_index)
    ))

    // Normalize and split multiallelic records.
    NORMALIZE_VARIANTS(raw_variants, reference_bundle)

    // Separate SNPs and indels.
    SELECT_VARIANT_TYPES(
        NORMALIZE_VARIANTS.out.vcf,
        reference_bundle
    )

    // Apply the original HG002 hard-filter thresholds.
    FILTER_SNPS(
        SELECT_VARIANT_TYPES.out.snps,
        reference_bundle
    )

    FILTER_INDELS(
        SELECT_VARIANT_TYPES.out.indels,
        reference_bundle
    )

    // Join the two branches by sample ID.
    def filtered_pairs = FILTER_SNPS.out.vcf.join(
        FILTER_INDELS.out.vcf
    )

    // Combine filtered variants and extract PASS records.
    COMBINE_PASS_VARIANTS(filtered_pairs)

    COMBINE_PASS_VARIANTS.out.filtered.view { result ->
        "COMBINED FILTERED VCF READY: ${result[0]}"
    }

    COMBINE_PASS_VARIANTS.out.pass.view { result ->
        "FINAL PASS VCF READY: ${result[0]}"
    }
}
