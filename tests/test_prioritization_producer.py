#!/usr/bin/env python3
"""Small synthetic end-to-end regressions; no real HG002 inputs required."""
import csv
import gzip
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

PRODUCER = Path(__file__).resolve().parents[1] / "scripts/produce_hg002_prioritization.sh"
FIELDS = ["Allele", "Consequence", "IMPACT", "SYMBOL", "Gene", "Feature",
          "BIOTYPE", "HGVSc", "HGVSp", "Existing_variation", "PICK",
          "CANONICAL", "MANE_SELECT", "SIFT", "PolyPhen", "MAX_AF", "CLIN_SIG"]
HEADER = """##fileformat=VCFv4.2
##contig=<ID=chr1,length=10000>
##contig=<ID=chr2,length=10000>
##FILTER=<ID=PASS,Description="All filters passed">
##INFO=<ID=CSQ,Number=.,Type=String,Description="VEP. Format: """ + "|".join(FIELDS) + """">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Depth">
##FORMAT=<ID=GQ,Number=1,Type=Integer,Description="Genotype quality">
##FORMAT=<ID=AD,Number=R,Type=Integer,Description="Allelic depths">
#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tTEST
"""


def record(pos, **kw):
    row = dict(chrom="chr1", pos=pos, ref="A", alt="C", impact="MODERATE",
               consequence="missense_variant", af="0.01", gt="0/1", dp="100",
               gq=".", ad="50,50", sift="deleterious(0.01)",
               polyphen="probably_damaging(0.99)", pick="1", symbol="SAME")
    row.update(kw)
    return row


def vcf(rows):
    text = HEADER
    for row in rows:
        values = dict(Allele=row["alt"].split(",")[0], Consequence=row["consequence"],
                      IMPACT=row["impact"], SYMBOL=row["symbol"], Gene="ENSG_TEST",
                      Feature="ENST_TEST", BIOTYPE="protein_coding", PICK=row["pick"],
                      SIFT=row["sift"], PolyPhen=row["polyphen"], MAX_AF=row["af"])
        csq = "|".join(values.get(field, "") for field in FIELDS)
        text += "\t".join([row["chrom"], str(row["pos"]), ".", row["ref"], row["alt"],
                           ".", "PASS", "CSQ=" + csq, "GT:DP:GQ:AD",
                           ":".join(row[k] for k in ("gt", "dp", "gq", "ad"))]) + "\n"
    return text


class ProducerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="prioritization-unit-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        # Run a standalone copy where no project reference output tables exist.
        self.script = self.base / "standalone/produce_hg002_prioritization.sh"
        self.script.parent.mkdir()
        shutil.copy2(PRODUCER, self.script)
        self.rtg = self.base / "rtg"
        self.rtg.mkdir()
        self.input = self.base / "input.vcf"
        self.bed = self.base / "benchmark.bed"
        self.out = self.base / "output"

    def run_producer(self, rows, *, tp=(), fp=(), bed="chr1\t0\t10000\n", extra=()):
        self.input.write_text(vcf(rows))
        for name, records in (("tp", tp), ("fp", fp)):
            with gzip.open(self.rtg / (name + ".vcf.gz"), "wt") as stream:
                stream.write(vcf(records))
        self.bed.write_text(bed)
        return subprocess.run(
            ["bash", str(self.script), "--input", str(self.input),
             "--rtg-dir", str(self.rtg), "--benchmark-bed", str(self.bed),
             "--out-dir", str(self.out), *extra],
            text=True, capture_output=True, cwd=self.base)

    def table(self, name):
        with (self.out / ("HG002." + name + ".tsv")).open() as stream:
            return list(csv.DictReader(stream, delimiter="\t"))

    def successful(self, process):
        self.assertEqual(process.returncode, 0, process.stdout + process.stderr)
        self.assertIn("status=COMPLETE", (self.out / "run_manifest.txt").read_text())

    def test_exact_four_field_identity_and_benchmark_statuses(self):
        a = record(100, impact="HIGH", consequence="frameshift_variant")
        low = record(100, alt="G", impact="HIGH", dp="9", ad="4,5")
        other_ref = record(100, ref="AA", impact="HIGH")
        other_chrom = record(100, chrom="chr2", impact="HIGH")
        fp = record(110, impact="HIGH")
        both = record(120, impact="HIGH")
        at_end = record(101, impact="HIGH")
        rows = [a, low, other_ref, other_chrom, fp, both, at_end]
        self.successful(self.run_producer(rows, tp=[a, both], fp=[low, fp, both],
                                         bed="chr1\t99\t100\n"))
        actual = {(r["CHROM"], r["POS"], r["REF"], r["ALT"]):
                  (r["GIAB_RECORD_STATUS"], r["GIAB_INTERPRETATION"])
                  for r in self.table("shortlist30_GIAB.final")}
        self.assertEqual(len(actual), 6)
        self.assertNotIn(("chr1", "100", "A", "G"), actual)
        self.assertEqual(actual[("chr1", "100", "A", "C")],
                         ("RTG_TP", "TP_MATCH_IN_BENCHMARK"))
        self.assertEqual(actual[("chr1", "100", "AA", "C")],
                         ("NOT_FOUND_EXACT", "REQUIRES_REVIEW"))  # partial overlap
        self.assertEqual(actual[("chr2", "100", "A", "C")],
                         ("NOT_FOUND_EXACT", "OUTSIDE_BENCHMARK"))
        self.assertEqual(actual[("chr1", "101", "A", "C")],
                         ("NOT_FOUND_EXACT", "OUTSIDE_BENCHMARK"))  # half-open endpoint
        self.assertEqual(actual[("chr1", "110", "A", "C")],
                         ("RTG_FP", "REQUIRES_REVIEW"))
        self.assertEqual(actual[("chr1", "120", "A", "C")],
                         ("CHECK_BOTH", "REQUIRES_REVIEW"))

    def test_frequency_predictor_and_review_boundaries(self):
        rows = [record(200, ad="70,30"), record(210, ad="30,70"),
                record(220, ad="71,29"), record(230, ad="29,71"),
                record(240, dp="10", ad="10,10"),
                record(250, dp="40", ad="10,10"), record(260, dp="41", ad="10,10"),
                record(270, af="0.010001"), record(280, af=""),
                record(290, sift="deleterious_low_confidence(0.01)"),
                record(300, polyphen="possibly_damaging(0.6)"),
                record(310, gt="1|0"), record(320, gt="1/1", ad="0,100"),
                record(330, dp="9", ad="5,4"), record(340, ad="91,9"),
                record(350, impact="LOW"), record(360, sift="tolerated(0.5)")]
        self.successful(self.run_producer(rows))
        strict = {r["POS"] for r in self.table("rare_missense_strict_review")}
        self.assertEqual(strict, {"200", "210", "240", "250", "310", "320"})
        rare = {r["POS"] for r in self.table("rare_protein_altering")}
        self.assertFalse({"270", "280", "350"} & rare)
        reviewed = {r["POS"]: r["REVIEW_FLAGS"] for r in
                    self.table("rare_missense_both_damaging_review")}
        self.assertNotIn("360", reviewed)
        self.assertIn("ALLELE_IMBALANCE;", reviewed["220"])
        self.assertIn("AD_DP_DISCREPANCY;", reviewed["260"])
        self.assertIn("LOW_DEPTH;", reviewed["330"])
        self.assertIn("LOW_ALT_SUPPORT;", reviewed["340"])

    def test_preserves_branch_specific_missing_data_and_homozygous_rules(self):
        rows = [record(100, impact="HIGH", ad="."),
                record(110, ad="."), record(120, impact="HIGH", dp="."),
                record(130, dp="."), record(140, impact="HIGH", gt="1/1", ad="0,100"),
                record(150, gt="1/1", ad="0,100")]
        self.successful(self.run_producer(rows))
        high = {r["POS"]: r["REVIEW_FLAGS"] for r in self.table("high_impact_review")}
        missense = {r["POS"]: r["REVIEW_FLAGS"] for r in
                    self.table("rare_missense_both_damaging_review")}
        self.assertEqual(high["100"], "NO_BASIC_FLAGS")
        self.assertEqual(high["120"], "LOW_DEPTH;")
        self.assertEqual(high["140"], "ALLELE_IMBALANCE;")
        self.assertEqual(missense["110"], "MISSING_AD;MISSING_ALT_BALANCE;")
        self.assertEqual(missense["130"], "MISSING_DP;")
        self.assertEqual(missense["150"], "NO_BASIC_FLAGS")

    def test_empty_selection_and_empty_genotype_stream(self):
        for rows in ([record(100, af="0.1")], []):
            with self.subTest(rows=len(rows)):
                self.out = self.base / ("output" + str(len(rows)))
                self.successful(self.run_producer(rows))
                self.assertEqual(self.table("shortlist30"), [])
                self.assertEqual(self.table("shortlist30_GIAB.final"), [])
                self.assertEqual(self.table("high_impact_review"), [])

    def test_duplicate_and_multiallelic_rejection(self):
        for label, rows in (("duplicate", [record(100), record(100)]),
                            ("nonpick-duplicate", [record(100, pick="0"), record(100, pick="0")]),
                            ("multiallelic", [record(100, alt="C,G", ad="30,30,40")])):
            with self.subTest(case=label):
                self.out = self.base / label
                process = self.run_producer(rows)
                self.assertNotEqual(process.returncode, 0)
                self.assertIn("Unsupported or duplicate", process.stderr)
                self.assertNotIn("status=COMPLETE", (self.out / "run_manifest.txt").read_text())

    def test_refuses_existing_output_and_invalid_arguments(self):
        self.out.mkdir()
        sentinel = self.out / "sentinel"
        sentinel.write_text("keep")
        process = self.run_producer([record(100)])
        self.assertNotEqual(process.returncode, 0)
        self.assertIn("already exists", process.stderr)
        self.assertEqual(sentinel.read_text(), "keep")
        for args in ([], ["--out-dir"], ["--unknown"]):
            process = subprocess.run(["bash", str(self.script), *args], text=True,
                                     capture_output=True, cwd=self.base)
            self.assertNotEqual(process.returncode, 0)
            self.assertIn("ERROR:", process.stderr)

    def test_multiple_samples_rejected_before_creating_output(self):
        self.successful(self.run_producer([record(100)]))
        self.out = self.base / "multisample-output"
        text = self.input.read_text().replace("FORMAT\tTEST\n", "FORMAT\tTEST\tOTHER\n")
        lines = text.splitlines()
        lines[-1] += "\t0/1:100:99:50,50"
        self.input.write_text("\n".join(lines) + "\n")
        process = subprocess.run(
            ["bash", str(self.script), "--input", str(self.input),
             "--rtg-dir", str(self.rtg), "--benchmark-bed", str(self.bed),
             "--out-dir", str(self.out)], text=True, capture_output=True)
        self.assertNotEqual(process.returncode, 0)
        self.assertIn("Exactly one VCF sample", process.stderr)
        self.assertFalse(self.out.exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
