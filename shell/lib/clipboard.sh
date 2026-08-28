# Shared clipboard helper. Sourced by zsh and bash inits.
# Prefers Wayland, then X11, then macOS pbcopy. Returns 1 if none work.

_ps_copy() {
  if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$1" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$1" | xclip -selection clipboard
  elif command -v xsel >/dev/null 2>&1; then
    printf '%s' "$1" | xsel --clipboard --input
  elif command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$1" | pbcopy
  else
    return 1
  fi
}
