# Project Design

## Project objective

Build a reproducible germline whole-exome sequencing (WES) pipeline for small-variant discovery, quality control, annotation, and benchmarking.

## Development strategy

The project follows a Build → Validate → Apply strategy:

1. Build the germline WES workflow manually to understand each analysis step.
2. Validate variant-calling performance using Genome in a Bottle (GIAB) benchmark data.
3. Convert the validated workflow into a reproducible Nextflow DSL2 pipeline.
4. Apply the workflow to an independent disease-focused WES dataset.

## Initial benchmark sample

- Sample: HG002
- Isolate: NA24385
- Sex: male
- Assay: whole-exome sequencing
- Role: benchmark sample

## Analysis workflow

FASTQ
→ raw-read QC
→ alignment to the reference genome
→ BAM processing and QC
→ duplicate marking
→ base quality score recalibration
→ germline variant calling
→ variant filtering and QC
→ GIAB benchmarking
→ variant annotation and prioritization

## Reference genome

The HG002 analysis used the Broad GRCh38 reference. The known-sites resources, Agilent V5 capture intervals, and GIAB benchmark files are recorded in `docs/resources.md`.

## Benchmarking principle

HG002 variant calls were benchmarked against GIAB v5.0q on GRCh38. The evaluation used the intersection of GIAB confident regions, Agilent V5 targets, and autosomes.

The benchmarking method and results are recorded in `docs/benchmarking.md`.

## Reproducibility

Software versions, reference resources, commands, parameters, QC metrics, and workflow decisions are recorded in the project.

The HG002 analysis was completed manually. The processing steps were subsequently implemented as a 13-process Nextflow DSL2 workflow and tested using synthetic data. The complete Nextflow workflow has not been rerun on the original HG002 reads.
