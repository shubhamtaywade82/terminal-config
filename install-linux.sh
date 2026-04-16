#!/usr/bin/env bash
# One-shot installer for the stack in modern-terminal-stack.md — Linux (apt).
# Targets Debian/Ubuntu and WSL2; does not configure Git remotes or sign in to hosted services.
#
# Re-runs: safe. apt skips already-installed packages; curl installers are idempotent where upstream allows.
#
# Usage:
#   ./install-linux.sh              # apt core + optional apt extras + fzf snippet + PATH helpers + Claude Code (if npm)
#   ./install-linux.sh --dry-run    # print what would run
#   ./install-linux.sh --help
#
# Flags:
#   --dry-run            print commands only
#   --skip-optional      skip lazygit + neovim (+ eza if only via optional path)
#   --skip-claude        skip npm global @anthropic-ai/claude-code
#   --skip-fzf-setup     skip writing ~/.fzf.zsh for Debian fzf paths
#   --dotfiles-status    print whether common config files exist (no apt; no file changes except see fzf)
#
# Environment (optional):
#   INSTALL_LINUX_APT_ATTEMPTS   max tries for core apt update+install (default: 3)
#   INSTALL_LINUX_APT_RETRY_SLEEP seconds between tries (default: 8)

set -euo pipefail

DRY_RUN=0
SKIP_OPTIONAL=0
SKIP_CLAUDE=0
SKIP_FZF_SETUP=0
DOTFILES_STATUS=0

log() { printf '%s\n' "$*"; }
err() { printf 'ERROR: %s\n' "$*" >&2; }

usage() {
  cat <<'EOF'
Usage: ./install-linux.sh [options]

  One-shot apt-based install for modern-terminal-stack.md (Debian/Ubuntu/WSL).

Options:
  --dry-run            print commands only
  --skip-optional      skip lazygit, neovim, and eza (when not already on PATH)
  --skip-claude        skip npm install -g @anthropic-ai/claude-code
  --skip-fzf-setup     skip writing ~/.fzf.zsh for Debian/Ubuntu fzf paths
  --dotfiles-status    list common config paths + merge hints (no apt; no changes)
  -h, --help           show this help

Environment:
  INSTALL_LINUX_APT_ATTEMPTS     core apt retries (default: 3)
  INSTALL_LINUX_APT_RETRY_SLEEP seconds between retries (default: 8)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --skip-optional) SKIP_OPTIONAL=1 ;;
    --skip-claude) SKIP_CLAUDE=1 ;;
    --skip-fzf-setup) SKIP_FZF_SETUP=1 ;;
    --dotfiles-status) DOTFILES_STATUS=1 ;;
    -h|--help) usage; exit 0 ;;
    *)
      err "unknown option: $1"
      usage >&2
      exit 1
      ;;
  esac
  shift
done

report_dotfiles_status() {
  local f lines
  log ""
  log "==> Dotfile / config status (nothing here is modified by install-linux.sh)"
  log ""
  dotline() {
    f="$1"
    if [[ -f "$f" ]]; then
      lines=$(wc -l <"$f" | tr -d ' ')
      log "  [exists]  $lines lines  $f"
    elif [[ -d "$f" ]]; then
      log "  [dir]              $f"
    else
      log "  [missing]          $f"
    fi
  }
  dotline "${ZDOTDIR:-$HOME}/.zshrc"
  dotline "$HOME/.zshenv"
  dotline "$HOME/.zprofile"
  dotline "$HOME/.fzf.zsh"
  dotline "$HOME/.config/starship.toml"
  dotline "$HOME/.config/atuin/config.toml"
  dotline "$HOME/.cursor/cli-config.json"
  log ""
  log "Merge strategy (see modern-terminal-stack.md § “Existing config files”):"
  log "  • Never replace whole ~/.zshrc — add a single source line to a tracked snippet, or merge by hand."
  log "  • Starship: merge TOML into one file, or set STARSHIP_CONFIG to an alternate path for experiments."
  log "  • fzf: on Debian/Ubuntu, install-linux.sh writes ~/.fzf.zsh sourcing /usr/share/doc/fzf/examples/*.zsh."
  log "  • Atuin: avoid running eval \"\$(atuin init zsh)\" twice; dedupe if you already had Oh My Zsh hooks."
  log ""
}

