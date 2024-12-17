set shell := ["bash", "-euo", "pipefail", "-c"]

[private]
@default: build

export DOCKER_CLI_HINTS := "false"

image_name := "ghcr.io/githedgehog/hhdocs"
image_version := "20241202"
image := image_name + ":" + image_version

# Run mkdocs or mike CLI in a container
_run +cmd:
  docker run -q --pull=always --rm -v $(pwd):/docs -p 8000:8000 {{image}} {{cmd}}

# Build docs site (unversioned)
build: (_run "mkdocs build")

# Clean generated docs site
clean:
  rm -rf site

# Serve docs site (unversioned, watches for changes)
serve: (_run "mkdocs serve -a 0.0.0.0:8000")

# List published versions
list: (_run "mike list -b publish")

branch_current := `git branch --show-current --format "%(refname:short)"`
branch_latest := `git branch --list 'release/2*' --format "%(refname:short)" --sort=-version:refname | head -n 1`
release := trim_start_match(branch_current, "release/")

_release := if branch_current == "master" { "dev" } else { release }
_alias := if branch_current == branch_latest { "latest" } else if branch_current == "master" { "master" } else { "" }

# Shoud version that will be deployed (to publish branch)
@version:
  echo "Release '{{_release}}' alias '{{_alias}}'"

# Deploy docs site (versioned) to publish branch
deploy release=_release alias=_alias: (_run "mike deploy -b publish -u" release alias)
