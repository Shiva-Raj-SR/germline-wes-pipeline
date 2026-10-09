# Genomic Resources

## Reference genome

Primary reference build: GRCh38

The HG002 analysis used the Broad/GATK GRCh38 reference:

`resources/reference/Homo_sapiens_assembly38.fasta`

The FASTA index, sequence dictionary, and BWA-MEM index files are stored in the same directory.

The FASTA index and sequence dictionary contain 3,366 contigs with matching names, lengths, and order. The reference metadata also passed compatibility checks against the known-sites VCFs and Agilent V5 interval lists.

The original download URL and FASTA checksum still need to be recorded after verification.

## Reference indexes

The reference FASTA has the following index and dictionary files:

- BWA index files for read alignment
- FASTA `.fai` index for random sequence access
- sequence dictionary (`.dict`) for GATK/Picard

## BQSR known-sites resources

The HG002 analysis used three GRCh38-compatible known-sites resources for GATK Base Quality Score Recalibration (BQSR).

The files are stored in `resources/known_sites/`:

- `Homo_sapiens_assembly38.dbsnp138.vcf`
- `Homo_sapiens_assembly38.known_indels.vcf.gz`
- `Mills_and_1000G_gold_standard.indels.hg38.vcf.gz`

The dbSNP VCF has a `.idx` index. Both compressed indel VCFs have `.tbi` indexes.

The three VCF headers were checked against the Broad GRCh38 reference. All declared 3,366 contigs matched the reference names and lengths.

## WES target intervals

The HG002 dataset was generated using the Agilent SureSelect Human All Exon V5 capture design (S04380110).

The project uses two GRCh38 interval lists:

- `resources/intervals/S04380110_Regions.interval_list` contains 230,719 intervals for hybrid-selection coverage assessment.
- `resources/intervals/S04380110_Regions.autosomes.interval_list` contains 222,043 intervals for autosome-restricted variant calling.

Both interval lists passed the GRCh38 reference compatibility check.

For another WES dataset, the capture intervals must match the library preparation used for that sample.

## GIAB benchmark resources

The HG002 variant calls were benchmarked against GIAB v5.0q on GRCh38.

The analysis used the GIAB truth VCF and benchmark-region BED. The WES benchmark region was derived by intersecting GIAB benchmark regions with Agilent V5 targets. Variant calling used an autosome-restricted interval list.

The resource files and target-region statistics are recorded below. The benchmarking methods and results are documented in `docs/benchmarking.md`.

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
