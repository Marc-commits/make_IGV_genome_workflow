# make_IGV_genome_workflow

A small Snakemake module: build an IGV `.genome` archive from a FASTA +
gene annotation file (GFF/GFF3/GTF/BED), wrapped in a single Snakemake rule.

## What it does

`make_igv_genome` — assembles a `.genome` zip archive: FASTA + `.fai` index
(generated via `samtools faidx`) + gene file + a correctly-named
`property.txt` descriptor, verified for zip integrity and per-entry size
correctness before being written to the requested output.

## Usage as a standalone workflow

```bash
snakemake --use-conda --latency-wait 30 make_igv_genome_workflow_all
```

Edit `config/config.yaml` (`fasta`, `genefile`, `genome_id`, `genome_name`,
`output`) first, or override via `--config`.
The config is validated against `workflow/schemas/config.schema.yaml`.

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
