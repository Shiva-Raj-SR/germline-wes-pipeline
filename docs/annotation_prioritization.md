# HG002 Germline WES: Functional Annotation and Variant Prioritization

## Scope

This analysis uses GIAB HG002 germline WES autosomal variants
called against GRCh38, hard-filtered with GATK, and annotated
using Ensembl VEP 116.2.

HG002 is a benchmarking sample. Variant prioritization here is
a workflow demonstration, not a clinical diagnosis.

## Annotation resources

- Ensembl VEP: 116.2
- Genome assembly: GRCh38
- Transcript annotation: GENCODE 50
- ClinVar cache release: 202509
- dbSNP: 156
- gnomAD exomes and genomes: v4.1
- SIFT and PolyPhen predictions included

The VEP cache was used in offline mode.

## Annotation results

- Hard-filtered PASS records: 44,289
- Sequence-resolved variants annotated with CSQ: 44,253
- Spanning-deletion (*) records without CSQ: 36
- Preferred transcript consequences: 44,253
- HIGH-impact preferred consequences: 250
- MODERATE-impact preferred consequences: 8,548
- LOW-impact preferred consequences: 12,131
- MODIFIER-impact preferred consequences: 23,324

The complete annotated VCF retains the 36 spanning-deletion
records. The downstream analysis VCF excludes them.

## Population-frequency prioritization

A variant was considered rare for exploratory prioritization
when its annotated MAX_AF was known and <= 0.01.

- Rare HIGH/MODERATE-impact variants: 199
- HIGH impact: 14
- MODERATE impact: 185
- Protein-coding preferred biotype: 194
- Immunoglobulin-gene preferred biotypes: 5

Missing frequency was not interpreted as evidence of rarity.

## Clinical annotations

- Variants containing explicit Pathogenic or Likely Pathogenic
  labels: 37
- Variants with only P/LP classification tokens: 6
- Variants with P/LP plus other classification tokens: 31

These are aggregated VEP CLIN_SIG annotations, not independent
clinical classifications. Condition specificity, ClinVar review
status, conflicting assertions, inheritance and phenotype
require additional investigation.

## Functional prediction prioritization

Among 185 rare MODERATE-impact variants:

- Missense-containing consequences: 181
- In-frame indels: 4
- SIFT and PolyPhen both flagged damaging: 59
- Standard SIFT deleterious predictions among these 59: 35
- Low-confidence SIFT deleterious predictions: 24
- Both predictors flagged damaging, with standard SIFT
  deleterious, PolyPhen probably damaging, and no basic
  sequencing-review flags: 25

Computational predictions do not establish pathogenicity.

## Sequencing-evidence review

Exploratory checks considered depth, alternate read support,
heterozygous allele balance and AD-versus-DP discrepancies.

- Rare HIGH-impact variants: 14
- HIGH-impact variants without basic review flags: 5
- Dual-predictor missense variants: 59
- Dual-predictor missense variants without basic flags: 58

No-basic-flags status is not equivalent to read-level validation.
Complex or repetitive loci can still contain alignment artifacts.

## Final 30-variant exploratory shortlist

The final shortlist comprises:

- 5 rare HIGH-impact variants without basic review flags
- 25 rare missense variants meeting the stricter SIFT/PolyPhen
  and sequencing-support criteria

GIAB RTG vcfeval call-side results were used for an exact-allele
cross-check against the existing autosomal Agilent V5 benchmark.

- Exact matches in RTG true-positive VCF: 29
- Exact matches in RTG false-positive VCF: 0
- Outside the benchmark interval set: 1

The out-of-region variant is a FLG2 frameshift at
chr1:152354681, REF=GTATT, ALT=G.

Its five-base REF span has zero overlap with the intersection
of GIAB confident regions and Agilent V5 autosomal targets.
It was therefore not assessed by this benchmark.

RTG true-positive concordance supports technical call accuracy
within the benchmark scope. It does not establish disease
causality or clinical pathogenicity.

## Limitations and next steps

- Preferred PICK consequences may differ from the most severe
  consequence across all transcripts.
- MANE and alternative transcript consequences should be
  retained for downstream disease-focused interpretation.
- Population frequency and in-silico predictors are not
  sufficient for clinical classification.
- Short-read WES can be unreliable in repetitive, polymorphic
  or homologous regions.
- Basic genotype metrics do not replace read-level BAM review.
- Sex-chromosome interpretation is outside this autosomal
  benchmark.
- Clinical interpretation requires phenotype, inheritance,
  condition-specific evidence and appropriate validation.

All 199 rare HIGH/MODERATE candidates remain available in the
full prioritization table. The 30-variant shortlist is an
exploratory technical-review subset, not an exhaustive list
of potentially clinically relevant variants.

## Independent prioritization producer

