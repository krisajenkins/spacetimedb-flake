#!/usr/bin/env bash
# Point sources.json at a SpacetimeDB release and re-hash every platform tarball.
#
#   ./update.sh            # latest upstream release
#   ./update.sh 2.14.0     # a specific version (a leading 'v' is fine)
#
# Exits 0 without changes if already at that version. Set GITHUB_TOKEN to avoid
# the API's anonymous rate limit.
set -euo pipefail
cd "$(dirname "$0")"

repo=clockworklabs/SpacetimeDB

if [[ $# -gt 0 ]]; then
  version=$1
else
  version=$(curl -fsSL ${GITHUB_TOKEN:+-H "Authorization: Bearer $GITHUB_TOKEN"} \
    "https://api.github.com/repos/$repo/releases/latest" | jq -r .tag_name)
fi
version=${version#v}

current=$(jq -r .version sources.json)
if [[ $version == "$current" ]]; then
  echo "Already at $version"
  exit 0
fi

json=$(jq --arg v "$version" '.version = $v' sources.json)
for system in $(jq -r '.platforms | keys[]' sources.json); do
  target=$(jq -r --arg s "$system" '.platforms[$s].target' sources.json)
  url="https://github.com/$repo/releases/download/v$version/spacetime-$target.tar.gz"
  hash=$(nix store prefetch-file --json "$url" | jq -r .hash)
  echo "$system  $hash"
  json=$(jq --arg s "$system" --arg h "$hash" '.platforms[$s].hash = $h' <<<"$json")
done

# Write only once every platform hashed, so a failed download leaves no half-update.
printf '%s\n' "$json" >sources.json
echo "Updated $current -> $version"
