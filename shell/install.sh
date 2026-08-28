#!/usr/bin/env bash
# Install interactive zsh/bash helpers from this checkout into rc files.
#
#   ./shell/install.sh              source zsh + bash inits; put bin on PATH
#   ./shell/install.sh --zsh        only ~/.zshrc (or $ZDOTDIR/.zshrc)
#   ./shell/install.sh --bash       only ~/.bashrc
#   ./shell/install.sh --uninstall  remove the managed blocks
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHELL_DIR="$ROOT/shell"
MARKER_START="# >>> personal-skills shell >>>"
MARKER_END="# <<< personal-skills shell <<<"

ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
BASHRC="${HOME}/.bashrc"

DO_ZSH=0
DO_BASH=0
UNINSTALL=0
EXPLICIT=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [--zsh] [--bash] [--uninstall]

  (no flags)     install for every shell that is on PATH
  --zsh          install the zsh init into $ZSHRC
  --bash         install the bash init into $BASHRC
  --uninstall    remove the managed block from those rc files

Sourced inits live in this checkout. Moving the repo means re-running this.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --zsh) DO_ZSH=1; EXPLICIT=1 ;;
    --bash) DO_BASH=1; EXPLICIT=1 ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
  shift
done

if [ "$EXPLICIT" -eq 0 ]; then
  command -v zsh >/dev/null 2>&1 && DO_ZSH=1
  command -v bash >/dev/null 2>&1 && DO_BASH=1
fi

if [ "$DO_ZSH" -eq 0 ] && [ "$DO_BASH" -eq 0 ]; then
  echo "no zsh or bash on PATH; pass --zsh and/or --bash" >&2
  exit 1
fi

path_snippet() {
  cat <<EOF
case ":\$PATH:" in
  *":$SHELL_DIR/bin:"*) ;;
  *) PATH="$SHELL_DIR/bin:\$PATH" ;;
esac
export PATH
EOF
}

zsh_block() {
  cat <<EOF
# Interactive helpers from $ROOT
if [ -r "$SHELL_DIR/zsh/init.zsh" ]; then
  . "$SHELL_DIR/zsh/init.zsh"
fi
$(path_snippet)
EOF
}

bash_block() {
  cat <<EOF
# Interactive helpers from $ROOT
if [ -r "$SHELL_DIR/bash/init.bash" ]; then
  . "$SHELL_DIR/bash/init.bash"
fi
$(path_snippet)
EOF
}

upsert_block() {
  local rcfile="$1"
  local inner="$2"
  local block tmp
  block="${MARKER_START}
${inner}
${MARKER_END}"
  mkdir -p "$(dirname "$rcfile")"
  touch "$rcfile"
  tmp="$(mktemp)"
  if grep -qF "$MARKER_START" "$rcfile"; then
    awk -v start="$MARKER_START" -v end="$MARKER_END" -v block="$block" '
      $0 == start { print block; skip=1; next }
      skip { if ($0 == end) skip=0; next }
      { print }
    ' "$rcfile" >"$tmp"
    mv "$tmp" "$rcfile"
    echo "updated $rcfile"
  else
    printf '\n%s\n' "$block" >>"$rcfile"
    rm -f "$tmp"
    echo "appended $rcfile"
  fi
}

remove_block() {
  local rcfile="$1"
  local tmp
  if [ ! -f "$rcfile" ] || ! grep -qF "$MARKER_START" "$rcfile"; then
    echo "no managed block in $rcfile"
    return 0
  fi
  tmp="$(mktemp)"
  awk -v start="$MARKER_START" -v end="$MARKER_END" '
    $0 == start { skip=1; next }
    skip { if ($0 == end) skip=0; next }
    { print }
  ' "$rcfile" >"$tmp"
  mv "$tmp" "$rcfile"
  echo "removed block from $rcfile"
}

if [ "$UNINSTALL" -eq 1 ]; then
  [ "$DO_ZSH" -eq 1 ] && remove_block "$ZSHRC"
  [ "$DO_BASH" -eq 1 ] && remove_block "$BASHRC"
  echo "uninstalled. open a new shell (or source the rc file) to drop functions."
  exit 0
fi

[ "$DO_ZSH" -eq 1 ] && upsert_block "$ZSHRC" "$(zsh_block)"
[ "$DO_BASH" -eq 1 ] && upsert_block "$BASHRC" "$(bash_block)"

echo
echo "Open a new shell, or: source $ZSHRC   /   source $BASHRC"
echo "Try: how list files modified today"
echo "Uninstall: $SHELL_DIR/install.sh --uninstall"