`scripts/prioritize_hg002_vep.sh` remains the unchanged six-stage regression
harness from commit `1526f93`, including its historical CHROM/POS/SYMBOL
shortlist lookup. The independent `scripts/produce_hg002_prioritization.sh`
never reads reference output tables. It extracts existing VEP and RTG data;
it does not run alignment, variant calling, benchmarking, or VEP annotation.

### Inputs and software

Default paths resolve relative to the producer's repository, independently of
the caller's working directory:

| Input | Repository-relative default |
|---|---|
| Single-sample, sequence-resolved VEP analysis VCF | `results/annotation/vep/HG002.autosomes.PASS.vep.analysis.vcf.gz` |
| Existing RTG call-side TP/FP VCFs | `results/benchmark/rtg/HG002_autosomes/tp.vcf.gz` and `fp.vcf.gz` |
| Existing 0-based, half-open benchmark BED | `resources/giab/HG002_GRCh38_v5.0q_smvar_AgilentV5.autosomes.benchmark.bed` |

Requirements: Bash, bcftools with `+split-vep`, AWK, and standard utilities
`cut`, `wc`, `mkdir`, `sha256sum`. Validation used bcftools/htslib 1.21 in
the existing `vep-annotation` Conda environment. Python 3 is needed only for
synthetic tests. VEP 116.2 previously generated the annotations; VEP itself,
its cache, a reference genome, network access, and downloads are not needed.

The input must already be the appropriate autosomal PASS callset with
GT/DP/GQ/AD and the CSQ fields used in the PICK table. The producer does not
normalize, split, or reapply upstream hard filters. Exactly one sample is
required. Multiallelic ALT, spanning-deletion `*`, duplicate genotype allele
keys, and duplicate PICK allele keys are rejected rather than merged.
The producer is validated for HG002; input overrides support tests and
alternate locations, not a validated general clinical pipeline.

### Exact allele identity and thresholds

All genotype, shortlist, RTG, and benchmark-region joins use exact
`CHROM/POS/REF/ALT` tuples, preserving representations and row order.
Contig names and alleles must agree across inputs; equivalent haplotype
representations can remain unmatched. This lookup does not replace RTG's
haplotype-aware benchmarking.

The baseline expressions are deliberately preserved:

1. Retain `PICK=1` consequences.
2. Select HIGH or MODERATE impact with known `MAX_AF <= 0.01`, inclusive.
   Empty or `.` frequency is excluded; no protein-coding biotype restriction
   is applied. Baseline AWK numeric conversion is retained; malformed
   nonnumeric frequency strings are not separately validated.
3. Join genotype evidence by exact allele. With exactly two integer AD counts
   and positive sum, calculate ALT AD / (REF AD + ALT AD), rounded to three
   decimals. Review thresholds use this rounded balance.
4. HIGH-impact flags, in emitted order:
   `LOW_DEPTH;` if numeric DP < 10 (missing DP coerces to 0);
   `LOW_ALT_SUPPORT;` if there are two AD entries and integer ALT AD < 10;
   `ALLELE_IMBALANCE;` if available balance is outside [0.30, 0.70],
   regardless of genotype; `AD_DP_DISCREPANCY;` if two AD entries exist,
   DP > 0, and AD sum / DP < 0.5.
5. Dual-predictor missense selection requires MODERATE impact, a consequence
   containing `missense_variant`, SIFT starting `deleterious` (including low
   confidence), and PolyPhen starting `probably_damaging` or
   `possibly_damaging`. These predictor checks are case insensitive.
   Flags, in emitted order: missing/empty DP yields `MISSING_DP;`, otherwise
   DP < 10 yields `LOW_DEPTH;`. Exactly two integer AD counts are required;
   otherwise flag `MISSING_AD;`. Valid AD with ALT AD < 10 yields
   `LOW_ALT_SUPPORT;`; integer DP > 0 and AD sum / DP < 0.5 yields
   `AD_DP_DISCREPANCY;`. Only 0/1 or 1/0, including phased equivalents,
   receives `MISSING_ALT_BALANCE;` or `ALLELE_IMBALANCE;` outside
   [0.30, 0.70].
6. Empty flags become `NO_BASIC_FLAGS`. Strict missense additionally requires
   the original case-sensitive prefixes `deleterious(` and
   `probably_damaging(`. Low-confidence SIFT and possibly-damaging PolyPhen
   are excluded from this strict subset.
7. Shortlist HIGH records with no basic flags plus strict missense records.
   Counts derive from inputs; the producer does not enforce 199, 25, or 30.
8. Exact RTG lookup yields `RTG_TP`, `RTG_FP`, `CHECK_BOTH`, or
   `NOT_FOUND_EXACT`. TP-only becomes `TP_MATCH_IN_BENCHMARK`.
   For unmatched alleles, test [POS-1, POS-1+length(REF)) against the BED.
   Zero overlap means `OUTSIDE_BENCHMARK`. Any overlap, including partial
   overlap, remains `REQUIRES_REVIEW`; FP and both-set matches also require
   review. Interval checks do not reclassify TP/FP matches.

