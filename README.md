# Germline WES Pipeline

A reproducible germline whole-exome sequencing (WES) analysis pipeline for variant discovery, annotation and benchmarking.

## Project status

In development.

## HG002 variant prioritization

Generate exploratory tables from existing VEP and RTG outputs with
`scripts/produce_hg002_prioritization.sh --out-dir NEW_DIRECTORY`.
The validated six-stage regression harness remains
`scripts/prioritize_hg002_vep.sh`.

See [inputs, thresholds, limitations, outputs, and commands](docs/annotation_prioritization.md#independent-prioritization-producer)
and [development validation results](docs/prioritization_refactor_validation.md).
