#!/bin/sh
# Copy contributor fixtures into .workflow/<slug>/ for standalone dry-runs.
# Run from the dream-warden repo root:
#   dev/bootstrap-workflow.sh
set -e
root=$(git rev-parse --show-toplevel)
src="$root/dev/fixtures/demo-feature-001"
dest="$root/.workflow/demo-feature-001"
mkdir -p "$dest"
cp -r "$src/." "$dest/"
echo "bootstrapped $dest (gitignored; safe to delete)"
