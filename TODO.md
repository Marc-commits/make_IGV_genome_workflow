# TODOs

- `snakefmt` reorder needed (2026-09-19 audit): `log:`/`benchmark:`/`conda:`
  before `params:` in `workflow/rules/igv_genome.smk`; `default_target:` before
  the docstring in `Snakefile`. Fix: `snakefmt Snakefile workflow/rules/igv_genome.smk`.
- (optional, low priority) embed `workflow/rulegraph.svg` in `README.md`.
- (optional, low priority) add per-key inline comments to `config/config.yaml`,
  or a `config/example.config.yaml`, if this module gains more config keys or
  wider external consumers.

- Consider syncing future fixes to `bash_scripts/make_IGV_genome/make_igv_genome.sh`
  back into this vendored copy (or switch to a git submodule of that repo
  instead of vendoring, if it starts changing often).
  This sync-back is already outstanding, not hypothetical: the vendored copy
  diverges from source commit `8c2a815` by the local `--tldr` flag.
  `workflow/scripts/make_igv_genome_README.md:15`

- [x] Add `--tldr` to: `make_igv_genome.sh`. New pre-commit-hooks v0.4.0 hooks
  (`{r-script,py,sh}-tldr`) require each script to exit 0 and print non-empty
  output on `--tldr`: a tldr-pages-style summary (imperative one-liner + ~5
  example invocations using literal example values, colored to match `tldr
  <cmd>`'s rendering -- green description / cyan command / underlined-cyan
  args, auto-off on non-tty -- <=40 lines total, doesn't need to be exhaustive,
  must not contradict this repo's README). Load the `tldr` skill for the exact
  ANSI scheme, the `@token` marker helper, and the per-language wiring pattern
  (docopt `Options:` entry for `.r`, `argparse` flag for `.py`, `case` branch
  for `.sh`). Reference implementation: `metaboanalystr_pca_plsda` (pilot repo,
  done). Also bump this repo's `.pre-commit-config.yaml`
  Marc-commits/pre-commit-hooks `rev` to `v0.4.0` and add the matching `*-tldr`
  hook id(s).

- [ ] Confirm a self-hosted runner labeled 'self-hosted' is registered and
      that this repo's first PR exercises .github/workflows/pre-commit.yml
      end-to-end.
