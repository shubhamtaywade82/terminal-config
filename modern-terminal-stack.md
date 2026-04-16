# Modern terminal stack (macOS) — programmable shell + AI surface

This document is tuned for **Ruby on Rails backends**, **Strategic Care–style monorepos** (Minitest, RuboCop, optional Rush/pnpm micro-frontends), and a terminal AI stack built from **Cursor (IDE + Cursor CLI)** plus **Claude Code**. Use it as a reference while you grow this `terminal-config` repo.

**Goal:** treat `zsh` as a small **orchestration layer** (fast startup, predictable tools), not a theme park. Keep AI in a **suggest / explain** role unless you explicitly opt into execution.

---

## Architecture (what to aim for)

| Layer | Role | Suggested tools |
|--------|------|------------------|
| **Execution** | Shell, core CLI | `zsh`, Homebrew `coreutils` if needed |
| **Speed + context** | Prompt, jumps, history | `starship`, `zoxide`, `atuin` |
| **Selection / search** | Fuzzy pickers, fast search | `fzf`, `ripgrep` (`rg`), `fd` |
| **Readable CLI** | Lists, file preview | `eza`, `bat` |
| **Sessions** | Long-running work, attach/detach | `tmux` or `zellij` |
| **AI** | IDE + terminal agents | **Cursor** (editor + **Cursor CLI**), **Claude Code** (`claude`); optional extras (e.g. local `ollama`) only if policy allows |

**Prefer replacing** slow, opaque stacks (heavy Oh My Zsh + huge prompt themes) with **fewer, composable** pieces—especially if you care about sub-200ms interactive startup.

---

## 1. Install baseline (Homebrew)

**Core (recommended):**

```bash
brew install starship zoxide fzf eza bat atuin fd ripgrep tmux git
```

`git` is for **your** remote (GitLab, Bitbucket, Azure DevOps, self-hosted, etc.)—this doc does **not** assume GitHub or the `gh` CLI.

**Often useful in Rails + JS monorepos:**

```bash
brew install lazygit neovim
```

**Ruby:** use whatever you already standardize on (`rbenv`, `asdf`, `mise`, or chruby). This repo does not pick one for you—hook it in *after* Homebrew on your `PATH` in `.zshrc`.

**One-shot install (this repo):** from the repo root, run `chmod +x install.sh && ./install.sh` (inspect with `./install.sh --dry-run` first). It installs the Homebrew formulae, runs the fzf installer, and installs Claude Code globally when `npm` is available. **Re-running is safe:** `brew install` leaves already-installed formulae alone (no failure); use `brew upgrade` when you want newer versions. It does **not** install the Cursor app or edit `~/.zshrc` / Starship / Cursor JSON—merge by hand or via a sourced snippet; see **§ Existing config files** and `./install.sh --dotfiles-status`.

After a normal install (or with `./install.sh --dotfiles-status` alone), the script prints **Still add manually**: a checklist of anything it **did not** configure (e.g. missing `~/.fzf.zsh`, hooks not found in `~/.zshrc`, no `starship.toml`, `cursor` / `claude` not on `PATH`, Ruby manager). Follow those lines and the doc; detection is best-effort (e.g. it looks for `starship init` / `zoxide init` / `atuin init` substrings in `~/.zshrc`).

---

## 2. AI layer (Cursor CLI + Claude Code)

You standardize on two terminal-adjacent agents:

### Cursor (editor + Cursor CLI)

- **In the app:** agents, rules, skills, integrated terminal—best for repo-wide context and review loops.
- **Cursor CLI:** install the shell command from the Cursor app (**Shell Command: Install `cursor` command in PATH**), then use it from any directory (e.g. open the repo: `cursor /path/to/project`).
- **CLI config:** global settings live in `~/.cursor/cli-config.json` (permissions, `approvalMode`, `sandbox`, `editor.defaultBehavior`, etc.). Projects can layer overrides via `.cursor/cli.json` from the repo root down to the cwd (deeper files win; they affect the current session only).

Treat **`approvalMode`** and **tool allowlists** as part of your safety model—especially on shared machines.

### Claude Code

- **Prerequisite:** Node.js + npm (or the runtime your org standardizes on) on your `PATH`.
- **Install (typical):** `npm install -g @anthropic-ai/claude-code` (use the Node/npm versions your team supports).
- **Invoke:** the CLI entrypoint is **`claude`** (run `claude --help` after install for current flags).
- **PATH:** ensure your npm global bin directory is on `PATH` in `.zshrc` so `claude` resolves in non-login shells (same concern as other global CLIs).

### How the two fit together

- **Cursor CLI** — tight integration with Cursor’s agent, permissions, and (optionally) opening the IDE from the shell.
- **Claude Code** — standalone Anthropic terminal agent for sessions where you want that workflow; still keep **human-in-the-loop** for destructive commands.

**Optional extras** (only if policy allows): local models (e.g. `ollama`) for offline experiments—not a substitute for your agreed-on agents.

