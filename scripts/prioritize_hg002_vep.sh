#!/usr/bin/env bash
set -euo pipefail

# HG002 VEP prioritization workflow
# Stage 1: Reproduce the PICK consequence table.
# Existing results are not modified.

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

INPUT="results/annotation/vep/HG002.autosomes.PASS.vep.analysis.vcf.gz"
EXPECTED="results/annotation/summary/HG002.vep.PICK.tsv"

command -v bcftools >/dev/null || {
    echo "ERROR: bcftools is required." >&2
    exit 1
}

[[ -s "$INPUT" ]] || {
    echo "ERROR: Annotated VCF missing." >&2
    exit 1
}

[[ -s "$EXPECTED" ]] || {
    echo "ERROR: Reference PICK table missing." >&2
    exit 1
}

# Temporary files are automatically removed.
WORKDIR=$(mktemp -d)
trap 'rm -rf -- "$WORKDIR"' EXIT

OUTPUT="$WORKDIR/HG002.vep.PICK.tsv"

printf 'CHROM\tPOS\tREF\tALT\tConsequence\tIMPACT\tSYMBOL\tGene\tFeature\tBIOTYPE\tHGVSc\tHGVSp\tExisting_variation\tPICK\tCANONICAL\tMANE_SELECT\tSIFT\tPolyPhen\tMAX_AF\tCLIN_SIG\n' \
    > "$OUTPUT"

# Stream transcript consequences and retain PICK=1.
# This avoids storing ~1.1 million transcript records.

bcftools +split-vep "$INPUT" \
    -d \
    -f '%CHROM\t%POS\t%REF\t%ALT\t%Consequence\t%IMPACT\t%SYMBOL\t%Gene\t%Feature\t%BIOTYPE\t%HGVSc\t%HGVSp\t%Existing_variation\t%PICK\t%CANONICAL\t%MANE_SELECT\t%SIFT\t%PolyPhen\t%MAX_AF\t%CLIN_SIG\n' \
    | awk -F'\t' '$14=="1"' \
    >> "$OUTPUT"

COUNT=$(awk 'END {print NR-1}' "$OUTPUT")

echo "Reproduced PICK records: $COUNT"

if [[ "$COUNT" -ne 44253 ]]; then
    echo "FAIL: Unexpected PICK variant count." >&2
    exit 1
fi

if cmp -s "$OUTPUT" "$EXPECTED"; then
    echo "PASS: Reproduced PICK table matches existing results."
else
    echo "FAIL: PICK table differs from existing results." >&2
    echo "Existing outputs remain unchanged." >&2
    exit 1
fi

echo "Stage 1 reproducibility validation: PASS"

# ------------------------------------------------------------
# Stage 2: Reproduce rare HIGH/MODERATE candidate selection.
# ------------------------------------------------------------

RARE_EXPECTED="results/annotation/summary/HG002.rare_protein_altering.tsv"
RARE_OUTPUT="$WORKDIR/HG002.rare_protein_altering.tsv"

[[ -s "$RARE_EXPECTED" ]] || {
    echo "ERROR: Reference rare-candidate table missing." >&2
    exit 1
}

awk -F'\t' '
BEGIN {OFS="\t"}

NR==1 {
    print
    next
}

($6=="HIGH" || $6=="MODERATE") &&
$19!="." &&
$19!="" &&
($19+0)<=0.01 {
    print
}
' "$OUTPUT" > "$RARE_OUTPUT"

RARE_COUNT=$(awk 'END {print NR-1}' "$RARE_OUTPUT")

echo "Reproduced rare HIGH/MODERATE candidates: $RARE_COUNT"

if [[ "$RARE_COUNT" -ne 199 ]]; then
    echo "FAIL: Expected 199 rare candidates." >&2
    exit 1
fi

awk -F'\t' '
NR>1 {count[$6]++}
END {
    print "HIGH-impact:", count["HIGH"]+0
    print "MODERATE-impact:", count["MODERATE"]+0
}
' "$RARE_OUTPUT"

if cmp -s "$RARE_OUTPUT" "$RARE_EXPECTED"; then
    echo "PASS: Reproduced rare-candidate table matches existing results."
else
    echo "FAIL: Rare-candidate table differs from existing results." >&2
    exit 1
fi

echo "Stage 2 reproducibility validation: PASS"