report_what_to_add_manually() {
  local mode="${1:-}"
  local z="$HOME/.zshrc"
  [[ -n "${ZDOTDIR:-}" ]] && z="${ZDOTDIR}/.zshrc"
  local any=0
  local fzf_kb="/usr/share/doc/fzf/examples/key-bindings.zsh"
  local fzf_cmp="/usr/share/doc/fzf/examples/completion.zsh"

  log ""
  log "==> Still add manually (this script never edits these)"
  if [[ "$mode" == "postinstall" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "    (Your home directory as-is — nothing was installed. Re-run without --dry-run to apply apt/curl/npm; this list may shrink.)"
    else
      log "    (Detected from your home directory after install.)"
    fi
  else
    log "    (From --dotfiles-status: current disk only.)"
  fi
  log ""

  if [[ "$mode" == "postinstall" ]] && [[ "$SKIP_FZF_SETUP" -eq 1 ]]; then
    any=1
    log "  • fzf: you used --skip-fzf-setup. To create ~/.fzf.zsh for Debian/Ubuntu fzf, add:"
    log "      See install-linux.sh (write_snippet_fzf_zsh) or re-run without --skip-fzf-setup."
  elif [[ ! -f "$HOME/.fzf.zsh" ]] && ! { [[ "$DRY_RUN" -eq 1 ]] && [[ "$mode" == "postinstall" ]]; }; then
    any=1
    log "  • fzf: ~/.fzf.zsh not found — install-linux.sh creates it from ${fzf_kb} when fzf is installed via apt."
    log "      [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh"
  elif [[ -f "$z" ]] && ! grep -Eq '[/.]fzf\.zsh' "$z"; then
    if [[ -f "$HOME/.fzf.zsh" ]] || ! { [[ "$DRY_RUN" -eq 1 ]] && [[ "$mode" == "postinstall" ]]; }; then
      any=1
      log "  • ~/.zshrc: add fzf keybindings/completion → [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh"
    fi
  fi

  if [[ "$DRY_RUN" -eq 1 ]] && [[ "$mode" == "postinstall" ]] && [[ ! -f "$HOME/.fzf.zsh" ]] && [[ "$SKIP_FZF_SETUP" -eq 0 ]]; then
    any=1
    log "  • fzf: ~/.fzf.zsh does not exist yet (expected with --dry-run). After a real install, add to ~/.zshrc if missing:"
    log "      [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh"
  fi

  if [[ ! -f "$z" ]]; then
    any=1
    log "  • ~/.zshrc: missing (${z}) — create it and add PATH + eval lines from modern-terminal-stack.md §3"
  else
    if ! grep -Eq 'starship init' "$z"; then
      any=1
      log "  • ~/.zshrc: add Starship → eval \"\$(starship init zsh)\""
    fi
    if ! grep -Eq 'zoxide init' "$z"; then
      any=1
      log "  • ~/.zshrc: add zoxide → eval \"\$(zoxide init zsh)\""
    fi
    if ! grep -Eq 'atuin init' "$z"; then
      any=1
      log "  • ~/.zshrc: add Atuin → eval \"\$(atuin init zsh)\" (optional: bindkey '^R' atuin-search)"
    fi
  fi

  if [[ ! -f "$HOME/.config/starship.toml" ]]; then
    any=1
    log "  • Starship: ~/.config/starship.toml missing — create/merge (example in modern-terminal-stack.md §4)"
  fi

  if [[ -f "$z" ]] && ! grep -Eq '\.local/bin|\.atuin/bin' "$z"; then
    if [[ -d "$HOME/.local/bin" ]] || [[ -d "$HOME/.atuin/bin" ]]; then
      any=1
      log "  • PATH: add ~/.local/bin and/or ~/.atuin/bin early in ~/.zshrc if starship/zoxide/atuin binaries are not found."
    fi
  fi

  if [[ "$mode" == "postinstall" ]] && [[ "$SKIP_CLAUDE" -eq 1 ]]; then
    any=1
    log "  • Claude Code: skipped with --skip-claude — run later: npm install -g @anthropic-ai/claude-code"
  elif ! command -v npm >/dev/null 2>&1; then
    if ! { [[ "$SKIP_CLAUDE" -eq 1 ]] && [[ "$mode" == "postinstall" ]]; }; then
      any=1
      log "  • Claude Code: npm not on PATH — install Node (e.g. https://nodejs.org/, nvm, or distro packages), then: npm install -g @anthropic-ai/claude-code"
    fi
  elif [[ "$DRY_RUN" -eq 0 ]] && [[ "$mode" == "postinstall" ]] && ! command -v claude >/dev/null 2>&1; then
    any=1
    log "  • Claude Code: \`claude\` not on PATH after install — add npm global bin, e.g.:"
    log "      export PATH=\"\$(npm prefix -g)/bin:\$PATH\""
  elif [[ "$mode" != "postinstall" ]] && ! command -v claude >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
    any=1
    log "  • Claude Code: \`claude\` not on PATH — run: npm install -g @anthropic-ai/claude-code; then add npm global bin to PATH in ~/.zshrc"
  fi

  if ! command -v cursor >/dev/null 2>&1; then
    any=1
    log "  • Cursor CLI: \`cursor\` not on PATH — install from Cursor and use “Install cursor to PATH” (wording may vary)."
  fi

  if [[ -f "$z" ]]; then
    if ! grep -Eq 'rbenv init|mise activate|asdf' "$z"; then
      if ! command -v rbenv >/dev/null 2>&1 && ! command -v mise >/dev/null 2>&1 && ! command -v asdf >/dev/null 2>&1; then
        any=1
        log "  • Ruby: no rbenv/mise/asdf in ~/.zshrc and tools not on PATH — add your version manager before Rails aliases"
      fi
    fi
  elif ! command -v rbenv >/dev/null 2>&1 && ! command -v mise >/dev/null 2>&1 && ! command -v asdf >/dev/null 2>&1; then
    any=1
    log "  • Ruby: configure rbenv, mise, or asdf (see modern-terminal-stack.md)"
  fi

  if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    any=1
    log "  • Debian/Ubuntu: \`bat\` is often installed as \`batcat\`. This script symlinks ~/.local/bin/bat → batcat when possible."
  fi
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    any=1
    log "  • Debian/Ubuntu: \`fd\` is installed as \`fdfind\`. This script symlinks ~/.local/bin/fd → fdfind when possible."
  fi

  if [[ "$any" -eq 0 ]]; then
    log "  • Nothing obvious missing: shell hooks, starship.toml, and claude/cursor on PATH look present."
    log "    Still verify: ~/.cursor/cli-config.json (permissions), \`atuin import auto\` if migrating history, Atuin sync, and doc §3b merge notes."
  fi
  log ""
}

if [[ "$DOTFILES_STATUS" -eq 1 ]]; then
  report_dotfiles_status
  report_what_to_add_manually dotfiles
  exit 0
fi

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] %q' "$1"
    shift
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

if [[ "$(uname -s)" != "Linux" ]]; then
  err "This script targets Linux. For macOS use ./install.sh."
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  err "apt-get not found. This script supports Debian/Ubuntu-based distros (including WSL). For Fedora/RHEL use dnf; for Arch use pacman — not automated here yet."
  exit 1
fi

SUDO=""
if [[ "$(id -u)" -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    err "Need root for apt. Install sudo or run this script as root."
    exit 1
  fi
fi

# Extra apt options: more HTTP retries + longer timeouts (helps flaky mirrors / WSL networking).
APT_GET_OPTS=(
  -o "Acquire::Retries=6"
  -o "Acquire::http::Timeout=120"
  -o "Acquire::https::Timeout=120"
)

_apt_get() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    run env DEBIAN_FRONTEND=noninteractive "$SUDO" apt-get "${APT_GET_OPTS[@]}" "$@"
    return 0
  fi
  env DEBIAN_FRONTEND=noninteractive "$SUDO" apt-get "${APT_GET_OPTS[@]}" "$@"
}

apt_update() {
  _apt_get update -qq
}

apt_install() {
  _apt_get install -y "$@"
}

apt_troubleshoot_hint() {
  err "apt failed after retries. Common causes:"
  err "  • Transient mirror/network errors — wait and re-run this script, or try: sudo apt-get clean && sudo apt-get update"
  err "  • VPN / proxy / corporate firewall blocking archive.ubuntu.com or security.ubuntu.com"
  err "  • Duplicate apt entries (e.g. W: Target Packages configured multiple times) — remove or comment the duplicate file in /etc/apt/sources.list.d/"
  err "  • WSL: ensure Windows firewall allows outbound HTTP, or switch mirror in /etc/apt/sources.list"
}

apt_install_if_available() {
  local pkg
  for pkg in "$@"; do
    if apt-cache show "$pkg" >/dev/null 2>&1; then
      if ! apt_install "$pkg"; then
        log "WARN: apt install failed for \`${pkg}\` — skipping this package (network or mirror issue)."
      fi
    else
      log "    (apt skip: no package \`${pkg}\` in current apt sources)"
    fi
  done
}

ensure_local_bin() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] mkdir -p ${HOME}/.local/bin"
  else
    mkdir -p "${HOME}/.local/bin"
  fi
}

