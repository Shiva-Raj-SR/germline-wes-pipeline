# Germline WES Pipeline

A reproducible germline whole-exome sequencing (WES) analysis pipeline for variant discovery, annotation and benchmarking.

## Project status

**Completed — initial implementation and HG002 analysis.**

## Nextflow WES workflow

The germline WES workflow is implemented in Nextflow DSL2:

`workflows/wes_fastq_to_pass.nf`

The workflow processes paired-end FASTQ reads through:

1. Raw-read quality control with FastQC
2. BWA-MEM alignment and BAM sorting
3. Duplicate marking with Picard
4. Hybrid-selection coverage assessment
5. Base quality score recalibration with GATK
6. Germline variant calling with HaplotypeCaller
7. Genotyping with GenotypeGVCFs
8. Variant normalization using bcftools
9. SNP and indel selection and hard filtering
10. Combination of filtered variants and extraction of PASS calls

The workflow contains 13 Nextflow processes, including independent
quality-control branches. The current workflow processes one sample per run.

### Validation status

The complete workflow was tested using a small synthetic paired-end
FASTQ dataset. All 13 processes completed with real bioinformatics
tools. The test produced an indexed raw VCF with no variant records,
and both final VCF outputs passed integrity checks.

The downstream variant-processing workflow was also tested separately
using 14 synthetic variants. All 14 records were retained in the
combined filtered VCF, and 2 records passed the filtering criteria.

The complete 13-process Nextflow workflow was subsequently run on
the original HG002 WES dataset (SRR2962669). It produced 44,291 PASS
records, compared with 44,289 from the manual analysis. All 44,289
manual PASS alleles and genotype strings matched.

Independent GIAB v5.0q benchmarking produced identical precision
(97.38%), sensitivity (95.83%), and F-measure (96.60%).
See `docs/benchmarking.md` for details and limitations.

### Software and reference resources

The validated environment uses Nextflow 26.04.6, GATK 4.6.2.0,
BWA 0.7.19, samtools 1.24, bcftools 1.24, Picard 2.20.4, and
FastQC 0.12.1.

The Conda package specification is recorded in
`envs/germline-wes-explicit.txt`. The Nextflow environment location
can be configured with `--wes_conda_env`.

The HG002 analysis uses the Broad GRCh38 reference and the Agilent
SureSelect Human All Exon V5 capture design. The reference, sequence
dictionary, known-sites VCF headers, and capture/calling intervals
passed the reference compatibility checks.

See `docs/resources.md` for the reference and benchmark resources.

### Running the workflow

The workflow requires a sample ID, paired FASTQ files, a BWA-indexed
reference, GATK reference files, three indexed BQSR known-sites
resources, capture intervals, and calling intervals.

The sample ID must start with a letter or number and can contain
letters, numbers, underscores, hyphens, and dots.

Run the integrated WES workflow from the repository root with
`nextflow run .`. The separate HG002 prioritization verification
workflow is in `workflows/hg002_prioritization_verification.nf`.

For runs with output publishing enabled, supply an absolute `--outdir`
path pointing to a new or empty directory. The workflow rejects
missing inputs, incompatible reference metadata, and nonempty output
directories before processing.

The publishing configuration is `conf/publish_outputs.config`.

### Example command

Run the workflow from the repository root. Replace the sample ID,
FASTQ paths, and output directory with the files for the analysis.

    nextflow run . \
      -c nextflow.config \
      -c conf/publish_outputs.config \
      --sample_id SAMPLE_ID \
      --r1 /path/to/SAMPLE_R1.fastq.gz \
      --r2 /path/to/SAMPLE_R2.fastq.gz \
      --reference_name Homo_sapiens_assembly38.fasta \
      --bwa_ref_dir "$PWD/resources/reference" \
      --gatk_ref_dir "$PWD/resources/reference" \
      --known_sites_dir "$PWD/resources/known_sites" \
      --capture_intervals "$PWD/resources/intervals/S04380110_Regions.interval_list" \
      --calling_intervals "$PWD/resources/intervals/S04380110_Regions.autosomes.interval_list" \
      --outdir "$PWD/results/SAMPLE_ID_run01" \
      -ansi-log false

The output directory must be new or empty. The capture intervals
must match the sequencing library used for the sample.

Published results include:

- Combined filtered VCF and Tabix index
- PASS VCF and Tabix index
- FastQC HTML and ZIP reports
- Picard duplicate metrics
- Hybrid-selection coverage metrics

Intermediate BAM files are retained in the Nextflow work directory
but are not copied to the published results directory.

The current FASTQ-to-PASS workflow covers variant discovery and
hard filtering. GIAB benchmarking, VEP annotation, and variant
prioritization are documented separately and are not part of this
13-process workflow.

## HG002 variant prioritization

Generate exploratory tables from existing VEP and RTG outputs with
`scripts/produce_hg002_prioritization.sh --out-dir NEW_DIRECTORY`.
The validated six-stage regression harness remains
`scripts/prioritize_hg002_vep.sh`.

See [inputs, thresholds, limitations, outputs, and commands](docs/annotation_prioritization.md#independent-prioritization-producer)
and [development validation results](docs/prioritization_refactor_validation.md).