# ------------------------------------------------------------
# Stage 3: Reproduce genotype integration and allele balance.
# ------------------------------------------------------------

GENOTYPES="$WORKDIR/HG002.genotypes.tsv"
GENOTYPE_OUTPUT="$WORKDIR/HG002.rare_candidates_with_genotypes.tsv"

GENOTYPE_EXPECTED="results/annotation/summary/HG002.rare_candidates_with_genotypes.tsv"

[[ -s "$GENOTYPE_EXPECTED" ]] || {
    echo "ERROR: Reference genotype-integrated table missing." >&2
    exit 1
}

# Extract genotype evidence directly from the annotated VCF.

bcftools query \
    -f '%CHROM\t%POS\t%REF\t%ALT[\t%GT\t%DP\t%GQ\t%AD]\n' \
    "$INPUT" > "$GENOTYPES"

# Join using the exact CHROM, POS, REF, ALT allele identity.

awk -F'\t' '
BEGIN {OFS="\t"}

FNR==NR {
    key=$1 FS $2 FS $3 FS $4
    gt[key]=$5
    dp[key]=$6
    gq[key]=$7
    ad[key]=$8
    next
}

FNR==1 {
    print $0,"GT","DP","GQ","AD","ALT_BALANCE"
    next
}

{
    key=$1 FS $2 FS $3 FS $4

    if (!(key in gt)) {
        print "Missing genotype for " key > "/dev/stderr"
        next
    }

    balance="."

    if (ad[key] ~ /^[0-9]+,[0-9]+$/) {
        split(ad[key],a,",")
        total=a[1]+a[2]

        if (total>0)
            balance=sprintf("%.3f",a[2]/total)
    }

    print $0,gt[key],dp[key],gq[key],ad[key],balance
}
' "$GENOTYPES" "$RARE_OUTPUT" > "$GENOTYPE_OUTPUT"

GENOTYPE_COUNT=$(awk 'END {print NR-1}' "$GENOTYPE_OUTPUT")

echo "Reproduced candidates with genotype evidence: $GENOTYPE_COUNT"

if [[ "$GENOTYPE_COUNT" -ne 199 ]]; then
    echo "FAIL: Expected 199 genotype-integrated candidates." >&2
    exit 1
fi

if cmp -s "$GENOTYPE_OUTPUT" "$GENOTYPE_EXPECTED"; then
    echo "PASS: Genotype-integrated table matches existing results."
else
    echo "FAIL: Genotype-integrated table differs from existing results." >&2
    exit 1
fi

echo "Stage 3 reproducibility validation: PASS"

# ------------------------------------------------------------
# Stage 4A: Reproduce HIGH-impact sequencing-review flags.
# ------------------------------------------------------------

HIGH_EXPECTED="results/annotation/summary/HG002.high_impact_review.tsv"
HIGH_OUTPUT="$WORKDIR/HG002.high_impact_review.tsv"

[[ -s "$HIGH_EXPECTED" ]] || {
    echo "ERROR: Reference HIGH-impact review table missing." >&2
    exit 1
}

awk -F'\t' '
BEGIN {
    OFS="\t"
    print "CHROM","POS","SYMBOL","Consequence","MAX_AF",
          "CLIN_SIG","GT","DP","GQ","AD","ALT_BALANCE",
          "REVIEW_FLAGS"
}

NR==1 {next}
$6!="HIGH" {next}

{
    flags=""
    dp=$22+0
    n=split($24,a,",")

    if (dp<10)
        flags=flags "LOW_DEPTH;"

    if (n==2 && a[2] ~ /^[0-9]+$/ && a[2]+0<10)
        flags=flags "LOW_ALT_SUPPORT;"

    if ($25!="." && ($25+0<0.30 || $25+0>0.70))
        flags=flags "ALLELE_IMBALANCE;"

    if (n==2 && dp>0 && (a[1]+a[2])/dp<0.5)
        flags=flags "AD_DP_DISCREPANCY;"

    if (flags=="")
        flags="NO_BASIC_FLAGS"

    print $1,$2,$7,$5,$19,$20,$21,$22,$23,$24,$25,flags
}
' "$GENOTYPE_OUTPUT" > "$HIGH_OUTPUT"

HIGH_COUNT=$(awk 'END {print NR-1}' "$HIGH_OUTPUT")

echo "Reproduced HIGH-impact review records: $HIGH_COUNT"

