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

## WES capture design

Benchmark sample HG002 (NA24385; SRR2962669) was generated using the Agilent SureSelect Human All Exon V5 capture design.

Design identifier: S04380110

Source used for hg38 intervals:
UCSC hg38 exomeProbesets archive.

Downloaded resources:

- S04380110_Covered.bb
- S04380110_Regions.bb

Both BigBed files were converted to BED using the UCSC `bigBedToBed` utility.

The resulting BED files were byte-identical:

- 230,719 intervals
- 50,446,305 bp total target territory
- 50.45 Mb unique merged footprint
- chromosomes: chr1-chr22, chrX, chrY

SHA256 of both BED files:

5c03072ed0583b22847bb5e0df4e725c05f32953a4bd53f1b30e6dbbb6d29342

The BED was converted to a Picard/GATK interval list using the Broad GRCh38 sequence dictionary:

S04380110_Regions.interval_list

The resulting interval list contains 230,719 intervals spanning 50,446,305 bases.
