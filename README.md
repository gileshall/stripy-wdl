# STRipy WDL pipeline

WDL workflow to run STRipy for short tandem repeat (STR) genotyping. The WDL standardizes STRipy execution in containerized environments for clinical pipelines.

Upstream STRipy: [STRipy-pipeline on GitLab](https://gitlab.com/andreassh/stripy-pipeline).

## What the workflow does

- Executes STRipy (`stri.py`) with pinned versions of ExpansionHunter, REViewer, and BWA
- Expands aliased groups of loci (e.g., cohorts or disease panels) into explicit loci
- Generates a runtime specific [config.json](https://gitlab.com/andreassh/stripy-pipeline/-/blob/main/config.json?ref_type=heads) based on workflow inputs.
- Collects TSV/JSON/HTML outputs

## Tools

- ExpansionHunter: STR genotyping
- REViewer: read visualization
- BWA: alignment utilities used by STRipy
- Builtin STRipy wrapper

All tools are installed in the Docker image and available on $PATH.

## Key WDL inputs:

- `input_bam` / `input_bam_index`: CRAM/BAM with matching CRAI/BAI
- `reference_fasta`: Indexed reference (e.g., hg38)
- `genome_build`: One of `hg38`, `hg19`, `hs1`
- `locus`: Comma-separated loci or profile names (expanded by wrapper)
- `analysis`: `standard` or `extended`
- `output_json` (default true), `verbose` (default false)


## Layout

- `docker/scripts/stripy` wrapper
- `docker/scripts/default-config.json` base config
- `docker/scripts/catalogs/` profiles
- `docker/scripts/catalogs/loci_profiles.json` defines named sets.
- `docker/Dockerfile` image
- `wdl/stripy-pipeline.wdl` workflow (primary)
- `wdl/test/test.sh` workflow test based on miniwdl

### Wrapper Details

The wrapper lives external to the WDL and is bundled in the Dockerimage.  It wraps the execution of [stri.py](https://gitlab.com/andreassh/stripy-pipeline/-/blob/main/stri.py?ref_type=heads).  Before the wrapper executes STRipy, it does the following:

1. Expand and merge aliased loci into explicit loci
2. Consume and convert extra command line options into a runtime specific config file that is based on the default config file shipped with STRipy.
3. Validate custom loci BED file, if provided
4. Execute STRipy
5. Generate VCF from STRipy JSON output, if requested

## Quick start

### Build image

```bash
docker/build.sh --tag stripy-pipeline:latest
```

### Test the workflow with miniwdl

```bash
$ pip install miniwdl
$ cd wdl/test
$ ./download.sh
$ ./test.sh
```