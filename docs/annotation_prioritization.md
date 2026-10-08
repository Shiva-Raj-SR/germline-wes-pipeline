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
