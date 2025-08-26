# STRipy Wrapper

A simple Python wrapper for STRipy that automatically expands loci profile names to individual loci.

## Usage

```bash
./stripy_wrapper.py [STRipy arguments...]
```

## Features

- Automatically loads loci profiles from `catalogs/loci_profiles.json`
- Expands profile names (e.g., "neurological_disease") to individual loci
- Removes duplicate loci
- Passes all other arguments unchanged to STRipy
- Uses `exec()` to replace the current process with STRipy

## Examples

```bash
# Expand a profile
./stripy_wrapper.py --loci neurological_disease --input sample.bam

# Mix profiles and individual loci
./stripy_wrapper.py --loci childhood_onset,HTT,ATXN3 --input sample.bam

# Individual loci (unchanged)
./stripy_wrapper.py --loci HTT,ATXN3,AFF2 --input sample.bam
```

## Loci Profiles

The wrapper recognizes these profile names:
- `all_loci` - All available loci
- `neurological_disease` - Neurological disease associated loci
- `childhood_onset` - Childhood onset disease loci
- `coding_region` - Coding region loci
- `utrs` - UTR loci
- `standard_repeats` - Standard repeat loci
- `imperfect_gcn_repeats` - Imperfect GCN repeat loci
- `replaced_nested_repeats` - Replaced nested repeat loci
- `vntrs` - VNTR loci

## Requirements

- Python 3.6+
- Access to `catalogs/loci_profiles.json`
- STRipy command available in PATH
