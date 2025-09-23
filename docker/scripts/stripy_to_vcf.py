#!/usr/bin/env python3

import argparse
import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

import pysam

def parse_coords(coord):
    m = re.match(r"(chr)?(?P<chrom>[^:]+):(?P<start>\d+)-(?P<end>\d+)", str(coord))
    if not m:
        return None
    chrom = m.group("chrom")
    if not chrom.startswith("chr"):
        chrom = "chr" + chrom
    return chrom, int(m.group("start")), int(m.group("end"))

def chrom_key(c):
    m = re.match(r"chr(\d+)$", c)
    if m:
        return (0, int(m.group(1)))
    order = {"chrX": (1, 23), "chrY": (1, 24), "chrM": (2, 25), "chrMT": (2, 25)}
    return order.get(c, (9, c))

def load_inputs(json_path):
    with open(json_path, "r") as f:
        J = json.load(f)
    loci = []
    for entry in J.get("GenotypingResults", []):
        for locus_name, locus in entry.items():
            tl = locus["TargetedLocus"]
            coords = tl["Coordinates"]
            (chrom, start, end) = parse_coords(coords)
            motif = tl["Motif"]
            (a1, a2) = locus["Alleles"]
            def to_float(x):
                try:
                    return float(x)
                except:
                    return float("nan")
            def ci_str(a):
                ci = a["CI"]
                return f"{ci.get('Min','')}-{ci.get('Max','')}"
            def outlier(a):
                return int(a["IsPopulationOutlier"])
            diseases = []
            corr = tl["CorrespondingDisease"]
            for sym, meta in corr.items():
                diseases.append(meta["DiseaseSymbol"])
            diseases_s = "|".join(sorted(set(diseases)))
            meta = locus["Metadata"]
            filt = locus["Filter"]
            coverage = meta["Coverage"]
            locus_id = tl.get("LocusID") or locus_name
            loci.append({
                "chrom": chrom,
                "pos": start,
                "end": end,
                "id": str(locus_id),
                "motif": motif,
                "period": len(motif),
                "a1_rep": to_float(a1["Repeats"]),
                "a2_rep": to_float(a2["Repeats"]),
                "a1_ci": ci_str(a1),
                "a2_ci": ci_str(a2),
                "a1_out": outlier(a1),
                "a2_out": outlier(a2),
                "a1_z": to_float(a1["PopulationZscore"]),
                "a2_z": to_float(a2["PopulationZscore"]),
                "coverage": coverage,
                "filter": filt,
                "diseases": diseases_s,
            })
    loci.sort(key=lambda x: (chrom_key(x["chrom"]), x["pos"]))
    return loci


def write_with_pysam(loci, out_path, sample_name):
    header = pysam.VariantHeader()

    header.add_meta("source", value="STRipy2VCF")
    header.add_meta("INFO", items=[("ID","END"), ("Number","1"), ("Type","Integer"), ("Description","Stop position of the interval")])
    header.add_meta("INFO", items=[("ID","SVTYPE"), ("Number","1"), ("Type","String"), ("Description","Type of structural variant")])
    header.add_meta("INFO", items=[("ID","RU"), ("Number","1"), ("Type","String"), ("Description","Repeat unit sequence (motif)")])
    header.add_meta("INFO", items=[("ID","PERIOD"), ("Number","1"), ("Type","Integer"), ("Description","Length of the repeat unit")])
    header.add_meta("INFO", items=[("ID","REPCN"), ("Number","2"), ("Type","Float"), ("Description","Allelic repeat counts (A1,A2) from STRipy")])
    header.add_meta("INFO", items=[("ID","REPCI"), ("Number","2"), ("Type","String"), ("Description","Allelic 95% CI on repeat counts as min-max,min-max")])
    header.add_meta("INFO", items=[("ID","OUTLIER"), ("Number","2"), ("Type","Integer"), ("Description","Allelic population outlier flags (0/1)")])
    header.add_meta("INFO", items=[("ID","ZSCORE"), ("Number","2"), ("Type","Float"), ("Description","Allelic population Z-scores")])
    header.add_meta("INFO", items=[("ID","DP"), ("Number","1"), ("Type","Integer"), ("Description","Depth (coverage) at locus, from STRipy")])
    header.add_meta("INFO", items=[("ID","DISEASES"), ("Number","."), ("Type","String"), ("Description","Associated disease symbols for this locus (| separated)")])
    header.add_meta("INFO", items=[("ID","LOCUS"), ("Number","1"), ("Type","String"), ("Description","Gene/locus identifier from STRipy")])
    header.add_meta("FORMAT", items=[("ID","GT"), ("Number","1"), ("Type","String"), ("Description","Unphased genotype")])
    header.add_meta("FORMAT", items=[("ID","AR"), ("Number","2"), ("Type","Integer"), ("Description","Allelic repeat counts (A1,A2) from STRipy")])
    # Should we only use the mentioned chromosomes?
    chrom_list = set(locus['chrom'] for locus in loci)
    for chrom_name in chrom_list:
        header.contigs.add(chrom_name)

    # This is a single sample tool
    header.add_sample(sample_name)
    vf = pysam.VariantFile(out_path, mode="w", header=header)
    for loc in loci:
        rec = header.new_record()
        rec.contig = loc["chrom"]
        rec.start = loc["pos"] - 1
        rec.stop = loc["end"]
        rec.id = str(loc["id"])
        rec.ref = "N"
        rec.alts = ("<STR>",)
        rec.filter.add(loc["filter"] if loc["filter"] else "PASS")
        rec.info["SVTYPE"] = "STR"
        if loc["motif"]:
            rec.info["RU"] = loc["motif"]
            if loc["period"]:
                rec.info["PERIOD"] = int(loc["period"])
        rec.info["REPCN"] = (loc["a1_rep"], loc["a2_rep"])
        rec.info["REPCI"] = (loc["a1_ci"], loc["a2_ci"])
        rec.info["OUTLIER"] = (loc["a1_out"], loc["a2_out"])
        rec.info["ZSCORE"] = (loc["a1_z"], loc["a2_z"])
        rec.info["DP"] = loc["coverage"]
        rec.info["DISEASES"] = loc["diseases"]
        rec.info["LOCUS"] = loc["id"]
        rec.samples[sample_name]["GT"] = (0, 0)
        rec.samples[sample_name]["AR"] = (loc["a1_rep"], loc["a2_rep"])
        vf.write(rec)
    vf.close()

def main():
    ap = argparse.ArgumentParser(description="Convert STRipy JSON output into a VCF with SV-style STR annotations.")
    ap.add_argument("--json", required=True, help="STRipy JSON report")
    ap.add_argument("-o", "--out", required=True, help="Output VCF (compressed and tabix indexed)")
    ap.add_argument("--sample-name", default=None, help="Sample name for VCF")
    args = ap.parse_args()

    if args.sample_name is None:
        args.sample_name = Path(args.out).stem

    loci = load_inputs(args.json)
    write_with_pysam(loci, args.out, args.sample_name)

if __name__ == "__main__":
    main()