if [[ "$HIGH_COUNT" -ne 14 ]]; then
    echo "FAIL: Expected 14 HIGH-impact review records." >&2
    exit 1
fi

if cmp -s "$HIGH_OUTPUT" "$HIGH_EXPECTED"; then
    echo "PASS: HIGH-impact review table matches existing results."
else
    echo "FAIL: HIGH-impact review table differs." >&2
    exit 1
fi

# ------------------------------------------------------------
# Stage 4B: Reproduce dual-predictor missense review flags.
# ------------------------------------------------------------

MISSENSE_EXPECTED="results/annotation/summary/HG002.rare_missense_both_damaging_review.tsv"
MISSENSE_OUTPUT="$WORKDIR/HG002.rare_missense_both_damaging_review.tsv"

[[ -s "$MISSENSE_EXPECTED" ]] || {
    echo "ERROR: Reference missense review table missing." >&2
    exit 1
}

awk -F'\t' '
BEGIN {
    OFS="\t"
    print "CHROM","POS","SYMBOL","Consequence","SIFT",
          "PolyPhen","MAX_AF","CLIN_SIG","GT","DP","GQ",
          "AD","ALT_BALANCE","REVIEW_FLAGS"
}

NR==1 {next}

$6=="MODERATE" &&
$5 ~ /missense_variant/ &&
tolower($17) ~ /^deleterious/ &&
tolower($18) ~ /^(probably_damaging|possibly_damaging)/ {

    flags=""
    dp=$22
    gt=$21
    gsub(/\|/,"/",gt)

    if (dp=="." || dp=="")
        flags=flags "MISSING_DP;"
    else if (dp+0<10)
        flags=flags "LOW_DEPTH;"

    if ($24 ~ /^[0-9]+,[0-9]+$/) {
        split($24,a,",")

        if (a[2]+0<10)
            flags=flags "LOW_ALT_SUPPORT;"

        if (dp ~ /^[0-9]+$/ && dp+0>0 &&
            (a[1]+a[2])/dp<0.5)
            flags=flags "AD_DP_DISCREPANCY;"
    }
    else {
        flags=flags "MISSING_AD;"
    }

    if (gt=="0/1" || gt=="1/0") {
        if ($25=="." || $25=="")
            flags=flags "MISSING_ALT_BALANCE;"
        else if ($25+0<0.30 || $25+0>0.70)
            flags=flags "ALLELE_IMBALANCE;"
    }

    if (flags=="")
        flags="NO_BASIC_FLAGS"

    print $1,$2,$7,$5,$17,$18,$19,$20,
          $21,$22,$23,$24,$25,flags
}
' "$GENOTYPE_OUTPUT" > "$MISSENSE_OUTPUT"

MISSENSE_COUNT=$(awk 'END {print NR-1}' "$MISSENSE_OUTPUT")

echo "Reproduced dual-predictor missense records: $MISSENSE_COUNT"

if [[ "$MISSENSE_COUNT" -ne 59 ]]; then
    echo "FAIL: Expected 59 missense review records." >&2
    exit 1
fi

if cmp -s "$MISSENSE_OUTPUT" "$MISSENSE_EXPECTED"; then
    echo "PASS: Missense review table matches existing results."
else
    echo "FAIL: Missense review table differs." >&2
    exit 1
fi

echo "Stage 4 reproducibility validation: PASS"

# ------------------------------------------------------------
# Stage 5A: Reproduce strict missense prioritization.
# ------------------------------------------------------------

STRICT_EXPECTED="results/annotation/summary/HG002.rare_missense_strict_review.tsv"
STRICT_OUTPUT="$WORKDIR/HG002.rare_missense_strict_review.tsv"

[[ -s "$STRICT_EXPECTED" ]] || {
    echo "ERROR: Reference strict missense table missing." >&2
    exit 1
}

awk -F'\t' '
BEGIN {OFS="\t"}

NR==1 {
    print
    next
}