These rules intentionally retain branch differences: HIGH missing AD can remain
unflagged; HIGH homozygous ALT can be flagged for imbalance, while missense
imbalance applies only to heterozygotes. GQ is reported but never thresholded.
These exploratory flags are not exhaustive read-level validation. Neither
HIGH impact, damaging predictions, no basic flags, nor RTG TP concordance
establishes pathogenicity, phenotype relevance, inheritance, or disease
causality. Missing population frequency is not evidence of rarity.

### Outputs and protection

The requested output directory **must not exist**; existing directories and
symlinks are refused. Validated summaries are never overwritten. A failed run
may leave partial files in its newly created directory; only a manifest ending
`status=COMPLETE` indicates success. Retry in a fresh directory.

All table names below have the `HG002.` prefix:

| Suffix | Purpose | HG002 rows |
|---|---|---:|
| `vep.PICK.tsv` | Preferred consequences | 44,253 |
| `rare_protein_altering.tsv` | Rare HIGH/MODERATE | 199 |
| `rare_candidates_with_genotypes.tsv` | Candidates with genotype evidence | 199 |
| `high_impact_review.tsv` | Historical HIGH review layout | 14 |
| `rare_missense_both_damaging_review.tsv` | Historical dual-predictor review | 59 |
| `rare_missense_strict_review.tsv` | Historical strict missense review | 25 |
| `shortlist30.tsv` | Exact-allele shortlist | 30 |
| `shortlist30_GIAB.tsv` | Exact RTG status | 30 |
| `shortlist30_GIAB.final.tsv` | Benchmark interpretation | 30 |

Three new `*.alleles.tsv` companion review tables append REF and ALT to the
HIGH, dual-predictor, and strict missense layouts. They carry exact identities
through selection while the nine historical tables remain byte-compatible.
`HG002.shortlist30.keys.tsv` intentionally changes from the old
CHROM/POS/SYMBOL/GROUP layout to CHROM/POS/REF/ALT/GROUP. Despite the
`shortlist30` filename, other valid inputs may produce different counts.

Retained intermediates: `HG002.genotypes.tsv`, `rtg_TP_alleles.tsv`,
`rtg_FP_alleles.tsv`, `outside_benchmark.keys.tsv`. The manifest records sample,
bcftools/htslib versions, SHA256 of the producer and all four inputs, and
completion. HG002 output occupies about 11 MB. Transcript extraction is
streamed; no full all-transcript table is materialized.

### Execution and verification

Run from the repository checkout. Replace the directory below
with the location of your own repository:

```bash
cd /path/to/germline-wes-pipeline
conda activate vep-annotation
run_root="$(mktemp -d /tmp/hg002-prioritization.XXXXXX)"
scripts/produce_hg002_prioritization.sh --out-dir "$run_root/generated"
```

The parent exists; its `generated` child must not exist. To override input
locations (using a different new output child):

```bash
scripts/produce_hg002_prioritization.sh \
  --input results/annotation/vep/HG002.autosomes.PASS.vep.analysis.vcf.gz \
  --rtg-dir results/benchmark/rtg/HG002_autosomes \
  --benchmark-bed resources/giab/HG002_GRCh38_v5.0q_smvar_AgilentV5.autosomes.benchmark.bed \
  --out-dir "$run_root/explicit-input-run"
```

Syntax checks, synthetic tests, unchanged baseline regression, and nine exact
comparisons:

```bash
bash -n scripts/produce_hg002_prioritization.sh scripts/prioritize_hg002_vep.sh
python3 -B tests/test_prioritization_producer.py
scripts/prioritize_hg002_vep.sh
for table in \
  vep.PICK rare_protein_altering rare_candidates_with_genotypes \
  high_impact_review rare_missense_both_damaging_review \
  rare_missense_strict_review shortlist30 shortlist30_GIAB shortlist30_GIAB.final
do
  cmp "results/annotation/summary/HG002.$table.tsv" \
      "$run_root/generated/HG002.$table.tsv" || exit 1
  printf 'BYTE_IDENTICAL: HG002.%s.tsv\n' "$table"
done
git diff --check
git status --short
```

Synthetic tests run a standalone copy without reference output tables using
tiny generated VCF/BED fixtures. They cover same-position allele collisions,
all four key fields, RTG statuses, partial overlap and BED boundaries, threshold
boundaries, missing metrics, phased/homozygous genotypes, empty selections and
streams, ambiguous-input rejection, multiple samples, and overwrite refusal.

See [development validation results](prioritization_refactor_validation.md).
