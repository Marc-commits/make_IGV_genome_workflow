# make_igv_genome.sh

**Purpose**: Builds an IGV `.genome` archive (a zip containing `property.txt`

+ FASTA + `.fai` + gene file) from a FASTA and a gene annotation file
(GFF/GFF3/GTF/BED). Wrapped by the `make_igv_genome` Snakemake rule via
`shell:`.

**Provenance**: Vendored unchanged from
`bash_scripts/make_IGV_genome/make_igv_genome.sh` (commit `8c2a815`) — a
standalone, already-tested CLI tool — rather than reimplemented, since it
already handles several non-obvious correctness requirements (see below).
Logic is identical to the source; only this module's Snakemake rule wrapper
around it is new.

**Inputs** (CLI flags, wired from `snakemake.input`/`.params` by the
Snakemake rule): `-f/--fasta`, `-g/--genefile`, `-o/--output`, `-i/--id`,
`-n/--name`, plus `--force` (always passed by the rule, since Snakemake's
own up-to-date tracking — not this script's own existence check — is what
should decide whether to rebuild).

**Outputs**: the `.genome` archive at the given output path.

**Data transformations**:

+ Generates a `.fai` index for the input FASTA (via `samtools faidx`) unless
  an existing one is passed with `--fai`.
+ Writes `property.txt` (`fasta=true`, `id=`, `name=`, `geneFile=`,
  `sequenceLocation=`) and zips it together with the FASTA, `.fai`, and gene
  file — all four packed inside the archive, which IGV requires.
+ Verifies the archive (zip integrity + declared vs. actual per-entry sizes)
  before placing it at the requested output path.

**Audit**:

+ Stages all inputs on local disk (`mktemp` under `$TMPDIR`/`/tmp`) before
  zipping, even when inputs/output live on a network mount (e.g. WSL
  `/mnt/*`) — avoids a known 9p/CIFS bug where `zip` writes a stale file
  size into the archive header when reading straight off such a mount.
+ The output descriptor file inside the zip is always named exactly
  `property.txt`; anything else and IGV reports `genomeDescriptor: null`.
+ No organism/plasmid-specific hardcoding; fully generic given any
  FASTA + gene file pair.
