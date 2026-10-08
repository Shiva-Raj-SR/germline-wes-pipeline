#!/usr/bin/env bash
set -euo pipefail

# Independent HG002 producer. No reference output tables are read.
# Filtering expressions deliberately preserve the 1526f93 baseline.
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INPUT="$PROJECT_ROOT/results/annotation/vep/HG002.autosomes.PASS.vep.analysis.vcf.gz"
RTG_DIR="$PROJECT_ROOT/results/benchmark/rtg/HG002_autosomes"
BENCHMARK_BED="$PROJECT_ROOT/resources/giab/HG002_GRCh38_v5.0q_smvar_AgilentV5.autosomes.benchmark.bed"
WORKDIR=""

usage() {
    cat <<'USAGE'
Usage: produce_hg002_prioritization.sh --out-dir NEW_DIRECTORY
       [--input ANNOTATED_VCF] [--rtg-dir EXISTING_RTG_DIRECTORY]
       [--benchmark-bed EXISTING_BED]

Defaults are HG002 paths under this script's repository.
The output directory must not exist. Outputs and small intermediates are retained.
Only extracts existing VEP and RTG annotations; no upstream analysis is run.
See docs/annotation_prioritization.md for thresholds and limitations.
USAGE
}
fail() { echo "ERROR: $*" >&2; exit 1; }
while (($#)); do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --out-dir|--input|--rtg-dir|--benchmark-bed)
            (($#>=2)) || fail "Missing value for $1"
            [[ -n "$2" && "$2" != --* ]] || fail "Missing value for $1"
            case "$1" in
                --out-dir) WORKDIR="$2" ;;
                --input) INPUT="$2" ;;
                --rtg-dir) RTG_DIR="$2" ;;
                --benchmark-bed) BENCHMARK_BED="$2" ;;
            esac
            shift 2 ;;
        *) fail "Unknown argument: $1" ;;
    esac
done
[[ -n "$WORKDIR" ]] || fail "--out-dir is required"
for tool in bcftools awk cut wc mkdir sha256sum; do
    command -v "$tool" >/dev/null || fail "$tool is required"
done
for file in "$INPUT" "$RTG_DIR/tp.vcf.gz" "$RTG_DIR/fp.vcf.gz" "$BENCHMARK_BED"; do
    [[ -s "$file" ]] || fail "Missing or empty input: $file"
done
# Explicitly single-sample; the legacy genotype schema holds one GT/DP/GQ/AD.
SAMPLES=$(bcftools query -l "$INPUT")
[[ -n "$SAMPLES" && "$SAMPLES" != *$'\n'* ]] || fail "Exactly one VCF sample is required"
[[ ! -e "$WORKDIR" && ! -L "$WORKDIR" ]] || fail "Output directory already exists: $WORKDIR"
mkdir -- "$WORKDIR"
{
    printf 'producer=produce_hg002_prioritization.sh\nsample=%s\n' "$SAMPLES"
    bcftools --version
    printf 'Producer and input SHA256 checksums:\n'
    sha256sum -- "$0" "$INPUT" "$RTG_DIR/tp.vcf.gz" "$RTG_DIR/fp.vcf.gz" "$BENCHMARK_BED"
} > "$WORKDIR/run_manifest.txt"

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

# Fail on ambiguous PICK rows rather than merge transcript identities.
awk -F'\t' 'NR>1 {
    key=$1 FS $2 FS $3 FS $4
    if (NF!=20 || $4 ~ /,/ || $4=="*" || seen[key]++) {
        print "ERROR: Unsupported or duplicate PICK allele: " key > "/dev/stderr"
        exit 1
    }
}' "$OUTPUT"

COUNT=$(awk 'END {print NR-1}' "$OUTPUT")

echo "Generated PICK records: $COUNT"


echo "Stage 1 production complete"

# ------------------------------------------------------------
# Stage 2: Generate rare HIGH/MODERATE candidate selection.
# ------------------------------------------------------------

RARE_OUTPUT="$WORKDIR/HG002.rare_protein_altering.tsv"

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

echo "Generated rare HIGH/MODERATE candidates: $RARE_COUNT"

