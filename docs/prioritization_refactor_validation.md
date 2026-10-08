# HG002 prioritization producer development validation

Date: 2026-10-08 (Asia/Calcutta).

Repository: `/home/shiva/bioinformatics_projects/germline-wes-pipeline`.
Baseline and current HEAD: `1526f93`.
Verified local host: `MahaaKaala`; WSL kernel:
`6.6.114.1-microsoft-standard-WSL2`.
All repository changes were made directly in WSL.

## Changes for review

- Added executable `scripts/produce_hg002_prioritization.sh`, an independent
  producer reading existing VEP/RTG/BED inputs and requiring a new output directory.
- Preserved all filtering expressions and the original historical table layouts.
  Three allele-aware review companions carry REF/ALT into exact-allele shortlist
  selection. The key intermediate intentionally changes to CHROM/POS/REF/ALT/GROUP.
- Added `tests/test_prioritization_producer.py` with seven synthetic end-to-end
  test methods. Each test uses a standalone producer copy without reference tables.
- Expanded `docs/annotation_prioritization.md` with inputs, outputs, software,
  thresholds, branch-specific limitations, storage, and execution commands.
- Added README links and this validation report.
- Left `scripts/prioritize_hg002_vep.sh` byte identical to its Git baseline.
  No Git commit was created.

## Final validation

| Check | Result |
|---|---|
| Bash syntax, existing and new scripts | PASS |
| Python syntax parsing | PASS |
| Seven synthetic test methods (including parameterized cases) | PASS |
| Unchanged historical six-stage regression harness | All six stages PASS |
| Final producer run; initial run launched from /tmp | PASS |
| Nine generated-versus-existing table comparisons | All byte identical |
| Tracked-file and new-file whitespace checks | PASS |
| Protected baseline/result/Conda-backup SHA256 checks | All unchanged |

ShellCheck was not installed and was not downloaded. Syntax, synthetic
end-to-end checks, exact HG002 comparisons, and the original regression harness
were used for this development stage.

Tool versions:

- GNU bash, version 5.3.9(1)-release (x86_64-pc-linux-gnu)
- Python 3.12.3
- bcftools 1.21

## Table comparison

| Table | Rows | Result |
|---|---:|---|
| `HG002.vep.PICK.tsv` | 44,253 | Byte identical |
| `HG002.rare_protein_altering.tsv` | 199 | Byte identical |
| `HG002.rare_candidates_with_genotypes.tsv` | 199 | Byte identical |
| `HG002.high_impact_review.tsv` | 14 | Byte identical |
| `HG002.rare_missense_both_damaging_review.tsv` | 59 | Byte identical |
| `HG002.rare_missense_strict_review.tsv` | 25 | Byte identical |
| `HG002.shortlist30.tsv` | 30 | Byte identical |
| `HG002.shortlist30_GIAB.tsv` | 30 | Byte identical |
| `HG002.shortlist30_GIAB.final.tsv` | 30 | Byte identical |

No differences were found in the nine comparable result tables.
The new companion tables, exact-allele key intermediate, and manifest are
intentional additions/schema changes. HG002 contains no case where replacing
the historical CHROM/POS/SYMBOL shortlist join changes its validated output;
synthetic same-position collisions demonstrate why the exact allele join matters.

The final shortlist remains 5 HIGH-impact + 25 strict missense candidates.
GIAB interpretation remains 29 exact RTG TP matches, 1 outside benchmark, and
0 requiring review. The out-of-region FLG2 record retains the validated
interpretation; there was no rerun of RTG benchmarking.

One initial synthetic multiallelic fixture used a comma inside the CSQ Allele
field, which made that fixture malformed. The fixture was corrected to use a
valid annotation token; the final suite confirms multiallelic records are
rejected. Production filtering criteria were not changed to resolve this test.

## Retained evidence and safety

Final generated output directory:

`/tmp/hg002-prioritization-validation-hjo3ahqt/generated-final`

Evidence directory:

`/tmp/hg002-prioritization-validation-hjo3ahqt`

It contains `producer-final.log`, `baseline-regression.log`,
`synthetic-final.log`, `syntax.log`, `diff-check.log`,
`protected_before.json`, and `validation.json`. The JSON report records
generated-table SHA256 values, counts, tool versions, and checks. The final
output manifest records producer/input hashes and ends with `status=COMPLETE`.
An initial successful generated directory is also retained. These /tmp files
are temporary and may not survive WSL restart; this repository report and the
documented commands preserve the validation summary and reproduction procedure.

The final generated directory contains 11,338,226 bytes (about 11 MB).

SHA256 verification confirmed all 22 protected files unchanged,
including every pre-existing summary file, the validated baseline script,
and these untracked Conda snapshots:

- `envs/germline-wes-before-vep-update-explicit.txt`
- `envs/germline-wes-before-vep-update.yml`

No existing analysis data was deleted or overwritten. No alignment, variant
calling, benchmark generation, or VEP annotation was run. No software, genome,
or dataset was downloaded. New producer outputs were kept outside the repository.
Changes remain uncommitted for user review.
