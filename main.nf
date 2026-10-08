nextflow.enable.dsl = 2

params.input_vcf = "${projectDir}/results/annotation/vep/HG002.autosomes.PASS.vep.analysis.vcf.gz"
params.rtg_tp = "${projectDir}/results/benchmark/rtg/HG002_autosomes/tp.vcf.gz"
params.rtg_fp = "${projectDir}/results/benchmark/rtg/HG002_autosomes/fp.vcf.gz"
params.benchmark_bed = "${projectDir}/resources/giab/HG002_GRCh38_v5.0q_smvar_AgilentV5.autosomes.benchmark.bed"
params.baseline_dir = "${projectDir}/results/annotation/summary"
params.producer = "${projectDir}/scripts/produce_hg002_prioritization.sh"
params.vep_env = "${System.getenv('HOME')}/miniconda3/envs/vep-annotation"

process PRODUCE_PRIORITIZATION {
    tag 'HG002'
    cpus 1
    memory '2 GB'
    conda params.vep_env

    input:
    path vcf, name: 'input.vcf.gz'
    path tp, name: 'rtg/tp.vcf.gz'
    path fp, name: 'rtg/fp.vcf.gz'
    path bed, name: 'benchmark.bed'
    path producer, name: 'producer.sh'

    output:
    path 'produced', emit: tables

    script:
    """
    bash producer.sh --out-dir produced --input input.vcf.gz --rtg-dir rtg --benchmark-bed benchmark.bed
    """
}

process VERIFY_PRIORITIZATION {
    tag 'HG002'
    cpus 1
    memory '512 MB'

    input:
    path generated, name: 'generated'
    path baseline, name: 'baseline'

    output:
    path 'verification.txt'

    script:
    '''
    set -euo pipefail

    for name in \
        HG002.vep.PICK.tsv \
        HG002.rare_protein_altering.tsv \
        HG002.rare_candidates_with_genotypes.tsv \
        HG002.high_impact_review.tsv \
        HG002.rare_missense_both_damaging_review.tsv \
        HG002.rare_missense_strict_review.tsv \
        HG002.shortlist30.tsv \
        HG002.shortlist30_GIAB.tsv \
        HG002.shortlist30_GIAB.final.tsv
    do
        if ! cmp -s "generated/$name" "baseline/$name"; then
            echo "MISMATCH: $name" >&2
            exit 1
        fi
    done

    echo "PASS: All 9 HG002 prioritization tables are byte-identical" > verification.txt
    '''
}

workflow {
    PRODUCE_PRIORITIZATION(
        file(params.input_vcf),
        file(params.rtg_tp),
        file(params.rtg_fp),
        file(params.benchmark_bed),
        file(params.producer)
    )

    VERIFY_PRIORITIZATION(
        PRODUCE_PRIORITIZATION.out.tables,
        file(params.baseline_dir)
    )

    VERIFY_PRIORITIZATION.out.view { it.text.trim() }
}
