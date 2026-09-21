# Genomic Resources

## Reference genome

Primary reference build: GRCh38

The pipeline will use a GRCh38 reference from the Broad/GATK resource ecosystem.

The exact FASTA filename, source URL, checksum, and associated index files will be recorded after download.

## Reference indexes

The reference FASTA will require:

- BWA index files for read alignment
- FASTA `.fai` index for random sequence access
- sequence dictionary (`.dict`) for GATK/Picard

## BQSR known-sites resources

GRCh38-compatible known-variant resources will be used for GATK Base Quality Score Recalibration (BQSR).

Planned resources include:

- dbSNP
- Mills and 1000 Genomes gold-standard indels
- Broad/GATK known indels

Exact filenames and versions will be recorded before BQSR.

## WES target intervals

Capture-kit-specific target intervals will be used for WES coverage assessment and appropriate region-restricted analyses.

The interval resource must correspond to the sequencing library's actual exome capture design and be compatible with the selected GRCh38 reference.

## GIAB benchmark resources

HG002 will be used for pipeline benchmarking.

Benchmarking requires:

- an HG002 benchmark/truth VCF
- corresponding benchmark-region BED
- compatible reference genome
- appropriate handling of the WES target region

The exact GIAB benchmark release will be selected and documented before benchmarking.

## Compatibility requirement

Reference FASTA, known-sites VCFs, capture intervals, and benchmarking resources must use compatible genome coordinates and contig naming conventions.
