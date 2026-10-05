#!/usr/bin/env bash

set -euo pipefail

GIAB_BED="resources/giab/HG002_GRCh38_v5.0q_smvar.benchmark.bed"
TARGET_BED="resources/intervals/S04380110_Regions.bed"
REFERENCE_FAI="resources/reference/Homo_sapiens_assembly38.fasta.fai"
OUTPUT_BED="resources/giab/HG002_GRCh38_v5.0q_smvar_AgilentV5.benchmark.bed"

bedtools intersect \
    -a "${GIAB_BED}" \
    -b "${TARGET_BED}" \
    | cut -f1-3 \
    | bedtools sort \
        -faidx "${REFERENCE_FAI}" \
        -i - \
    | bedtools merge -i - \
    > "${OUTPUT_BED}"

echo "Created: ${OUTPUT_BED}"

wc -l "${OUTPUT_BED}"

awk '
{
    bases += $3-$2
}
END {
    printf "Benchmark territory: %d bases (%.2f Mb)\n",
           bases, bases/1000000
}' "${OUTPUT_BED}"

sha256sum "${OUTPUT_BED}"
