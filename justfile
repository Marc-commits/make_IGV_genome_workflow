test:
    pytest .tests/unit/
    bats -rT tests/

version-map:
    grep -riHne "version:\s" $(git ls-tree -r HEAD --name-only | grep -v "^\.") 2>/dev/null > .version-map