write_snippet_fzf_zsh() {
  local kb="/usr/share/doc/fzf/examples/key-bindings.zsh"
  local cmp="/usr/share/doc/fzf/examples/completion.zsh"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] write ~/.fzf.zsh sourcing Debian/Ubuntu fzf example zsh files"
    return 0
  fi
  if [[ ! -f "$kb" ]] || [[ ! -f "$cmp" ]]; then
    err "fzf example files missing (expected $kb and $cmp). Is fzf installed?"
    exit 1
  fi
  cat >"${HOME}/.fzf.zsh" <<EOF
# Generated by install-linux.sh — Debian/Ubuntu fzf package
[[ -f $kb ]] && source $kb
[[ -f $cmp ]] && source $cmp
EOF
  log "Wrote ${HOME}/.fzf.zsh"
}

symlink_bat_fd() {
  ensure_local_bin
  if [[ "$DRY_RUN" -eq 1 ]]; then
    command -v batcat >/dev/null 2>&1 && log "[dry-run] ln -sf \$(command -v batcat) ~/.local/bin/bat"
    command -v fdfind >/dev/null 2>&1 && log "[dry-run] ln -sf \$(command -v fdfind) ~/.local/bin/fd"
    return 0
  fi
  if command -v batcat >/dev/null 2>&1; then
    ln -sf "$(command -v batcat)" "${HOME}/.local/bin/bat"
    log "Linked ~/.local/bin/bat → batcat"
  fi
  if command -v fdfind >/dev/null 2>&1; then
    ln -sf "$(command -v fdfind)" "${HOME}/.local/bin/fd"
    log "Linked ~/.local/bin/fd → fdfind"
  fi
}

