#!/usr/bin/env bash
set -euo pipefail

DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

DRY_RUN=0
BACKUP=0
INSTALL_SYSTEM=0
COMMON_ONLY=0
HOST_OVERRIDE=""

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Links common dotfiles and host-specific configs from:
  $DOTDIR/common/
  $DOTDIR/hosts/<hostname>/

Options:
  -n, --dry-run       Show what would change without modifying anything
      --host NAME     Override detected hostname (default: /etc/hostname)
      --common-only   Only install common/ links (skip hosts/<hostname>/)
      --system        Also install hosts/<hostname>/etc/* files via sudo
      --backup        Back up conflicting regular files/dirs (*.bak.<ts>) before linking
  -h, --help          Show this help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--dry-run)    DRY_RUN=1 ;;
    --backup)        BACKUP=1 ;;
    --system)        INSTALL_SYSTEM=1 ;;
    --common-only)   COMMON_ONLY=1 ;;
    --host)
      shift
      [ $# -gt 0 ] || { echo "Error: --host requires a value" >&2; exit 2; }
      HOST_OVERRIDE="$1"
      ;;
    -h|--help)       usage; exit 0 ;;
    *)               echo "Error: unknown option '$1'" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [ -n "$HOST_OVERRIDE" ]; then
  HOSTNAME_ID="$HOST_OVERRIDE"
elif [ -r /etc/hostname ]; then
  HOSTNAME_ID="$(tr -d '[:space:]' < /etc/hostname)"
else
  HOSTNAME_ID="$(hostname -s)"
fi

declare -A MANAGED_DSTS=()
CNT_LINK=0
CNT_UPDATE=0
CNT_OK=0
CNT_SKIP=0
CNT_PRUNE=0
CNT_SYS=0

ensure_dir() {
  local dir="$1"
  local mode="${2:-}"
  [ -d "$dir" ] && return 0
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '  [mkdir]  %s\n' "$dir"
  else
    if [ -n "$mode" ]; then
      mkdir -m "$mode" -p "$dir"
    else
      mkdir -p "$dir"
    fi
  fi
}

link() {
  local rel_src="$1"
  local dst="$2"
  local src="$DOTDIR/$rel_src"
  local parent cur bak

  if [ ! -e "$src" ]; then
    printf '  [ERROR]  missing source: %s\n' "$src" >&2
    return 1
  fi

  MANAGED_DSTS["$dst"]=1
  parent="$(dirname "$dst")"

  if [ -L "$dst" ]; then
    cur="$(readlink "$dst")"
    if [ "$cur" = "$src" ]; then
      CNT_OK=$((CNT_OK + 1))
      return 0
    fi
    if [[ "$cur" == "$DOTDIR/"* ]] || [ ! -e "$dst" ]; then
      printf '  [update] %s -> %s (was: %s)\n' "$dst" "$rel_src" "$cur"
      if [ "$DRY_RUN" -eq 0 ]; then
        rm "$dst"
        ln -s "$src" "$dst"
      fi
      CNT_UPDATE=$((CNT_UPDATE + 1))
      return 0
    fi
    if [ "$BACKUP" -eq 1 ]; then
      bak="${dst}.bak.${STAMP}"
      printf '  [backup] %s -> %s\n' "$dst" "$bak"
      printf '  [link]   %s -> %s\n' "$dst" "$rel_src"
      if [ "$DRY_RUN" -eq 0 ]; then
        mv "$dst" "$bak"
        ln -s "$src" "$dst"
      fi
      CNT_LINK=$((CNT_LINK + 1))
    else
      printf '  [skip]   %s points elsewhere (%s) — use --backup to replace\n' "$dst" "$cur"
      CNT_SKIP=$((CNT_SKIP + 1))
    fi
    return 0
  fi

  if [ -e "$dst" ]; then
    if [ "$BACKUP" -eq 1 ]; then
      bak="${dst}.bak.${STAMP}"
      printf '  [backup] %s -> %s\n' "$dst" "$bak"
      printf '  [link]   %s -> %s\n' "$dst" "$rel_src"
      if [ "$DRY_RUN" -eq 0 ]; then
        mv "$dst" "$bak"
        ln -s "$src" "$dst"
      fi
      CNT_LINK=$((CNT_LINK + 1))
    else
      printf '  [skip]   %s exists (not a symlink) — use --backup to replace\n' "$dst"
      CNT_SKIP=$((CNT_SKIP + 1))
    fi
    return 0
  fi

  ensure_dir "$parent"
  printf '  [link]   %s -> %s\n' "$dst" "$rel_src"
  if [ "$DRY_RUN" -eq 0 ]; then
    ln -s "$src" "$dst"
  fi
  CNT_LINK=$((CNT_LINK + 1))
}

system_file() {
  local rel_src="$1"
  local dst="$2"
  local src="$DOTDIR/$rel_src"

  if [ ! -f "$src" ]; then
    printf '  [ERROR]  missing system source: %s\n' "$src" >&2
    return 1
  fi

  if [ "$INSTALL_SYSTEM" -eq 0 ]; then
    if [ ! -f "$dst" ] || ! cmp -s "$src" "$dst"; then
      printf '  [sys]    %s differs/missing (pass --system to install)\n' "$dst"
    fi
    return 0
  fi

  if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
    CNT_OK=$((CNT_OK + 1))
    return 0
  fi

  printf '  [sudo]   %s -> %s\n' "$rel_src" "$dst"
  if [ "$DRY_RUN" -eq 0 ]; then
    sudo install -D -m 644 "$src" "$dst"
  fi
  CNT_SYS=$((CNT_SYS + 1))
}

prune_dangling() {
  local dir p target
  for dir in "$HOME" "$HOME/.config" "$HOME/.config/nvim" "$HOME/.local/share/wm" "$HOME/.local/bin"; do
    [ -d "$dir" ] || continue
    while IFS= read -r -d '' p; do
      [ -e "$p" ] && continue
      [ -n "${MANAGED_DSTS[$p]:-}" ] && continue
      target="$(readlink "$p")"
      case "$target" in
        "$DOTDIR"/*)
          printf '  [prune]  %s (broken -> %s)\n' "$p" "$target"
          if [ "$DRY_RUN" -eq 0 ]; then
            rm "$p"
          fi
          CNT_PRUNE=$((CNT_PRUNE + 1))
          ;;
      esac
    done < <(find "$dir" -maxdepth 1 -type l -print0 2>/dev/null)
  done
}

printf 'dotfiles: %s | host: %s%s\n' "$DOTDIR" "$HOSTNAME_ID" "$([ "$DRY_RUN" -eq 1 ] && printf ' (dry-run)' || true)"

echo '==> common'
# shellcheck source=common/links.sh
source "$DOTDIR/common/links.sh"

if [ "$COMMON_ONLY" -eq 0 ]; then
  host_manifest="$DOTDIR/hosts/$HOSTNAME_ID/links.sh"
  if [ -f "$host_manifest" ]; then
    printf '==> host: %s\n' "$HOSTNAME_ID"
    # shellcheck disable=SC1090
    source "$host_manifest"
  else
    printf '==> host: %s (no hosts/%s/links.sh — skipping host-specific configs)\n' "$HOSTNAME_ID" "$HOSTNAME_ID"
  fi
fi

echo '==> cleanup'
prune_dangling

printf 'Summary: %d linked, %d updated, %d ok, %d pruned, %d skipped, %d system\n' \
  "$CNT_LINK" "$CNT_UPDATE" "$CNT_OK" "$CNT_PRUNE" "$CNT_SKIP" "$CNT_SYS"
