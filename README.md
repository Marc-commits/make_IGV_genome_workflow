# make_IGV_genome_workflow

A small Snakemake module: build an IGV flat JSON genome descriptor from a
FASTA + gene annotation file (GFF/GFF3/GTF/BED). Originally wrapped
`bash_scripts/make_IGV_genome/make_igv_genome.sh` (a private internal repo)
unchanged; as of 2.0.0 the script has diverged (JSON descriptor rewrite) and
is a first-party change in this repo, not a vendored passthrough.

## What it does

`make_igv_genome` — runs the script to generate a `.fai` index (via
`samtools faidx`, unless `--fai` is given) and write a flat IGV JSON genome
descriptor (`{id, name, fastaURL, indexURL, tracks}`) referencing the
FASTA, `.fai`, and gene file by a path relative to the descriptor's own
directory. The FASTA and gene file are **not** copied — they must remain in
place at the referenced location for IGV to load the genome.

**Caveat for consumers**: unless `--fai` is given, the rule declares
`<fasta>.fai` as a Snakemake output, so `<fasta>` must be a file this
workflow owns (e.g. a pipeline-built artifact) — Snakemake will consider
itself the owner of that `.fai` and may delete it under
`--delete-all-output`/`snakemake --clean`. Don't point `fasta` at a shared
external file you don't want a `.fai` written next to.

## Usage as a standalone workflow

```bash
snakemake --use-conda --latency-wait 30 make_igv_genome_workflow_all
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
    "output": "results/pSAM301.json",
}

module igv:
    snakefile:
        "../../submodules/make_IGV_genome_workflow/Snakefile"
    config:
        _igv_module_config

use rule * from igv as igv_*
```

## Tests

- `tests/make_igv_genome.bats` — bats suite exercising the script directly
  (`bats tests/make_igv_genome.bats`).
- `.tests/unit/` — Snakemake rule-level integration test
  (`pytest .tests/unit`).

## Migrating from 0.1.x (zip `.genome` archives)

0.2.0 replaces the legacy zip `.genome` archive output with IGV's flat
JSON genome descriptor format (IGV's own current primary format). The zip
format had a known bug loading from a WSL-mounted network share in IGV
Desktop ("cannot find file" for the bundled `.fai`). Consumers must:

- change their `output` config value's extension from `.genome` to `.json`
- keep the FASTA/gene file in place next to (or at a stable relative path
  from) the `.json` output — the descriptor references them, it no longer
  bundles them
- be aware the rule now also produces `<fasta>.fai` as a declared output
  (see the caveat above)
