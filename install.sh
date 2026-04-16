#!/usr/bin/env bash
# One-shot installer for the stack described in modern-terminal-stack.md
# macOS + Homebrew. Does not configure Git remotes or sign in to hosted services.
#
# Re-runs: safe. `brew install` skips formulae that are already installed (exit 0);
# outdated bottles are not auto-upgraded—use `brew upgrade <name>` or `brew upgrade`
# when you want newer versions. fzf installer and `npm install -g` are idempotent.
#
# Usage:
#   ./install.sh              # install Homebrew packages + fzf integration + Claude Code (if npm exists)
#   ./install.sh --dry-run    # print what would run
#   ./install.sh --help
#
# Flags:
#   --dry-run            print commands only
#   --skip-optional      skip lazygit + neovim
#   --skip-claude        skip npm global @anthropic-ai/claude-code
#   --skip-fzf-setup     skip fzf key-bindings/completion installer
#   --dotfiles-status    print whether common config files exist (does not install; does not edit files)

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
Usage: ./install.sh [options]

  One-shot Homebrew install for modern-terminal-stack.md (macOS).

Options:
  --dry-run            print commands only
  --skip-optional      skip lazygit and neovim
  --skip-claude        skip npm install -g @anthropic-ai/claude-code
  --skip-fzf-setup     skip fzf key-bindings/completion installer
  --dotfiles-status    list common config paths + merge hints (no brew; no file changes)
  -h, --help           show this help
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
  log "==> Dotfile / config status (nothing here is modified by install.sh)"
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
  log "  • fzf: ~/.fzf.zsh is managed by the fzf installer; keep one [[ -f ~/.fzf.zsh ]] && source … in .zshrc."
  log "  • Atuin: avoid running eval \"\$(atuin init zsh)\" twice; dedupe if you already had Oh My Zsh hooks."
  log ""
}

report_what_to_add_manually() {
  # Optional: pass "postinstall" as $1 after a real install run (uses SKIP_* flags for extra hints).
  local mode="${1:-}"
  local z="$HOME/.zshrc"
  [[ -n "${ZDOTDIR:-}" ]] && z="${ZDOTDIR}/.zshrc"
  local any=0
  local brew_prefix
  brew_prefix="$(brew --prefix 2>/dev/null || true)"

  log ""
  log "==> Still add manually (this script never edits these)"
  if [[ "$mode" == "postinstall" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "    (Your home directory as-is — nothing was installed. Re-run without --dry-run to apply brew/fzf/npm; this list may shrink.)"
    else
      log "    (Detected from your home directory after install.)"
    fi
  else
    log "    (From --dotfiles-status: current disk only.)"
  fi
  log ""

  if [[ "$mode" == "postinstall" ]] && [[ "$SKIP_FZF_SETUP" -eq 1 ]]; then
    any=1
    log "  • fzf: you used --skip-fzf-setup. To create ~/.fzf.zsh, run:"
    log "      yes | ${brew_prefix:-/opt/homebrew}/opt/fzf/install --key-bindings --completion --no-update-rc"
  elif [[ ! -f "$HOME/.fzf.zsh" ]] && ! { [[ "$DRY_RUN" -eq 1 ]] && [[ "$mode" == "postinstall" ]]; }; then
    any=1
    log "  • fzf: ~/.fzf.zsh not found — install integration (creates the file), then source it from ~/.zshrc:"
    log "      yes | ${brew_prefix:-/opt/homebrew}/opt/fzf/install --key-bindings --completion --no-update-rc"
    log "      [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh"
  elif [[ -f "$z" ]] && ! grep -Eq '[/.]fzf\.zsh' "$z"; then
    # During --dry-run, ~/.fzf.zsh is not created yet — do not suggest sourcing it until a real install runs.
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

  if [[ "$mode" == "postinstall" ]] && [[ "$SKIP_CLAUDE" -eq 1 ]]; then
    any=1
    log "  • Claude Code: skipped with --skip-claude — run later: npm install -g @anthropic-ai/claude-code"
  elif ! command -v npm >/dev/null 2>&1; then
    if ! { [[ "$SKIP_CLAUDE" -eq 1 ]] && [[ "$mode" == "postinstall" ]]; }; then
      any=1
      log "  • Claude Code: npm not on PATH — install Node (e.g. brew install node), then: npm install -g @anthropic-ai/claude-code"
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
    log "  • Cursor CLI: \`cursor\` not on PATH — Cursor app → Command Palette → “Install cursor to PATH” (wording may vary by version)"
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

if [[ "$(uname -s)" != "Darwin" ]]; then
  err "This script targets macOS (Darwin). Aborting."
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  err "Homebrew not found. Install from https://brew.sh then re-run."
  exit 1
fi

BREW_PREFIX="$(brew --prefix)"
export HOMEBREW_NO_ANALYTICS=1

PACKAGES=(
  starship
  zoxide
  fzf
  eza
  bat
  atuin
  fd
  ripgrep
  tmux
  git
)

OPTIONAL_PACKAGES=(
  lazygit
  neovim
)

if [[ "$SKIP_OPTIONAL" -eq 0 ]]; then
  PACKAGES+=("${OPTIONAL_PACKAGES[@]}")
fi

log "==> Installing Homebrew formulae (${#PACKAGES[@]} packages)…"
log "    (Already installed → Homebrew skips them; no error. Outdated → run brew upgrade separately.)"
run brew update || true
run brew install "${PACKAGES[@]}"

if [[ "$SKIP_FZF_SETUP" -eq 0 ]]; then
  FZF_INSTALL="${BREW_PREFIX}/opt/fzf/install"
  if [[ -x "$FZF_INSTALL" ]] || [[ -f "$FZF_INSTALL" ]]; then
    log "==> Configuring fzf (key bindings + completion, no auto .zshrc lines)…"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "[dry-run] yes | $FZF_INSTALL --key-bindings --completion --no-update-rc"
    else
      yes | "$FZF_INSTALL" --key-bindings --completion --no-update-rc
    fi
  else
    err "fzf install script missing at $FZF_INSTALL — check brew install fzf."
    exit 1
  fi
fi

if [[ "$SKIP_CLAUDE" -eq 0 ]]; then
  if command -v npm >/dev/null 2>&1; then
    log "==> Installing Claude Code (npm global; re-run updates if a newer package exists)…"
    run npm install -g @anthropic-ai/claude-code
  else
    log "WARN: npm not on PATH — skipped Claude Code. Install Node (e.g. brew install node) and run:"
    log "      npm install -g @anthropic-ai/claude-code"
  fi
else
  log "==> Skipped Claude Code (--skip-claude)."
fi

log ""
log "==> Done (brew + fzf + optional npm global)."
report_what_to_add_manually postinstall
log "Re-check any time: ./install.sh --dotfiles-status"
log ""
log "Verify:  starship --version  zoxide --version  fzf --version  atuin --version  rg --version  fd --version"
if [[ "$SKIP_CLAUDE" -eq 0 ]] && command -v claude >/dev/null 2>&1; then
  log "          claude --help"
fi
