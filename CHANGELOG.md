# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Changed (Unreleased)

- `.pre-commit-config.yaml`: `Marc-commits/pre-commit-hooks` bumped from v0.4.0
  to v0.10.0; new `snakemake-config-validate` hook validates the config files
  against `workflow/schemas/config.schema.yaml` at commit time.
- Bumped pre-commit-hooks to v0.11.0: `snakedeploy-pin-conda-envs` is now
  manual-stage only (no pin drift on commits); run `just pin-env`.

### Added (Unreleased)

- `just config-validation` (also a dependency of `just lint`): validates
  `config/config.yaml` against `workflow/schemas/config.schema.yaml` with
  `check-jsonschema` (via `uvx`), reporting all errors at once without parsing
  the workflow.

## [0.3.0] - 2026-11-20

### Added in 0.3.0

- `workflow/schemas/config.schema.yaml` and a `validate()` call in the
  `Snakefile`: the five required keys (`fasta`, `genefile`, `genome_id`,
  `genome_name`, `output`) are checked at parse time, also when used as a
  module.

### Fixed

- justfile rulegraph recipes no longer discard snakemake stderr and now fail
  on pipeline errors (`pipefail`), so a failed rulegraph is reported.

### Changed in 0.3.0

- Rulegraph regeneration moved from `.envrc` into the justfile recipe
  `just chore`; direnv no longer rewrites `workflow/rulegraph.svg` on `cd`.

## [0.1.1] - 2026-09-01

### Added in 0.1.1

- `workflow/scripts/make_igv_genome.sh`: `--tldr` flag printing a
  tldr-pages-style summary (one-line description + 5 example invocations,
  green/cyan/underline-cyan coloring that auto-disables on non-tty stdout).
  A local, help-text-only divergence from the vendored source commit
  `8c2a815`, pending sync back upstream.
- `justfile`: added `env:`/`lint:` recipes to dry-run validate
  `workflow/envs/*.yaml` conda envs and lint the Snakemake workflow.
- `justfile`: added a `version-map:` recipe to (re)generate
  `.version-map` via `grep` over tracked files.

### Changed

- `.pre-commit-config.yaml`: bumped `Marc-commits/pre-commit-hooks` to
  `v0.4.0` and added the `sh-tldr` hook (enforces `--tldr` exits 0 with
  non-empty output).

## [0.1.0] - 2026-07-30

### Added

- Initial release: `make_igv_genome` rule wrapping the vendored
  `bash_scripts/make_IGV_genome/make_igv_genome.sh` (commit `8c2a815`),
  packaged as a reusable Snakemake `module:` (git submodule), consumed
  first by `genbank_to_replicon_workflow`.
