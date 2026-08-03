# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.2.0] - 2026-08-03

### Changed

- **Breaking:** `make_igv_genome` now builds a flat IGV JSON genome
  descriptor (`{id, name, fastaURL, indexURL, tracks: [...]}`) instead of a
  legacy zip `.genome` archive. Fixes a real bug: IGV Desktop on Windows
  failed to find the bundled `.fai` when loading a `.genome` zip from a
  WSL-mounted network share (`/mnt/*` / `\\...`) — the flat JSON format is
  also IGV's own current primary format. Consumers must change their
  `output` config value's extension from `.genome` to `.json`.
- The script no longer copies the FASTA/gene file; the JSON references them
  by a path relative to the descriptor's own directory (or an absolute path
  if outside that tree). `.fai` generation (via `samtools faidx`, unless
  `--fai` is given) now happens directly beside the input FASTA instead of
  in a throwaway staging directory, and is a declared Snakemake rule output
  (`igv_genome.smk`'s `output.fai`).
- `format` in the JSON `tracks` entry is derived from the gene file's
  extension (gff/gff3/gtf/bed) instead of being implicit in `property.txt`.
- `--keep-tmp` removed (no staging directory exists anymore).
- Dropped `zip`/`unzip` from `workflow/envs/igv_genome.yaml`; regenerated
  `igv_genome.linux-64.pin.txt` accordingly.
- `make_igv_genome.sh` version bumped `1.0.0` → `2.0.0`.

## [0.1.0] - 2026-07-30

### Added

- Initial release: `make_igv_genome` rule wrapping the vendored
  `bash_scripts/make_IGV_genome/make_igv_genome.sh` (commit `8c2a815`),
  packaged as a reusable Snakemake `module:` (git submodule), consumed
  first by `genbank_to_replicon_workflow`.
