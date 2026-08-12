#!/usr/bin/env bash
set -euo pipefail

local_dir="${XOURNALPP_LOCAL_CONFIG:-$HOME/.config/nixos/xournalpp}"
repo_dir="${1:-${XOURNALPP_REPO:-$HOME/.config/nixos/xournal-conf}}"

if [[ ! -d "$local_dir" ]]; then
  printf 'Diretório local não encontrado: %s\n' "$local_dir" >&2
  printf 'Execute primeiro uma ativação do Home Manager/NixOS.\n' >&2
  exit 1
fi
if [[ ! -d "$repo_dir/.git" ]]; then
  printf 'Checkout Git do xournal-conf não encontrado: %s\n' "$repo_dir" >&2
  printf 'Uso: %s /caminho/para/xournal-conf\n' "$0" >&2
  exit 1
fi

for file in settings.xml toolbar.ini; do
  source="$local_dir/$file"
  destination="$repo_dir/xournalpp/$file"
  if [[ ! -f "$source" ]]; then
    printf 'Arquivo local não encontrado: %s\n' "$source" >&2
    exit 1
  fi
  install -m 0644 "$source" "$destination"
  printf 'Sincronizado: %s -> %s\n' "$source" "$destination"
done

printf '\nRevise as alterações antes de publicar:\n'
git -C "$repo_dir" diff -- xournalpp/settings.xml xournalpp/toolbar.ini
git -C "$repo_dir" status --short
printf '\nDepois de revisar, execute no checkout:\n'
printf '  git add xournalpp/settings.xml xournalpp/toolbar.ini\n'
printf '  git commit -m "xournalpp: update user configuration"\n'
printf '  git push origin main\n'
