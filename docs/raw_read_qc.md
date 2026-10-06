# HG002 Raw Read Quality Control

## Input

- Sample: HG002
- Run: SRR2962669
- Layout: paired-end
- Read pairs: 75,193,388
- Observed read length: 126 bp
- Total sequence: approximately 18.8 Gbp
- GC content: 48% for both mates

## Data integrity

ENA MD5 checksums were reproduced exactly for both FASTQ files.

Both compressed FASTQ files passed `gzip -t` integrity testing.

## FastQC

Both R1 and R2 passed:

- Basic Statistics
- Per base sequence quality
- Per sequence quality scores
- Per base sequence content
- Per base N content
- Sequence Length Distribution
- Sequence Duplication Levels
- Overrepresented sequences
- Adapter Content

Both mates failed the FastQC Per Sequence GC Content module.

Because this is targeted whole-exome sequencing and all major read-quality,
adapter, duplication, and contamination-sensitive FastQC modules otherwise
passed, the GC-content deviation is interpreted as compatible with
capture-enrichment bias rather than evidence requiring trimming.

## Pre-alignment decision

No adapter or quality trimming will be performed.

The verified raw paired-end FASTQ files will be aligned directly to the
Broad/GATK GRCh38 reference using BWA-MEM.

