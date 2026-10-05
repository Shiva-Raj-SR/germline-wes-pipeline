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

## GIAB HG002 benchmark

Primary benchmark:

- Sample: HG002
- GIAB release: v5.0q
- Reference build: GRCh38
- Benchmark type: small variants
- Truth VCF: HG002_GRCh38_v5.0q_smvar.vcf.gz
- Benchmark regions: HG002_GRCh38_v5.0q_smvar.benchmark.bed

GIAB v5.0q is an assembly-based benchmark. The VCF and benchmark BED are used together.

For WES benchmarking, the GIAB benchmark regions were intersected with the Agilent SureSelect Human All Exon V5 target intervals.

Derived WES benchmark region:

HG002_GRCh38_v5.0q_smvar_AgilentV5.benchmark.bed

Statistics:

- Agilent V5 target territory: 50,446,305 bp
- WES benchmark territory: 49,216,825 bp
- Benchmarkable target fraction: 97.56%
- Benchmark intervals: 224,081
- GIAB truth VCF records within this territory: 43,199

SHA256:

b5032c31e4611c5b6d488e6342a24d66999394550d8f3a8e5160218f81d4f7e0