$5 ~ /^deleterious\(/ &&
$6 ~ /^probably_damaging\(/ &&
$14=="NO_BASIC_FLAGS" {
    print
}
' "$MISSENSE_OUTPUT" > "$STRICT_OUTPUT"

STRICT_COUNT=$(awk 'END {print NR-1}' "$STRICT_OUTPUT")

echo "Reproduced strict missense candidates: $STRICT_COUNT"

if [[ "$STRICT_COUNT" -ne 25 ]]; then
    echo "FAIL: Expected 25 strict missense candidates." >&2
    exit 1
fi

if cmp -s "$STRICT_OUTPUT" "$STRICT_EXPECTED"; then
    echo "PASS: Strict missense table matches existing results."
else
    echo "FAIL: Strict missense table differs." >&2
    exit 1
fi

# ------------------------------------------------------------
# Stage 5B: Reproduce the final 30-candidate shortlist.
# ------------------------------------------------------------

SHORTLIST_EXPECTED="results/annotation/summary/HG002.shortlist30.tsv"
SHORTLIST_OUTPUT="$WORKDIR/HG002.shortlist30.tsv"
SHORTLIST_KEYS="$WORKDIR/HG002.shortlist30.keys.tsv"

[[ -s "$SHORTLIST_EXPECTED" ]] || {
    echo "ERROR: Reference shortlist missing." >&2
    exit 1
}

# Collect HIGH-impact variants without basic review flags.

awk -F'\t' '
BEGIN {OFS="\t"}

NR>1 && $12=="NO_BASIC_FLAGS" {
    print $1,$2,$3,"HIGH_REVIEW"
}
' "$HIGH_OUTPUT" > "$SHORTLIST_KEYS"

# Add the 25 strict missense candidates.

awk -F'\t' '
BEGIN {OFS="\t"}

NR>1 {
    print $1,$2,$3,"MISSENSE_REVIEW"
}
' "$STRICT_OUTPUT" >> "$SHORTLIST_KEYS"

KEY_COUNT=$(wc -l < "$SHORTLIST_KEYS")

if [[ "$KEY_COUNT" -ne 30 ]]; then
    echo "FAIL: Expected 30 shortlist keys." >&2
    exit 1
fi

# Recover original REF/ALT alleles and genotype evidence.
# The join reproduces the established CHROM/POS/SYMBOL lookup.

awk -F'\t' '
BEGIN {OFS="\t"}

FNR==NR {
    key=$1 FS $2 FS $3
    group[key]=$4
    next
}

FNR==1 {
    print "CHROM","POS","REF","ALT","SYMBOL","Consequence",
          "IMPACT","MAX_AF","CLIN_SIG","GT","DP","GQ",
          "AD","ALT_BALANCE","SHORTLIST_GROUP"
    next
}

{
    key=$1 FS $2 FS $7

    if (key in group)
        print $1,$2,$3,$4,$7,$5,$6,$19,$20,
              $21,$22,$23,$24,$25,group[key]
}
' "$SHORTLIST_KEYS" "$GENOTYPE_OUTPUT" > "$SHORTLIST_OUTPUT"

SHORTLIST_COUNT=$(awk 'END {print NR-1}' "$SHORTLIST_OUTPUT")

echo "Reproduced final shortlist variants: $SHORTLIST_COUNT"

if [[ "$SHORTLIST_COUNT" -ne 30 ]]; then
    echo "FAIL: Expected 30 shortlisted variants." >&2
    exit 1
fi

awk -F'\t' '
NR>1 {count[$15]++}
END {
    print "HIGH-impact shortlist:",count["HIGH_REVIEW"]+0
    print "Strict missense shortlist:",count["MISSENSE_REVIEW"]+0
}
' "$SHORTLIST_OUTPUT"

if cmp -s "$SHORTLIST_OUTPUT" "$SHORTLIST_EXPECTED"; then
    echo "PASS: Final 30-variant shortlist matches existing results."
else
    echo "FAIL: Final shortlist differs from existing results." >&2
    exit 1
fi

echo "Stage 5 reproducibility validation: PASS"

# ------------------------------------------------------------
# Stage 6: Reproduce the GIAB benchmark cross-check.
# ------------------------------------------------------------

RTG_DIR="results/benchmark/rtg/HG002_autosomes"
BENCHMARK_BED="resources/giab/HG002_GRCh38_v5.0q_smvar_AgilentV5.autosomes.benchmark.bed"

GIAB_EXPECTED="results/annotation/summary/HG002.shortlist30_GIAB.final.tsv"

TP_KEYS="$WORKDIR/rtg_TP_alleles.tsv"
FP_KEYS="$WORKDIR/rtg_FP_alleles.tsv"

GIAB_LOOKUP="$WORKDIR/HG002.shortlist30_GIAB.tsv"
GIAB_FINAL="$WORKDIR/HG002.shortlist30_GIAB.final.tsv"
OUTSIDE_KEYS="$WORKDIR/outside_benchmark.keys.tsv"

for file in \
    "$RTG_DIR/tp.vcf.gz" \
    "$RTG_DIR/fp.vcf.gz" \
    "$BENCHMARK_BED" \
    "$GIAB_EXPECTED"
do
    [[ -s "$file" ]] || {
        echo "ERROR: Missing required file: $file" >&2
        exit 1
    }
done

# Extract exact call-side allele representations from RTG.

bcftools query \
    -f '%CHROM\t%POS\t%REF\t%ALT\n' \
    "$RTG_DIR/tp.vcf.gz" > "$TP_KEYS"

bcftools query \
    -f '%CHROM\t%POS\t%REF\t%ALT\n' \
    "$RTG_DIR/fp.vcf.gz" > "$FP_KEYS"

# Reproduce the original exact-allele lookup.

awk -F'\t' '
BEGIN {OFS="\t"}

FILENAME==ARGV[1] {
    tp[$0]=1
    next
}

FILENAME==ARGV[2] {
    fp[$0]=1
    next
}

FNR==1 {
    print $0,"GIAB_RECORD_STATUS"
    next
}

{
    key=$1 FS $2 FS $3 FS $4

    if ((key in tp) && (key in fp))
        status="CHECK_BOTH"
    else if (key in tp)
        status="RTG_TP"
    else if (key in fp)
        status="RTG_FP"
    else
        status="NOT_FOUND_EXACT"

    print $0,status
}
' "$TP_KEYS" "$FP_KEYS" "$SHORTLIST_OUTPUT" \
> "$GIAB_LOOKUP"

# For unmatched alleles, check whether the complete REF
# span has any overlap with the 0-based benchmark BED.
# No overlap means outside the benchmark.
# Partial overlap remains unresolved.

awk -F'\t' '
BEGIN {OFS="\t"}

FNR==NR {
    if (FNR>1 && $16=="NOT_FOUND_EXACT") {
        key=$1 FS $2 FS $3 FS $4

        chrom[key]=$1
        start[key]=$2-1
        end[key]=start[key]+length($3)
    }
    next
}

{
    for (key in start) {
        if ($1==chrom[key] &&
            $2<end[key] &&
            $3>start[key])
            overlap[key]=1
    }
}

END {
    for (key in start)
        if (!(key in overlap))
            print key
}
' "$GIAB_LOOKUP" "$BENCHMARK_BED" \
> "$OUTSIDE_KEYS"

# Add the benchmark-region interpretation.

awk -F'\t' '
BEGIN {OFS="\t"}

FILENAME==ARGV[1] {
    outside[$0]=1
    next
}

FNR==1 {
    print $0,"GIAB_INTERPRETATION"
    next
}

{
    key=$1 FS $2 FS $3 FS $4

    if ($16=="RTG_TP")
        status="TP_MATCH_IN_BENCHMARK"
    else if ($16=="NOT_FOUND_EXACT" && (key in outside))
        status="OUTSIDE_BENCHMARK"
    else
        status="REQUIRES_REVIEW"

    print $0,status
}
' "$OUTSIDE_KEYS" "$GIAB_LOOKUP" \
> "$GIAB_FINAL"

# Validate the reconstructed final report.

GIAB_COUNT=$(awk 'END {print NR-1}' "$GIAB_FINAL")

echo "Reproduced GIAB shortlist records: $GIAB_COUNT"

if [[ "$GIAB_COUNT" -ne 30 ]]; then
    echo "FAIL: Expected 30 GIAB shortlist records." >&2
    exit 1
fi

awk -F'\t' '
NR>1 {count[$17]++}
END {
    print "RTG true-positive matches:",
          count["TP_MATCH_IN_BENCHMARK"]+0
    print "Outside benchmark:",
          count["OUTSIDE_BENCHMARK"]+0
    print "Requiring review:",
          count["REQUIRES_REVIEW"]+0
}
' "$GIAB_FINAL"

if cmp -s "$GIAB_FINAL" "$GIAB_EXPECTED"; then
    echo "PASS: GIAB final report matches existing results."
else
    echo "FAIL: GIAB final report differs." >&2
    echo "Existing reference outputs were not modified." >&2
    exit 1
fi

echo "Stage 6 reproducibility validation: PASS"
