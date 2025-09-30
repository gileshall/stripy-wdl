# Stripy Custom Loci BED Format Specification

## Overview

Stripy accepts custom tandem repeat loci via a modified BED format file. This document describes the expected format based on the parser implementation.

## File Format

- **Delimiter**: Tab-separated values (TSV)
- **Header**: No header row
- **Encoding**: UTF-8
- **Extension**: `.bed` (recommended)

## Format Variants

Stripy supports three format variants with increasing levels of detail:

### 1. Minimal Format (4 columns)
Basic locus definition without disease annotations.

### 2. Standard Format (5 columns)
Adds custom locus identifier.

### 3. Extended Format (9 columns)
Full disease annotation with clinical ranges.

## Column Specification

| Column | Name | Type | Required | Description |
|--------|------|------|----------|-------------|
| 1 | Chromosome | String | ✓ | Chromosome identifier (e.g., `chr4`, `chrX`) |
| 2 | Start | Integer | ✓ | 0-based start position (BED standard) |
| 3 | End | Integer | ✓ | End position (exclusive, BED standard) |
| 4 | Motif | String | ✓ | Repeat unit sequence (e.g., `CAG`, `CTG`, `GGCCCC`) |
| 5 | LocusID | String | ○ | Locus identifier (default: `"Custom"`) |
| 6 | Disease | String | ○ | Associated disease name |
| 7 | Inheritance | String | ○ | Inheritance pattern (e.g., `AD`, `AR`, `XL`) |
| 8 | NormalRange | String | ○ | Normal repeat range (format: `"min-max"` or single value) |
| 9 | PathogenicCutoff | Integer | ○ | Pathogenic repeat threshold |

### Column Details

#### Chromosome (Required)
- Reference sequence identifier
- Examples: `chr1`, `chr2`, ..., `chr22`, `chrX`, `chrY`, `chrM`
- No specific format enforced, but should match reference genome

#### Start (Required)
- 0-based start coordinate (BED standard)
- Must be a valid integer
- Must be less than End coordinate

#### End (Required)
- End coordinate (exclusive, BED standard)
- Must be a valid integer
- Must satisfy: `end > start`
- Must satisfy: `end - start < 500`

#### Motif (Required)
- DNA repeat unit sequence
- Use uppercase (e.g., `CAG`, not `cag`)
- Examples: `CAG`, `CTG`, `CGG`, `GAA`, `GGCCCC`, `ATTCT`

#### LocusID (Optional)
- Custom identifier for the locus
- Defaults to `"Custom"` if column not provided
- Recommended to use gene symbols or established nomenclature
- Examples: `HD`, `DM1`, `FMR1`, `ATXN1`, `C9orf72`

#### Disease (Optional)
- Human-readable disease name
- Defaults to `"NA"` if columns 5-8 not fully provided
- Examples: `Huntington Disease`, `Myotonic Dystrophy Type 1`

#### Inheritance (Optional)
- Inheritance pattern abbreviation
- Defaults to `"NA"` if columns 5-8 not fully provided
- Common values:
  - `AD` - Autosomal Dominant
  - `AR` - Autosomal Recessive
  - `XL` - X-Linked
  - `XLD` - X-Linked Dominant
  - `XLR` - X-Linked Recessive

#### NormalRange (Optional)
- Normal repeat count range
- Format: `"min-max"` (e.g., `"6-26"`) or single value (e.g., `"20"`)
- Parsed by splitting on `"-"` character
- Single values become `[value, value]`
- Defaults to `[-1, -1]` if columns 5-8 not fully provided

#### PathogenicCutoff (Optional)
- Repeat count threshold for pathogenicity
- Must be a valid integer
- Defaults to `9999` if columns 5-8 not fully provided
- Represents the minimum repeat count considered pathogenic

## Examples

### Example 1: Minimal Format (4 columns)

```tsv
chr4	3074876	3074966	CAG
chr19	46273462	46273525	CTG
chrX	147912050	147912110	CGG
```

### Example 2: Standard Format (5 columns)

```tsv
chr4	3074876	3074966	CAG	HD
chr19	46273462	46273525	CTG	DM1
chrX	147912050	147912110	CGG	FMR1
```

### Example 3: Extended Format (9 columns)

```tsv
chr4	3074876	3074966	CAG	HD	Huntington Disease	AD	6-26	40
chr19	46273462	46273525	CTG	DM1	Myotonic Dystrophy Type 1	AD	5-34	50
chrX	147912050	147912110	CGG	FMR1	Fragile X Syndrome	XL	6-44	200
chr9	27573526	27573566	GGCCCC	C9orf72	ALS/FTD	AD	2-8	30
chr6	16327634	16327723	CTG	DMPK	Myotonic Dystrophy	AD	5-37	50
chr14	92537355	92537415	CAG	ATXN3	Machado-Joseph Disease	AD	12-40	61
```

### Example 4: Single Value Normal Range

```tsv
chr1	12345000	12345050	GAA	FXN	Friedreich Ataxia	AR	33	66
```
This parses `normal_range` as `["33", "33"]`.