install_starship() {
  command -v starship >/dev/null 2>&1 && return 0
  ensure_local_bin
  log "==> Installing Starship (official installer → ~/.local/bin)…"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log '[dry-run] curl -sS https://starship.rs/install.sh | sh -s -- -y -b ~/.local/bin'
    return 0
  fi
  curl -sS https://starship.rs/install.sh | sh -s -- -y -b "${HOME}/.local/bin"
}

install_zoxide() {
  command -v zoxide >/dev/null 2>&1 && return 0
  ensure_local_bin
  log "==> Installing zoxide (official installer → ~/.local/bin)…"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log '[dry-run] curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash'
    return 0
  fi
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
}

install_atuin() {
  command -v atuin >/dev/null 2>&1 && return 0
  log "==> Installing Atuin (official installer → ~/.atuin/bin)…"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh -s -- --non-interactive"
    return 0
  fi
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh -s -- --non-interactive
}

CORE_APT_PACKAGES=(
  ca-certificates
  curl
  git
  tmux
  wget
  fzf
  ripgrep
  fd-find
  bat
)

OPTIONAL_APT_PACKAGES=(
  neovim
  lazygit
  eza
  starship
  zoxide
  atuin
)

install_core_apt_with_retry() {
  local max="${INSTALL_LINUX_APT_ATTEMPTS:-3}"
  local delay="${INSTALL_LINUX_APT_RETRY_SLEEP:-8}"
  local n=1
  [[ "$max" -lt 1 ]] && max=1

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "==> apt-get update…"
    apt_update
    log "==> Installing core apt packages (${#CORE_APT_PACKAGES[@]})…"
    apt_install "${CORE_APT_PACKAGES[@]}"
    return 0
  fi

  while [[ "$n" -le "$max" ]]; do
    log "==> apt-get update…"
    if ! apt_update; then
      log "WARN: apt-get update exited with an error; still attempting install…"
    fi
    log "==> Installing core apt packages (${#CORE_APT_PACKAGES[@]})…"
    if apt_install "${CORE_APT_PACKAGES[@]}"; then
      return 0
    fi
    if [[ "$n" -lt "$max" ]]; then
      log "WARN: core apt install failed (attempt ${n} of ${max}); waiting ${delay}s before retry…"
      sleep "$delay"
    fi
    n=$((n + 1))
  done
  apt_troubleshoot_hint
  exit 1
}

