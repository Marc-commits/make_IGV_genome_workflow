# make_IGV_genome_workflow

A small Snakemake module: build an IGV `.genome` archive from a FASTA +
gene annotation file (GFF/GFF3/GTF/BED). Wraps
[`bash_scripts/make_IGV_genome/make_igv_genome.sh`](https://github.com/Marc-commits/bash_scripts)
(vendored as `workflow/scripts/make_igv_genome.sh`) in a Snakemake rule; the
underlying logic is unchanged from that already-tested standalone script.

## What it does

`make_igv_genome` — runs the vendored script to assemble a `.genome` zip
archive: FASTA + `.fai` index (generated via `samtools faidx`) + gene file +
a correctly-named `property.txt` descriptor, verified for zip integrity and
per-entry size correctness before being written to the requested output.

## Usage as a standalone workflow

```bash
snakemake --use-conda --conda-frontend mamba --conda-prefix ~/.snakemake \
  --latency-wait 30 make_igv_genome_workflow_all
```

Edit `config/config.yaml` (`fasta`, `genefile`, `genome_id`, `genome_name`,
`output`) first, or override via `--config`.

## Usage as a Snakemake module (git submodule)

```python
_igv_module_config = {
    "fasta": combined_fasta,
    "genefile": combined_genes_gff,
    "genome_id": "pSAM301",
    "genome_name": "pSAM301 plasmid",
    "output": "results/pSAM301.genome",
}

module igv:
    snakefile:
        "../../submodules/make_IGV_genome_workflow/Snakefile"
    config:
        _igv_module_config

use rule * from igv as igv_*
```

## Tests

- `tests/make_igv_genome.bats` — ported unchanged from the source script's
  own bats suite, run directly against the vendored copy
  (`bats tests/make_igv_genome.bats`).
- `.tests/unit/` — Snakemake rule-level integration test
  (`pytest .tests/unit`).
