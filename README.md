# STRipy Wrapper & WDL Pipeline

A minimal wrapper around STRipy that expands `--locus` profile names (from `scripts/catalogs/loci_profiles.json`) into individual loci before invoking the original STRipy pipeline. Includes a WDL workflow and a Python-based test harness.

## Features

- Expands `--locus` profile names (e.g., `all_loci`, `neurological_disease`) into loci
- No-op pass-through when `--locus` is absent
- Docker image with wrapper on PATH as `stripy`
- WDL workflow (`stripy-pipeline.wdl`) to run STRipy in Docker
- Python test runner to validate two scenarios

## Quick Start

### Build Docker image

```bash
./build.sh --tag stripy-pipeline:latest
```

### Run via WDL (miniwdl)

Create an inputs JSON (example):

```json
{
  "STRipyPipeline.input_bam": "NA12878/NA12878.final.cram",
  "STRipyPipeline.input_bam_index": "NA12878/NA12878.final.cram.crai",
  "STRipyPipeline.genome_build": "hg38",
  "STRipyPipeline.reference_fasta": "references/hg38.fa.gz",
  "STRipyPipeline.locus": "HTT,ATXN3,AFF2",
  "STRipyPipeline.sex": "female",
  "STRipyPipeline.analysis": "standard",
  "STRipyPipeline.docker_image": "stripy-pipeline:latest",
  "STRipyPipeline.memory_gb": 16,
  "STRipyPipeline.cpu": 4
}
```

Run:

```bash
miniwdl run stripy-pipeline.wdl -i test-inputs.json -d test-outputs -v
```

Outputs appear under `test-outputs/.../call-RunSTRipy/out/`.

### Wrapper behavior

- Command exposed as `stripy` in the container
- If `--locus` is present, profile names are expanded and deduplicated, then STRipy is executed as:
  - `python3 /opt/stripy-pipeline/stri.py [args...]`
- If `--locus` is not present, arguments are passed straight through

### Run test suite

Requires `miniwdl` and Docker.

```bash
pip install miniwdl
./test_wdl.py
```

The test harness:
- Creates `test-env/` containing required inputs (CRAM/CRAI, hg38.fa.gz/fai)
- Runs two cases:
  1) `HTT,ATXN3,AFF2`
  2) `all_loci`
- Writes run folders under `test-env/test-outputs/`

## Locus profiles

`scripts/catalogs/loci_profiles.json` contains named sets such as:
- `all_loci`
- `neurological_disease`
- `childhood_onset`
- `coding_region`
- `utrs`

## Repo layout

- `scripts/stripy` wrapper entrypoint
- `scripts/catalogs/` locus/profile catalogs
- `stripy-pipeline.wdl` WDL workflow
- `test_wdl.py` Python test harness
- `Dockerfile` container build

## Notes

- The wrapper only modifies `--locus`; everything else is unchanged
- Reference is kept compressed (`hg38.fa.gz`) as used by the WDL inputs