**Design rule:** agents suggest or generate; **you** approve and run destructive commands (`rm`, `DROP`, mass `sed`, `git reset --hard`, etc.).

---

## 3. Example `.zshrc` (fast, composable)

Copy ideas, don’t paste blindly. Adjust Ruby manager, paths, and aliases to match your machine.

```zsh
# ---------- PATH (Apple Silicon Homebrew + npm globals for claude, etc.) ----------
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
# Uncomment if `claude` / other global npm CLIs are not found:
# export PATH="$HOME/.local/bin:$PATH"
# export PATH="$(npm config get prefix 2>/dev/null)/bin:$PATH"

# ---------- Ruby version manager (pick ONE; uncomment/adapt) ----------
# eval "$(rbenv init - zsh)"
# eval "$(mise activate zsh)"

# ---------- PROMPT ----------
eval "$(starship init zsh)"

# ---------- SMART CD ----------
eval "$(zoxide init zsh)"

# ---------- HISTORY (Atuin) ----------
eval "$(atuin init zsh)"

# ---------- FZF ----------
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# ---------- COMPLETION ----------
autoload -Uz compinit
compinit -C

# ---------- KEYBINDS ----------
bindkey '^R' atuin-search

# ---------- MODERN CLI (do not shadow the fd binary) ----------
alias ls='eza --icons --group-directories-first'
alias ll='eza -lh --icons'
alias cat='bat'
alias grep='rg'
# zoxide provides `z`; keep real cd available:
alias cdd='builtin cd'

# Fuzzy files in cwd (name this anything except `fd`)
alias ffiles='fd --type f | fzf'

# ---------- GIT (safe habits) ----------
alias g='git'
alias gs='git status'
alias gd='git diff'
# Avoid one-letter aliases for commit/push if you want fewer accidents:
alias gcm='git commit'
alias gph='git push'

# ---------- RAILS / RUBY (monorepo-friendly) ----------
alias rs='bin/rails server'
alias rc='bin/rails console'
alias rr='bin/rails routes'
alias be='bundle exec'
# Minitest (adjust paths to your app)
alias mt='bin/rails test'
alias qtest='bin/rails test test/quality_test.rb'

# ---------- NODE (Rush / pnpm micro-frontends) ----------
alias pni='pnpm install'
alias pnr='pnpm run'

# ---------- SESSIONS ----------
alias t='tmux'

# ---------- CURSOR + CLAUDE CODE (shortcuts — requires CLI on PATH) ----------
# Open repo in Cursor (after installing the `cursor` shell command from the app)
alias c.='cursor .'

# Claude Code — prefer running with explicit intent, e.g. `claude` in repo root
# alias cc='claude'
```

**Why change `alias cd="z"`?** Some workflows still need real `cd` (scripts, subshells, odd paths). Prefer `z` / `zi` from zoxide and keep `builtin cd` reachable.

**Why not `alias fd=...`?** You lose the real `fd` executable; use a differently named alias (see `ffiles` above).

---

## 3b. Existing config files (merge, don’t clobber)

`./install.sh` **never edits** `~/.zshrc`, Starship, Cursor, or Atuin config—it only installs binaries and the fzf integration file `~/.fzf.zsh` (from Homebrew’s fzf installer). If you already have settings, treat this stack as **additive**.

### `~/.zshrc` (or `$ZDOTDIR/.zshrc`)

- **Do not replace** a long `.zshrc` wholesale. Copy **sections** from the example above (PATH, `eval "$(starship init zsh)"`, zoxide, atuin, fzf source) into the right **order** (PATH and version managers before prompts; completions after `fpath` changes).
- **Avoid duplicates:** a second `eval "$(atuin init zsh)"` or double `compinit` slows startup and can break keybinds. Search the file for `starship`, `zoxide`, `atuin`, `fzf` before pasting.
- **Low-risk pattern:** keep your main `.zshrc` as-is and add **one line** at the end, e.g. `[[ -f ~/.config/terminal-config/zsh.local ]] && source ~/.config/terminal-config/zsh.local`, then put *only* the new stack snippets in that sourced file (easy to diff and disable).

### `~/.config/starship.toml`

- Starship reads **one** config file by default. **Merge** new `[module]` blocks into your existing TOML instead of deleting your file.
- **Experiment without touching the default:** run once with `STARSHIP_CONFIG=/path/to/alternate.toml zsh` to compare prompts before you merge.

### `~/.fzf.zsh` (fzf)

- The Homebrew fzf installer (run by `install.sh`) (re)generates this file. Your `.zshrc` should contain **at most one** `source ~/.fzf.zsh` (or `source` via `$HOMEBREW_PREFIX`). Remove old fzf install lines if you migrated from a manual install.

### Atuin (`~/.config/atuin/config.toml` + shell hook)

- Config and sync live under `~/.config/atuin/`. **Do not** add a second full `eval "$(atuin init zsh)"` if one is already there from another setup.
- If you use **Oh My Zsh** `atuin` plugin *and* a manual `eval`, pick **one** integration path.

