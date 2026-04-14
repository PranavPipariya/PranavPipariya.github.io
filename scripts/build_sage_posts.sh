#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAGE_DIR="$ROOT_DIR/sage"
GENERATED_DIR="$ROOT_DIR/_includes/generated"
SAGE_BIN="${SAGE_BIN:-sage}"

if [[ ! -d "$SAGE_DIR" ]]; then
  echo "Missing sage directory: $SAGE_DIR" >&2
  exit 1
fi

mkdir -p "$GENERATED_DIR"

run_one() {
  local slug="$1"
  local source_file="$SAGE_DIR/$slug.sage"

  if [[ ! -f "$source_file" ]]; then
    echo "No Sage source found for slug '$slug' at $source_file" >&2
    return 1
  fi

  echo "Building Sage output for '$slug'..."
  if ! "$SAGE_BIN" "$source_file"; then
    cat <<'EOF' >&2

SageMath did not run successfully.
If you're on macOS and see a permission/reconfigure message, open the SageMath app once:
  /Applications/SageMath-10-8.app
Then rerun this command.
EOF
    return 1
  fi
}

if [[ $# -gt 0 ]]; then
  for slug in "$@"; do
    run_one "$slug"
  done
else
  shopt -s nullglob
  found_any=false
  for source_file in "$SAGE_DIR"/*.sage; do
    found_any=true
    run_one "$(basename "$source_file" .sage)"
  done

  if [[ "$found_any" == false ]]; then
    echo "No .sage files found in $SAGE_DIR" >&2
    exit 1
  fi
fi

echo "Sage build complete."
