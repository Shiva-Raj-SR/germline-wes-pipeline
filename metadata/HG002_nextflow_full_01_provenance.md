# HG002 full-scale Nextflow execution provenance

## Execution

- Sample: HG002 / NA24385
- Sequencing accession: SRR2962669
- Execution date: 2026-10-10
- Nextflow version: 26.04.6
- Workflow: workflows/wes_fastq_to_pass.nf
- Run name: agitated_carson
- Run ID: 30ddfe1b-607a-42de-8b89-69b434a38c75
- Status: OK
- Duration: 4h 34m 59s
- Git revision: b80f42d86d8aa66152bf4904785857dfd8c9001f
- Nextflow revision: 23eb35795bf508c2c7e5f11c368e053f

## Inputs and configuration

- Read 1: data/raw/SRR2962669_1.fastq.gz
- Read 2: data/raw/SRR2962669_2.fastq.gz
- Reference: resources/reference/Homo_sapiens_assembly38.fasta
- Known sites: resources/known_sites/
- Capture intervals: resources/intervals/S04380110_Regions.interval_list
- Calling intervals: resources/intervals/S04380110_Regions.autosomes.interval_list
- Additional configuration: conf/publish_outputs.config
- Execution concurrency: -qs 1
- Nextflow work directory: ~/.nextflow-work/hg002

## Outputs and validation

- Published results: results/nextflow_hg002_full_01/
- GIAB evaluation: results/benchmark/rtg/HG002_autosomes_nextflow_full_01/
- Output checksum manifest: metadata/HG002_nextflow_full_01_outputs.sha256
- PASS records: 44,291
- Shared manual and Nextflow PASS alleles: 44,289
- Exact genotype matches among shared alleles: 44,289
- GIAB precision: 97.38%
- GIAB sensitivity: 95.83%
- GIAB F-measure: 96.60%

GIAB benchmarking used RTG vcfeval 3.13, the HG002 v5.0q
truth set, and the 47,405,929 bp autosomal Agilent V5
evaluation territory. Both benchmark runs reported 5,390
problematic baseline variants skipped during loading.

See docs/benchmarking.md for concordance details, the two
additional Nextflow PASS SNPs, and interpretation limits.

## Original execution command

The original command used machine-specific absolute paths.

```bash
nextflow run . -qs 1 -c conf/publish_outputs.config --sample_id HG002 --r1 /home/shiva/bioinformatics_projects/germline-wes-pipeline/data/raw/SRR2962669_1.fastq.gz --r2 /home/shiva/bioinformatics_projects/germline-wes-pipeline/data/raw/SRR2962669_2.fastq.gz --reference_name Homo_sapiens_assembly38.fasta --bwa_ref_dir /home/shiva/bioinformatics_projects/germline-wes-pipeline/resources/reference --gatk_ref_dir /home/shiva/bioinformatics_projects/germline-wes-pipeline/resources/reference --known_sites_dir /home/shiva/bioinformatics_projects/germline-wes-pipeline/resources/known_sites --capture_intervals /home/shiva/bioinformatics_projects/germline-wes-pipeline/resources/intervals/S04380110_Regions.interval_list --calling_intervals /home/shiva/bioinformatics_projects/germline-wes-pipeline/resources/intervals/S04380110_Regions.autosomes.interval_list --outdir /home/shiva/bioinformatics_projects/germline-wes-pipeline/results/nextflow_hg002_full_01 -ansi-log false
```
