#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FORCE=0
[[ "${1-}" == "--force" ]] && FORCE=1

make_if_missing() {
  local src="$1" dst="$2" desc="$3" role_name="$4" collection_name="$5"
  if [[ -f "$dst" && $FORCE -eq 0 ]]; then
    echo "⏭️  $desc exists: $dst"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  sed -e "s/\${ROLE_NAME}/$role_name/g" \
      -e "s/\${COLLECTION_NAME}/$collection_name/g" \
      "$src" > "$dst"
  echo "✅ Generated $desc: $dst"
}

setup_molecule_for_role() {
  local role_path="$1" role_name="$2" collection_name="$3"

  echo "🔧 Role: $role_name"

  # molecule.yml
  make_if_missing "$SCRIPT_DIR/molecule.yml.template" \
    "$role_path/molecule/default/molecule.yml" "molecule.yml" "$role_name" "$collection_name"

  # prepare.yml
  make_if_missing "$SCRIPT_DIR/prepare.yml.template" \
    "$role_path/molecule/default/prepare.yml" "prepare.yml" "$role_name" "$collection_name"

  # converge.yml
  make_if_missing "$SCRIPT_DIR/converge.yml.template" \
    "$role_path/molecule/default/converge.yml" "converge.yml" "$role_name" "$collection_name"

  # verify.yml
  make_if_missing "$SCRIPT_DIR/verify.yml.template" \
    "$role_path/molecule/default/verify.yml" "verify.yml" "$role_name" "$collection_name"

  # requirements.yml
  if [[ -f "$SCRIPT_DIR/requirements.yml.template" ]]; then
    if [[ ! -f "$role_path/molecule/default/requirements.yml" || $FORCE -eq 1 ]]; then
      cp "$SCRIPT_DIR/requirements.yml.template" "$role_path/molecule/default/requirements.yml"
      echo "✅ Copied requirements.yml"
    else
      echo "⏭️  requirements.yml exists"
    fi
  fi
}

echo "Processing yamisskey.appliances..."
for d in "$PROJECT_ROOT/ansible_collections/yamisskey/appliances/roles"/*; do
  [[ -d "$d" && "$(basename "$d")" != "README.md" ]] && \
    setup_molecule_for_role "$d" "$(basename "$d")" "yamisskey.appliances"
done

echo "Processing yamisskey.servers..."
for d in "$PROJECT_ROOT/ansible_collections/yamisskey/servers/roles"/*; do
  [[ -d "$d" && "$(basename "$d")" != "README.md" ]] && \
    setup_molecule_for_role "$d" "$(basename "$d")" "yamisskey.servers"
done

echo "🎉 Done. Use --force to overwrite existing files if needed."
