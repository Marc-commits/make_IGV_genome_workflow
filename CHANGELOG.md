# Changelog

All notable changes to this project will be documented in this file.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [0.1.0] - 2026-07-30

### Added

- Initial release: `make_igv_genome` rule wrapping the vendored
  `bash_scripts/make_IGV_genome/make_igv_genome.sh` (commit `8c2a815`),
  packaged as a reusable Snakemake `module:` (git submodule), consumed
  first by `genbank_to_replicon_workflow`.
