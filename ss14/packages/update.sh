#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./update.sh ss14-watchdog
#   ./update.sh robust-cdn v2.1.0
#   ./update.sh all

ALL_PACKAGES=("ss14-watchdog" "robust-cdn" "ss14-admin")

update_package() {
  local pkg="$1"
  local version="${2:-}"

  echo "=== Updating $pkg ${version:+(to $version)} ==="

  local update_args=("-f" "default.nix")
  [[ -n "$version" ]] && update_args+=("--version" "$version")
  
  echo " -> Bumping source..."
  nix run "nixpkgs#nix-update" -- "${update_args[@]}" "$pkg"

  echo " -> Fetching NuGet dependencies..."
  $(nix-build default.nix -A "$pkg.fetch-deps" --no-out-link)

  echo " -> Verifying build..."
  nix-build default.nix -A "$pkg" --no-out-link > /dev/null

  echo "=== Successfully updated: $pkg ==="
  echo
}

main() {
  cd "$(dirname "$0")"

  local target="${1:-}"
  local version="${2:-}"

  if [[ -z "$target" ]]; then
    echo "Usage: $0 <package|all> [version]" >&2
    exit 1
  fi

  if [[ "$target" == "all" ]]; then
    for pkg in "${ALL_PACKAGES[@]}"; do
      update_package "$pkg"
    done
  else
    update_package "$target" "$version"
  fi
}

main "$@"
