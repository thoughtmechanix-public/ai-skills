# Sourced from ~/.bashrc by shell/install.sh. Loads lib + bash functions.

_ps_bash_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
_ps_shell_root="$(cd -- "$_ps_bash_dir/.." && pwd)"

. "$_ps_shell_root/lib/clipboard.sh"
. "$_ps_shell_root/lib/how-query.sh"

for _ps_f in "$_ps_bash_dir/functions/"*.bash; do
  [ -f "$_ps_f" ] && . "$_ps_f"
done
unset _ps_f _ps_bash_dir _ps_shell_root
