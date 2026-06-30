#!/bin/sh
# Install dream-warden runtime files into a host project (default: .workflow/_dream).
# Copies only what installed mode needs — no dev fixtures, demos, or contributor tooling.
#
# From your project root:
#   git clone --depth 1 https://github.com/<your-user>/dream-warden /tmp/dream-warden
#   /tmp/dream-warden/install.sh .workflow/_dream
#   .workflow/_dream/install-hook.sh
#   rm -rf /tmp/dream-warden
#
# Or, from a dream-warden checkout:
#   ./install.sh /path/to/your-project/.workflow/_dream
set -e
src=$(cd "$(dirname "$0")" && pwd)
dest="${1:-.workflow/_dream}"
mkdir -p "$dest"

copy_tree() {
  name=$1
  rm -rf "$dest/$name"
  cp -R "$src/$name" "$dest/$name"
}

for name in bin hooks prompts; do
  copy_tree "$name"
done

for name in playbook.md playbook.digest.md CONTRACT.md README.md LICENSE install-hook.sh install.sh; do
  cp "$src/$name" "$dest/$name"
done

mkdir -p "$dest/queue" "$dest/proposals/approved" "$dest/ledger"
echo "installed dream-warden runtime -> $dest"
