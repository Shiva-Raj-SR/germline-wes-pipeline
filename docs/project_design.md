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

## Planned analysis

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

GRCh38 will be used for the primary analysis.

Exact reference FASTA, known-sites resources, capture intervals, and benchmark resources will be documented before analysis.

## Benchmarking principle

Variant calls generated from HG002 WES data will be compared against an appropriate GIAB HG002 truth set.

Benchmark evaluation must be restricted to genomic regions where comparison is scientifically valid. The exact benchmark release, confident regions, reference build, and WES target-region handling will be documented before benchmarking.

## Reproducibility

Software versions, reference resources, commands, parameters, intermediate QC metrics, and workflow decisions will be recorded throughout the project.

The workflow will first be executed manually and subsequently implemented using Nextflow DSL2.
