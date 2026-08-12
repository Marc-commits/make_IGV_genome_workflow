test:
    pytest .tests/unit/
    bats -rT tests/

version-map:
    grep -riHne "version:\s" $(git ls-tree -r HEAD --name-only | grep -v "^\.") 2>/dev/null > .version-map

env:
    find workflow/envs/ -type f -iname "*.yaml" -print0 | xargs -0 -P 1 -I {} sh -c 'conda env create  --solver libmamba --dry-run --prefix "$(mktemp -d)" -f "{}"'
    snakedeploy pin-conda-envs workflow/envs/*.yaml

lint: env
    snakemake --lint