### Cursor (`~/.cursor/cli-config.json`)

- JSON: merge new keys carefully (trailing commas are invalid). Prefer editing in Cursor or a JSON-aware editor. Repo-level overrides belong in `.cursor/cli.json` inside projects—those merge over the global file for CLI sessions.

### Inspect what you already have

From this repo:

```bash
./install.sh --dotfiles-status
```

That prints whether common paths exist and line counts (read-only). It does **not** install packages.

---

## 4. Example Starship (`~/.config/starship.toml`)

Keep the prompt **cheap**: git + Ruby + optional Node/Docker only if you touch them daily.

```toml
add_newline = false

[character]
success_symbol = "[➜](green)"
error_symbol = "[✗](red)"

[git_branch]
symbol = " "
style = "bold yellow"

[ruby]
symbol = " "

[nodejs]
symbol = " "

[docker_context]
symbol = " "
disabled = true

[kubernetes]
disabled = true
```

Uncomment or enable sections when they carry signal, not noise.

---

## 5. Project-specific habits (Rails + quality gates)

When working in a large Rails app:

- **Prefer `bin/rails` and `bin/rubocop`** (or `bundle exec …`) so you match the repo’s Bundler lock.
- **Run targeted tests** while iterating: `bin/rails test path/to/file_test.rb` instead of the whole suite.
- **RuboCop on changed files** before push if that is your team norm; keep it fast (narrow paths, parallel where configured).
- **`test/quality_test.rb`** (or your repo’s equivalent) is a gate—know how to run it alone (`qtest` alias above is a template).

For **HIP / HIL / micro-frontend** work, your editor and package manager versions matter as much as the shell; the shell’s job is to get you to the right directory and run the right **pinned** `pnpm`/`rush` commands quickly.

---

## 6. Optional “agent-shaped” shell helpers (high ROI, low magic)

Small functions **wrap** tools you already trust—never auto-apply patches:

```zsh
# Preview diff with pager; add model step only if you want commentary
diffview() {
  git diff "${@:---}" | bat --language=diff
}

# Pipe last command output to fzf (manual, safe)
lastout() {
  fc -ln -1 | bat
}
```

For **Cursor** / **Claude Code**, do not paste secrets, production credentials, or full `.env` contents into prompts. For any **local** model you run yourself, keep prompts **offline** and **non-secret** (e.g. redacted SQL shapes).

---

## 7. Performance and sanity checks

```bash
# Interactive zsh startup (rough)
time zsh -i -c exit
```

If startup drifts above **~200ms**, remove unused `eval`s, defer slow completions, and avoid sourcing huge plugin frameworks on every shell.

**Atuin:** confirm `Ctrl+R` opens Atuin search, not only classic reverse search.

**Zoxide:** use `z foo` to jump; verify database path if you sync machines.

---

## 8. Verification checklist

- [ ] `starship` shows without noticeable delay.
- [ ] `z` / `zi` jumps to frequent directories.
- [ ] `Ctrl+R` → Atuin UI (if Atuin is active).
- [ ] `fzf` works on files / git / history integrations you rely on.
- [ ] `rg` and `fd` remain real binaries (no shadowing aliases).
- [ ] Ruby toolchain loads in **non-login** shells the way your editor expects.
- [ ] `time zsh -i -c exit` is acceptable on your machine.
- [ ] `cursor` is on `PATH` (Cursor app shell-command install) and opens a project as expected.
- [ ] `claude` is on `PATH` and runs (`claude --help` succeeds).

---

## 9. What belongs in *this* repo (`terminal-config`)

Suggested layout as you evolve:

- [FEATURES_AND_USAGE.md](./FEATURES_AND_USAGE.md) — feature list + macOS/Linux usage for each tool.
- `README.md` — how you sync these snippets to `~/.zshrc` / `~/.config/starship.toml`.
- `zsh/` — modular fragments (`zsh/10-path.zsh`, `zsh/20-ruby.zsh`, …) sourced from a thin `~/.zshrc`.
- `starship.toml` — versioned copy of your prompt config.

Keep **secrets and machine-specific paths** out of git; use a private snippet or `~/.zshrc.local` sourced at the end.

---

## References

1. [The Ultimate Terminal Stack in 2026 (cross-platform overview)](https://medium.com/vmacwrites/the-ultimate-terminal-stack-in-2026-a-cross-platform-guide-for-macos-linux-and-windows-c0d1f93cd9cc)
2. [Building AI coding agents for the terminal (research perspective)](https://arxiv.org/abs/2603.05344)

---

## Not in scope (unless you add it)

- Remote `curl | bash` pipelines from the internet (prefer reviewing and running `./install.sh` from this repo).
- **Trading / domain-specific CLIs**—replace that idea with *your* real systems (e.g. internal `bin/` tools, `script/` runners, or Cursor commands) when you have something concrete to wrap.

When you want a **second doc**, good next steps are: (a) a minimal `README.md` for how you apply files from this repo, or (b) a `zsh/` split layout with concrete filenames—say which you prefer.
