#!/usr/bin/env bash
# Register this checkout with Grok and install each plugin with trust.
#
#   ./scripts/install.sh           marketplace add + install/trust plugins
#   ./scripts/install.sh --paths   same install, and append [plugins].paths
#
# A path entry does not enable a plugin. Grok leaves path-only plugins
# disabled, so skills load only from the trusted install under $GROK_HOME.
# Re-running replaces an existing snapshot from this checkout.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GROK_HOME="${GROK_HOME:-$HOME/.grok}"
CONFIG="$GROK_HOME/config.toml"
PLUGINS=(core ai go typescript git)
MODE="marketplace"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--paths|--marketplace]

  --marketplace  (default) grok plugin marketplace add + install --trust
  --paths        also append plugin dirs to [plugins].paths in $CONFIG

Path entries do not load skills. Both modes install and trust every plugin.
Re-running refreshes an installed snapshot from this checkout.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --paths) MODE="paths" ;;
    --marketplace) MODE="marketplace" ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done

chmod_scripts() {
  local f
  while IFS= read -r f; do
    chmod +x "$f"
  done < <(find "$ROOT/plugins" \( -path '*/hooks/bin/*' -o -path '*/skills/*/scripts/*' \) -type f)
  chmod +x "$ROOT/scripts/install.sh" "$ROOT/scripts/validate.sh"
  if [ -f "$ROOT/shell/install.sh" ]; then
    chmod +x "$ROOT/shell/install.sh"
  fi
  if [ -d "$ROOT/shell/bin" ]; then
    find "$ROOT/shell/bin" -type f ! -name '.gitkeep' -exec chmod +x {} +
  fi
}

append_plugin_paths() {
  local block
  block=$(
    cat <<EOF

# personal-skills ($ROOT)
[plugins]
paths = [
  "$ROOT/plugins/core",
  "$ROOT/plugins/ai",
  "$ROOT/plugins/go",
  "$ROOT/plugins/typescript",
  "$ROOT/plugins/git",
]
enabled = ["core", "ai", "go", "typescript", "git"]
EOF
  )

  if [ -f "$CONFIG" ] && grep -q "$ROOT/plugins/core" "$CONFIG"; then
    echo "config already lists $ROOT/plugins/core"
    return 0
  fi

  if [ -f "$CONFIG" ] && grep -q '^\[plugins\]' "$CONFIG"; then
    echo "Refusing to edit $CONFIG: a [plugins] table already exists." >&2
    echo "Add these paths under [plugins].paths and enable the plugins:" >&2
    printf '%s\n' "$block" >&2
    return 1
  fi

  mkdir -p "$GROK_HOME"
  if [ ! -f "$CONFIG" ]; then
    printf '%s\n' "$block" | sed '1{/^$/d;}' >"$CONFIG"
  else
    printf '%s\n' "$block" >>"$CONFIG"
  fi
  echo "updated $CONFIG"
}

install_marketplace() {
  if ! command -v grok >/dev/null 2>&1; then
    echo "grok is not on PATH; chmod'd scripts only." >&2
    echo "Install grok, then re-run." >&2
    return 1
  fi

  if grok plugin marketplace add "$ROOT"; then
    echo "added marketplace $ROOT"
  else
    echo "marketplace add failed (it may already be registered); continuing"
  fi

  local name
  for name in "${PLUGINS[@]}"; do
    install_one "$name"
  done
}

install_one() {
  local name="$1"
  local src="$ROOT/plugins/$name"

  if grok plugin details "$name" >/dev/null 2>&1; then
    echo "refreshing $name from $src"
    grok plugin uninstall "$name" --confirm --keep-data
  else
    echo "installing $name from $src"
  fi

  grok plugin install "$src" --trust
  grok plugin enable "$name" || true
}

chmod_scripts
echo "made hook and skill scripts executable"

case "$MODE" in
  paths)
    # A listed path stays disabled. Still install so skills can load.
    append_plugin_paths || true
    install_marketplace
    ;;
  marketplace) install_marketplace ;;
esac

echo
echo "Next: restart Grok, or press r in the Plugins tab, then grok inspect"
echo "Validate with: $ROOT/scripts/validate.sh"
echo "Interactive shell helpers: $ROOT/shell/install.sh"
