# Sourced from ~/.zshrc by shell/install.sh. Loads lib + zsh functions.

_ps_zsh_dir="${${(%):-%x}:A:h}"
_ps_shell_root="${_ps_zsh_dir:h}"

. "$_ps_shell_root/lib/clipboard.sh"
. "$_ps_shell_root/lib/how-query.sh"

for _ps_f in "$_ps_zsh_dir/functions/"*.zsh(N); do
  . "$_ps_f"
done
unset _ps_f _ps_zsh_dir _ps_shell_root
