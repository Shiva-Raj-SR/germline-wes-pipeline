#!/usr/bin/env python3

import argparse
import filecmp
import gzip
import re
from pathlib import Path


def read_fai(path):
    contigs = {}

    with open(path) as handle:
        for line in handle:
            fields = line.rstrip("\n").split("\t")
            name, length = fields[0], int(fields[1])

            if name in contigs or length <= 0:
                raise ValueError(f"Invalid FASTA index entry: {name}")

            contigs[name] = length

    if not contigs:
        raise ValueError("FASTA index is empty")

    return contigs


def read_dictionary(path):
    contigs = {}

    with open(path) as handle:
        for line in handle:
            if not line.startswith("@SQ\t"):
                continue

            tags = dict(
                field.split(":", 1)
                for field in line.rstrip("\n").split("\t")[1:]
                if ":" in field
            )

            name = tags["SN"]
            length = int(tags["LN"])

            if name in contigs or length <= 0:
                raise ValueError(f"Invalid sequence dictionary entry: {name}")

            contigs[name] = length

    if not contigs:
        raise ValueError("Sequence dictionary has no contigs")

    return contigs


def check_intervals(path, reference):
    declared = {}
    count = 0

    with open(path) as handle:
        for line in handle:
            if line.startswith("@SQ\t"):
                tags = dict(
                    field.split(":", 1)
                    for field in line.rstrip("\n").split("\t")[1:]
                    if ":" in field
                )

                name = tags["SN"]
                length = int(tags["LN"])

                if name not in reference or reference[name] != length:
                    raise ValueError(
                        f"{path}: incompatible interval header for {name}"
                    )

                if name in declared:
                    raise ValueError(f"{path}: duplicate contig {name}")

                declared[name] = length

            elif line.startswith("@") or not line.strip():
                continue

            else:
                fields = line.rstrip("\n").split("\t")
                name = fields[0]
                start = int(fields[1])
                end = int(fields[2])

                if name not in declared:
                    raise ValueError(f"{path}: undeclared contig {name}")

                if not 1 <= start <= end <= reference[name]:
                    raise ValueError(
                        f"{path}: invalid interval {name}:{start}-{end}"
                    )

                count += 1

    if count == 0:
        raise ValueError(f"{path}: no intervals found")

    print(f"PASS: {Path(path).name} ({count} intervals)")


def check_known_sites(path, reference):
    declared = {}
    opener = gzip.open if str(path).endswith(".gz") else open

    with opener(path, "rt") as handle:
        for line in handle:
            if line.startswith("##contig=<"):
                name_match = re.search(r"\bID=([^,>]+)", line)
                length_match = re.search(r"\blength=(\d+)", line)

                if not name_match:
                    raise ValueError(f"{path}: invalid contig header")

                name = name_match.group(1)

                if name not in reference:
                    raise ValueError(f"{path}: unknown contig {name}")

                if length_match:
                    length = int(length_match.group(1))

                    if length != reference[name]:
                        raise ValueError(
                            f"{path}: incorrect length for {name}"
                        )

                if name in declared:
                    raise ValueError(f"{path}: duplicate contig {name}")

                declared[name] = True

            elif line.startswith("#CHROM"):
                break

    if not declared:
        raise ValueError(f"{path}: no contig metadata found")

    print(f"PASS: {Path(path).name} ({len(declared)} contigs)")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--bwa-fasta", required=True)
    parser.add_argument("--gatk-fasta", required=True)
    parser.add_argument("--fai", required=True)
    parser.add_argument("--dict", required=True)
    parser.add_argument("--capture", required=True)
    parser.add_argument("--calling", required=True)
    parser.add_argument("--known-sites", nargs=3, required=True)

    args = parser.parse_args()

    bwa = Path(args.bwa_fasta)
    gatk = Path(args.gatk_fasta)

    if not bwa.samefile(gatk) and not filecmp.cmp(
        bwa, gatk, shallow=False
    ):
        raise ValueError("BWA and GATK reference FASTAs differ")

    print("PASS: BWA and GATK reference FASTAs match")

    reference = read_fai(args.fai)
    dictionary = read_dictionary(args.dict)

    if list(reference.items()) != list(dictionary.items()):
        raise ValueError(
            "FASTA index and sequence dictionary disagree"
        )

    print(f"PASS: FASTA index and dictionary ({len(reference)} contigs)")

    check_intervals(args.capture, reference)
    check_intervals(args.calling, reference)

    for path in args.known_sites:
        check_known_sites(path, reference)

    print("REFERENCE COMPATIBILITY VALIDATION PASSED")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError, IndexError) as error:
        raise SystemExit(f"ERROR: {error}")
