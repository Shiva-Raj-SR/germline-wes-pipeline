#!/usr/bin/env bash

set -euo pipefail

REF="resources/reference/Homo_sapiens_assembly38.fasta"
R1="data/raw/SRR2962669_1.fastq.gz"
R2="data/raw/SRR2962669_2.fastq.gz"

OUT="results/alignment/HG002.sorted.bam"
TMP="results/alignment/tmp/HG002"

RG='@RG\tID:SRR2962669\tSM:HG002\tLB:HG002_WES_OUS\tPL:ILLUMINA'

mkdir -p results/alignment/tmp logs/alignment

bwa mem \
    -t 2 \
    -R "${RG}" \
    "${REF}" \
    "${R1}" \
    "${R2}" \
    2> logs/alignment/HG002_bwa.log \
| samtools sort \
    -@ 1 \
    -m 256M \
    -T "${TMP}" \
    -o "${OUT}" \
    - \
    2> logs/alignment/HG002_samtools_sort.log

samtools quickcheck -v "${OUT}"

samtools index \
    -@ 2 \
    "${OUT}"

echo "HG002 alignment completed successfully."