install_core_apt_with_retry

if [[ "$SKIP_OPTIONAL" -eq 0 ]]; then
  log "==> Installing optional apt packages (if published for this release)…"
  apt_install_if_available "${OPTIONAL_APT_PACKAGES[@]}"
else
  log "==> Skipped optional apt packages (--skip-optional)."
fi

log "==> Ensuring CLI tools on PATH (apt + fallbacks)…"
apt_install_if_available starship zoxide atuin
install_starship
install_zoxide
install_atuin

if [[ "$SKIP_OPTIONAL" -eq 0 ]] && ! command -v eza >/dev/null 2>&1; then
  log "WARN: \`eza\` not on PATH after apt — on older Ubuntu, install from https://github.com/eza-community/eza/releases or upgrade the distro."
fi
if [[ "$SKIP_OPTIONAL" -eq 0 ]] && ! command -v lazygit >/dev/null 2>&1; then
  log "WARN: \`lazygit\` not on PATH after apt — install from https://github.com/jesseduffield/lazygit/releases or upgrade the distro."
fi

symlink_bat_fd

if [[ "$SKIP_FZF_SETUP" -eq 0 ]]; then
  log "==> Configuring fzf for zsh (Debian/Ubuntu paths, writes ~/.fzf.zsh)…"
  write_snippet_fzf_zsh
else
  log "==> Skipped fzf zsh snippet (--skip-fzf-setup)."
fi

if [[ "$SKIP_CLAUDE" -eq 0 ]]; then
  if command -v npm >/dev/null 2>&1; then
    log "==> Installing Claude Code (npm global; re-run updates if a newer package exists)…"
    run npm install -g @anthropic-ai/claude-code
  else
    log "WARN: npm not on PATH — skipped Claude Code. Install Node, then:"
    log "      npm install -g @anthropic-ai/claude-code"
  fi
else
  log "==> Skipped Claude Code (--skip-claude)."
fi

log ""
log "==> Done (apt + optional curl installers + optional npm global)."
report_what_to_add_manually postinstall
log "Re-check any time: ./install-linux.sh --dotfiles-status"
log ""
log "Verify:  starship --version  zoxide --version  fzf --version  atuin --version  rg --version  fd --version  bat --version"
if [[ "$SKIP_CLAUDE" -eq 0 ]] && command -v claude >/dev/null 2>&1; then
  log "          claude --help"
fi
