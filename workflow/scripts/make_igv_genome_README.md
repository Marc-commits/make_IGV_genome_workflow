# make_igv_genome.sh

**Purpose**: Builds a flat IGV JSON genome descriptor (`{id, name,
fastaURL, indexURL, tracks}`) from a FASTA and a gene annotation file
(GFF/GFF3/GTF/BED). Wrapped by the `make_igv_genome` Snakemake rule via
`shell:`.

**Provenance**: Originally vendored unchanged from
`bash_scripts/make_IGV_genome/make_igv_genome.sh` (commit `8c2a815`). As of
2.0.0 the script has diverged (JSON descriptor rewrite, replacing the
original zip-archive output) and is a first-party change in this repo, no
longer a passthrough of that source.

**Inputs** (CLI flags, wired from `snakemake.input`/`.params` by the
Snakemake rule): `-f/--fasta`, `-g/--genefile`, `-o/--output`, `-i/--id`,
`-n/--name`, plus `--force` (always passed by the rule, since Snakemake's
own up-to-date tracking — not this script's own existence check — is what
should decide whether to rebuild).

**Outputs**: the JSON descriptor at the given output path, plus (unless
`--fai` is given) a `.fai` index generated beside the input FASTA.

**Data transformations**:

- Generates a `.fai` index for the input FASTA (via `samtools faidx`,
  written directly beside the FASTA) unless an existing one is passed with
  `--fai`.
- Derives the `tracks[0].format` value from the gene file's extension
  (`gff3`/`gff`/`gtf`/`bed`), rather than hardcoding it — fails loudly on
  an unrecognized extension.
- Computes `fastaURL`/`indexURL`/`tracks[0].url` as paths relative to the
  output JSON's own directory (`os.path.relpath` on absolute paths), so
  the FASTA/`.fai`/gene file are referenced correctly whether or not they
  live in the same directory as the output — nothing is copied.
- Writes the descriptor atomically (`<output>.tmp` + `os.replace()`).

**Audit**:

- Zero-copy by design: the FASTA and gene file are never duplicated, so
  they must remain in place at their referenced path for IGV to load the
  genome — the JSON is not a self-contained, relocatable bundle the way
  the old zip archive was. This is inherent to IGV's flat-file genome
  format (which also supports remote http/s3 URLs), not a limitation of
  this script.
- `.fai` generation is a declared side effect against the *input* FASTA's
  own location (not a throwaway staging copy) — the FASTA must be
  writable, and callers should only point `fasta` at a file this workflow
  owns (see the module README's consumer caveat).
- No organism/plasmid-specific hardcoding; fully generic given any
  FASTA + gene file pair.
