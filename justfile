test: dry
    pytest .tests/unit/
    bats -rT tests/

version-map:
    grep -riHne "version:\s" $(git ls-tree -r HEAD --name-only | grep -v "^\.") 2>/dev/null > .version-map

env:
    find workflow/envs/ -type f -iname "*.yaml" -print0 | xargs -0 -P 1 -I {} sh -c 'conda env create  --solver libmamba --dry-run --prefix "$(mktemp -d)" -f "{}"'

dry:
    snakemake -n --configfile config/config.yaml

pre-commit:
    pre-commit run --all-files

pin-env: env
    snakedeploy pin-conda-envs workflow/envs/*.yaml

lint: dry
    snakemake --lint
    pre-commit run readme-no-local-paths --files README.md
    pre-commit run readme-url-check --files README.md
    snakefmt --check Snakefile
    snakefmt --check workflow/rules/

fmt:
    snakefmt Snakefile
    snakefmt workflow/rules/
