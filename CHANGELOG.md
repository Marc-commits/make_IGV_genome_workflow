# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added (Unreleased)

- Added .github/workflows/pre-commit.yml: runs `uvx pre-commit run
  --all-files` on `runs-on: self-hosted` for every pull request.

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
