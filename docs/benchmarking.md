# HG002 GIAB Benchmarking

## Benchmark design

Variant-calling performance was evaluated using the Genome in a Bottle
HG002 small-variant benchmark, release v5.0q, on GRCh38.

Evaluation was restricted to the intersection of:

- GIAB HG002 v5.0q small-variant benchmark regions
- Agilent SureSelect Human All Exon V5 capture targets
- autosomes chr1-chr22

The resulting autosomal evaluation territory contains 215,950 intervals
covering 47,405,929 bp (47.41 Mb). This is smaller than the
49,216,825 bp WES benchmark region recorded in `docs/resources.md`,
which was calculated before restricting the evaluation to autosomes.

The query callset consisted of normalized, hard-filtered PASS variants
generated during the manual HG002 analysis. The complete Nextflow
FASTQ-to-PASS workflow was tested separately using synthetic data.

RTG Tools vcfeval v3.13 was used for haplotype-aware comparison.

## Overall performance

Using the complete PASS callset without additional GQ thresholding:

- Precision: 97.38%
- Sensitivity: 95.83%
- F-measure: 96.60%
- True-positive baseline variants: 40,798
- True-positive call variants: 40,814
- False positives: 1,100
- False negatives: 1,776

## SNP performance

- GIAB baseline SNPs: 39,040
- Query SNPs: 38,341
- True-positive baseline SNPs: 37,796
- True-positive called SNPs: 37,730
- False positives: 611
- False negatives: 1,244
- Precision: 98.41%
- Sensitivity: 96.81%
- F-measure: 97.60%

## INDEL performance

- GIAB baseline indels: 3,504
- Query indels: 3,573
- True-positive baseline indels: 2,988
- True-positive called indels: 3,084
- False positives: 489
- False negatives: 516
- Precision: 86.31%
- Sensitivity: 85.27%
- F-measure: 85.79%

## Interpretation

The manual HG002 analysis showed high accuracy for germline SNP discovery
within the benchmarkable WES target territory.

Indel performance is lower than SNP performance, reflecting the greater
difficulty of short-read indel detection and local haplotype reconstruction.

The overall benchmark result is dominated by the larger number of SNPs,
so SNP and indel metrics are reported separately.

No additional genotype-quality threshold was selected using HG002 benchmark
performance. This avoids tuning parameters on the same truth set used for
final performance evaluation.

## Effect of hard filtering

The normalized callset was also benchmarked before hard filtering using
the identical GIAB truth set and autosomal WES evaluation territory.

### Overall comparison

| Callset | Precision | Sensitivity | F-measure |
|---|---:|---:|---:|
| Pre-filter | 96.26% | 97.09% | 96.68% |
| Hard-filtered PASS | 97.38% | 95.83% | 96.60% |

Hard filtering increased overall precision by 1.12 percentage points
while reducing sensitivity by 1.26 percentage points. Overall F-measure
changed only slightly (-0.08 percentage points).

### SNP comparison

| Callset | Precision | Sensitivity | F-measure |
|---|---:|---:|---:|
| Pre-filter | 97.41% | 98.16% | 97.79% |
| Hard-filtered PASS | 98.41% | 96.81% | 97.60% |

For SNPs, hard filtering substantially reduced false positives and
increased precision, but also removed true-positive variants, producing
a small reduction in F-measure.

### INDEL comparison

| Callset | Precision | Sensitivity | F-measure |
|---|---:|---:|---:|
| Pre-filter | 84.04% | 85.59% | 84.81% |
| Hard-filtered PASS | 86.31% | 85.27% | 85.79% |

For indels, hard filtering produced a favorable trade-off. Precision
increased by 2.27 percentage points while sensitivity decreased by only
0.32 percentage points, increasing the indel F-measure by 0.98
percentage points.

### Interpretation

The predefined hard-filter thresholds were evaluated rather than
optimized using HG002. No thresholds were modified in response to the
HG002 benchmark results, avoiding parameter tuning on the same truth
set used for final validation.

The hard-filtered PASS callset is retained for downstream annotation
because it provides higher precision, while both pre-filter and
post-filter benchmark results are reported to make the sensitivity-
specificity trade-off explicit.
