#!/usr/bin/env bash
# Build game-forge.zip for uploading as a claude.ai account skill (works in every cloud and CLI session).
# Usage: bash tools/package_skill.sh [out_dir]    (default: ./dist)
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
out="${1:-$root/dist}"; mkdir -p "$out"
src="$root/plugins/game-forge/skills"
ver="$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$root/plugins/game-forge/.claude-plugin/plugin.json")"
zip="$out/game-forge-$ver.zip"; rm -f "$zip"
# frontmatter may only use the fields uploads accept
fm="$(awk '/^---$/{n++; next} n==1' "$src/game-forge/SKILL.md" | sed -n 's/^\([a-z_-]*\):.*/\1/p')"
for k in $fm; do case "$k" in name|description|license|compatibility|metadata|allowed-tools) ;; *) echo "SKILL.md frontmatter field '$k' is not accepted by uploads" >&2; exit 1;; esac; done
(cd "$src" && zip -qr "$zip" game-forge -x '*/.DS_Store' '*/node_modules/*')
echo "$zip ($(du -h "$zip" | cut -f1), $(unzip -l "$zip" | tail -1 | awk '{print $2}') files)"