awk -F'\t' '
NR>1 {count[$6]++}
END {
    print "HIGH-impact:", count["HIGH"]+0
    print "MODERATE-impact:", count["MODERATE"]+0
}
' "$RARE_OUTPUT"

echo "Stage 2 production complete"

# ------------------------------------------------------------
# Stage 3: Generate genotype integration and allele balance.
# ------------------------------------------------------------

GENOTYPES="$WORKDIR/HG002.genotypes.tsv"
GENOTYPE_OUTPUT="$WORKDIR/HG002.rare_candidates_with_genotypes.tsv"


# Extract genotype evidence directly from the annotated VCF.

bcftools query \
    -f '%CHROM\t%POS\t%REF\t%ALT[\t%GT\t%DP\t%GQ\t%AD]\n' \
    "$INPUT" > "$GENOTYPES"

# Join using the exact CHROM, POS, REF, ALT allele identity.

awk -F'\t' '
BEGIN {OFS="\t"}

FILENAME==ARGV[1] {
    key=$1 FS $2 FS $3 FS $4
    if (NF!=8 || $4 ~ /,/ || $4=="*" || key in gt) {
        print "ERROR: Unsupported or duplicate genotype allele: " key > "/dev/stderr"
        exit 1
    }
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
        exit 1
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

[[ "$GENOTYPE_COUNT" -eq "$RARE_COUNT" ]] || fail "Genotype join lost candidate rows"
echo "Generated candidates with genotype evidence: $GENOTYPE_COUNT"


echo "Stage 3 production complete"

# ------------------------------------------------------------
# Stage 4A: Generate HIGH-impact sequencing-review flags.
# ------------------------------------------------------------

HIGH_OUTPUT="$WORKDIR/HG002.high_impact_review.tsv"
HIGH_ALLELES="$WORKDIR/HG002.high_impact_review.alleles.tsv"

awk -F'\t' '
BEGIN {
    OFS="\t"
    print "CHROM","POS","SYMBOL","Consequence","MAX_AF",
          "CLIN_SIG","GT","DP","GQ","AD","ALT_BALANCE",
          "REVIEW_FLAGS","REF","ALT"
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

    print $1,$2,$7,$5,$19,$20,$21,$22,$23,$24,$25,flags,$3,$4
}
' "$GENOTYPE_OUTPUT" > "$HIGH_ALLELES"
cut -f1-12 "$HIGH_ALLELES" > "$HIGH_OUTPUT"

HIGH_COUNT=$(awk 'END {print NR-1}' "$HIGH_OUTPUT")

echo "Generated HIGH-impact review records: $HIGH_COUNT"


# ------------------------------------------------------------
# Stage 4B: Generate dual-predictor missense review flags.
# ------------------------------------------------------------

MISSENSE_OUTPUT="$WORKDIR/HG002.rare_missense_both_damaging_review.tsv"
MISSENSE_ALLELES="$WORKDIR/HG002.rare_missense_both_damaging_review.alleles.tsv"

awk -F'\t' '
BEGIN {
    OFS="\t"
    print "CHROM","POS","SYMBOL","Consequence","SIFT",
          "PolyPhen","MAX_AF","CLIN_SIG","GT","DP","GQ",
          "AD","ALT_BALANCE","REVIEW_FLAGS","REF","ALT"
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
          $21,$22,$23,$24,$25,flags,$3,$4
}
' "$GENOTYPE_OUTPUT" > "$MISSENSE_ALLELES"
cut -f1-14 "$MISSENSE_ALLELES" > "$MISSENSE_OUTPUT"

MISSENSE_COUNT=$(awk 'END {print NR-1}' "$MISSENSE_OUTPUT")

echo "Generated dual-predictor missense records: $MISSENSE_COUNT"


echo "Stage 4 production complete"

# ------------------------------------------------------------
# Stage 5A: Generate strict missense prioritization.
# ------------------------------------------------------------

STRICT_OUTPUT="$WORKDIR/HG002.rare_missense_strict_review.tsv"
STRICT_ALLELES="$WORKDIR/HG002.rare_missense_strict_review.alleles.tsv"

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
' "$MISSENSE_ALLELES" > "$STRICT_ALLELES"
cut -f1-14 "$STRICT_ALLELES" > "$STRICT_OUTPUT"

STRICT_COUNT=$(awk 'END {print NR-1}' "$STRICT_OUTPUT")

echo "Generated strict missense candidates: $STRICT_COUNT"


# ------------------------------------------------------------
# Stage 5B: Generate the shortlist (legacy HG002 filename, variable row count).
# ------------------------------------------------------------

SHORTLIST_OUTPUT="$WORKDIR/HG002.shortlist30.tsv"
SHORTLIST_KEYS="$WORKDIR/HG002.shortlist30.keys.tsv"

# Collect HIGH-impact variants without basic review flags.

awk -F'\t' '
BEGIN {OFS="\t"}

NR>1 && $12=="NO_BASIC_FLAGS" {
    print $1,$2,$13,$14,"HIGH_REVIEW"
}
' "$HIGH_ALLELES" > "$SHORTLIST_KEYS"

# Add strict missense candidates; no HG002 counts are required.

awk -F'\t' '
BEGIN {OFS="\t"}

NR>1 {
    print $1,$2,$15,$16,"MISSENSE_REVIEW"
}
' "$STRICT_ALLELES" >> "$SHORTLIST_KEYS"

KEY_COUNT=$(wc -l < "$SHORTLIST_KEYS")

# Recover original REF/ALT alleles and genotype evidence.
# All joins use exact CHROM/POS/REF/ALT, never position or gene alone.

awk -F'\t' '
BEGIN {OFS="\t"}

FILENAME==ARGV[1] {
    key=$1 FS $2 FS $3 FS $4
    group[key]=$5
    next
}

FNR==1 {
    print "CHROM","POS","REF","ALT","SYMBOL","Consequence",
          "IMPACT","MAX_AF","CLIN_SIG","GT","DP","GQ",
          "AD","ALT_BALANCE","SHORTLIST_GROUP"
    next
}

{
    key=$1 FS $2 FS $3 FS $4

    if (key in group)
        print $1,$2,$3,$4,$7,$5,$6,$19,$20,
              $21,$22,$23,$24,$25,group[key]
}
' "$SHORTLIST_KEYS" "$GENOTYPE_OUTPUT" > "$SHORTLIST_OUTPUT"

SHORTLIST_COUNT=$(awk 'END {print NR-1}' "$SHORTLIST_OUTPUT")

[[ "$SHORTLIST_COUNT" -eq "$KEY_COUNT" ]] || fail "Shortlist allele join changed candidate count"
echo "Generated final shortlist variants: $SHORTLIST_COUNT"

awk -F'\t' '
NR>1 {count[$15]++}
END {
    print "HIGH-impact shortlist:",count["HIGH_REVIEW"]+0
    print "Strict missense shortlist:",count["MISSENSE_REVIEW"]+0
}
' "$SHORTLIST_OUTPUT"

echo "Stage 5 production complete"

# ------------------------------------------------------------
# Stage 6: Generate the GIAB benchmark cross-check.
# ------------------------------------------------------------


TP_KEYS="$WORKDIR/rtg_TP_alleles.tsv"
FP_KEYS="$WORKDIR/rtg_FP_alleles.tsv"

GIAB_LOOKUP="$WORKDIR/HG002.shortlist30_GIAB.tsv"
GIAB_FINAL="$WORKDIR/HG002.shortlist30_GIAB.final.tsv"
OUTSIDE_KEYS="$WORKDIR/outside_benchmark.keys.tsv"

for file in \
    "$RTG_DIR/tp.vcf.gz" \
    "$RTG_DIR/fp.vcf.gz" \
    "$BENCHMARK_BED"
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

FILENAME==ARGV[1] {
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

# Report the generated final report.

GIAB_COUNT=$(awk 'END {print NR-1}' "$GIAB_FINAL")

[[ "$GIAB_COUNT" -eq "$SHORTLIST_COUNT" ]] || fail "GIAB join changed shortlist count"
echo "Generated GIAB shortlist records: $GIAB_COUNT"

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

echo "Stage 6 production complete"

printf "Production complete. Outputs retained in: %s\n" "$WORKDIR"
printf "status=COMPLETE\n" >> "$WORKDIR/run_manifest.txt"
