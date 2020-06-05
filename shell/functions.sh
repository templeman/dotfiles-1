# shell/functions.sh

export DKO_SOURCE="${DKO_SOURCE} -> shell/functions.sh"

# ============================================================================
# Scripting
# ============================================================================

current_shell() {
  ps -p $$ | awk 'NR==2 { print $4 }'
}

# ============================================================================
# Directory
# ============================================================================

# Go to git root
cdr() {
  git rev-parse || return 1
  cd -- "$(git rev-parse --show-cdup)" || return 1
}

# ============================================================================
# edit
# This is usually overridden in ./after.sh
# ============================================================================

e() {
  if __dko_has nvim && __dko_has nvctl && pgrep nvim >/dev/null; then
    for file in "$@"; do
      # don't prepend PWD for absolute paths
      case "$file" in
        /*) ;;
        *) file="${PWD}/${file}" ;;
      esac
      nvctl "e ${file}" && wait
    done
  else
    "$EDITOR" "$@"
  fi
}

# ============================================================================
# edit upwards
# ============================================================================

eu() {
  end="/"
  gitroot=$(git rev-parse --show-cdup || echo '')
  [ -d "$gitroot" ] && end="$gitroot"
  x=$(pwd)
  while [ "$x" != "$end" ] ; do
    result="$(find "$x" -maxdepth 1 -name "$1")"
    [ -f "$result" ] && {
      e "$result"
      return $?
    }
    x=$(dirname "$x")
  done
  return 1
}

# ============================================================================
# dev
# ============================================================================

batdiff() {
  git diff --name-only --diff-filter=d 2>/dev/null | xargs bat --diff
}

# git or git status
g() {
  if [ $# -gt 0 ]; then
    git "$@"
  else
    git status --short --branch
  fi
}

# Update composer packages without cache
cunt() {
  COMPOSER_CACHE_DIR=/dev/null composer update
}

# ============================================================================
# Archiving
# ============================================================================

# Export repo files to specified dir
gitexport() {
  to_dir="${2:-./gitexport}"
  rsync -a "${1:-./}" "$to_dir" --exclude "$to_dir" --exclude .git
}

# ============================================================================
# Network tools
# ============================================================================

# Copy ssh key to clipboard
mykey() {
  enc="${1:-id_ed25519}"
  pubkey="${HOME}/.ssh/${enc}.pub"
  [ ! -f "${pubkey}" ] && {
    (echo >&2 "Could not find public key ${pubkey}")
    exit 1
  }

  command cat "$pubkey"
  echo

  if __dko_has "pbcopy"; then
    pbcopy <"$pubkey"
    echo "Copied to clipboard"
  elif __dko_has "xclip"; then
    xclip "$pubkey"
    echo "Copied to clipboard"
  fi
}
