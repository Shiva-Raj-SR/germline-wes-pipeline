#!/usr/bin/env bash

set -euo pipefail

# Reproduce HG002 autosomal PASS variant annotation.
# Requires the vep-annotation Conda environment and
# the Ensembl VEP 116 GRCh38 cache.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

CACHE_DIR="${VEP_CACHE_DIR:-/mnt/d/vep_cache}"

INPUT="results/variants/filtered/HG002.autosomes.PASS.vcf.gz"
REFERENCE="resources/reference/Homo_sapiens_assembly38.fasta"

OUTDIR="results/annotation/vep"
BASENAME="HG002.autosomes.PASS.vep"

RAW="$OUTDIR/$BASENAME.vcf"
COMPRESSED="$RAW.gz"
ANALYSIS="$OUTDIR/$BASENAME.analysis.vcf.gz"

mkdir -p "$OUTDIR" logs/annotation

for tool in vep bcftools bgzip tabix; do
    command -v "$tool" >/dev/null || {
        echo "Missing dependency: $tool" >&2
        exit 1
    }
done

test -f "$INPUT"
test -f "$REFERENCE"
test -f "$CACHE_DIR/homo_sapiens/116_GRCh38/info.txt"

# Do not overwrite completed annotation results.
if [[ -e "$RAW" || -e "$COMPRESSED" || -e "$ANALYSIS" ]]; then
    echo "Annotation outputs already exist." >&2
    echo "Existing results have been preserved; no rerun performed." >&2
    exit 1
fi

vep \
    --input_file "$INPUT" \
    --output_file "$RAW" \
    --format vcf \
    --vcf \
    --cache \
    --offline \
    --dir_cache "$CACHE_DIR" \
    --species homo_sapiens \
    --assembly GRCh38 \
    --fasta "$REFERENCE" \
    --symbol \
    --canonical \
    --mane \
    --hgvs \
    --protein \
    --biotype \
    --variant_class \
    --check_existing \
    --af \
    --af_gnomade \
    --af_gnomadg \
    --max_af \
    --sift b \
    --polyphen b \
    --flag_pick \
    --fork 2 \
    2>&1 | tee logs/annotation/HG002_VEP.log

bgzip -@ 2 -c "$RAW" > "$COMPRESSED"
tabix -p vcf "$COMPRESSED"

bcftools view \
    -e 'ALT="*"' \
    -Oz \
    -o "$ANALYSIS" \
    "$COMPRESSED"

bcftools index -t "$ANALYSIS"

TOTAL=$(bcftools view -H "$COMPRESSED" | wc -l)
RESOLVED=$(bcftools view -H "$ANALYSIS" | wc -l)

echo "Complete annotated records: $TOTAL"
echo "Sequence-resolved records: $RESOLVED"

if [[ "$TOTAL" -ne 44289 || "$RESOLVED" -ne 44253 ]]; then
    echo "Unexpected variant counts; inspect outputs." >&2
    exit 1
fi

rm "$RAW"

echo "HG002 VEP annotation completed successfully."
