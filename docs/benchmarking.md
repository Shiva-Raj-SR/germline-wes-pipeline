# HG002 GIAB Benchmarking

## Benchmark design

Variant-calling performance was evaluated using the Genome in a Bottle
HG002 small-variant benchmark, release v5.0q, on GRCh38.

Evaluation was restricted to the intersection of:

- GIAB HG002 v5.0q small-variant benchmark regions
- Agilent SureSelect Human All Exon V5 capture targets
- autosomes chr1-chr22

The resulting autosomal evaluation territory contains 215,950 intervals
covering 47,405,929 bp (47.41 Mb).

The query callset consisted of normalized, hard-filtered PASS variants
generated from HG002 WES data.

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

The workflow demonstrates high accuracy for germline SNP discovery within
the benchmarkable WES target territory.

Indel performance is lower than SNP performance, reflecting the greater
difficulty of short-read indel detection and local haplotype reconstruction.

The overall benchmark result is dominated by the larger number of SNPs,
so SNP and indel metrics are reported separately.

No additional genotype-quality threshold was selected using HG002 benchmark
performance. This avoids tuning parameters on the same truth set used for
final performance evaluation.
