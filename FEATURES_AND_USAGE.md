# Terminal stack — features and usage (macOS & Linux)

This document lists what the **modern terminal stack** in this repo gives you, and how to **use** each piece on **macOS** and **Linux**.

| Scope | Notes |
|--------|--------|
| **`install.sh` in this repo** | **macOS only** (Homebrew). See [modern-terminal-stack.md](./modern-terminal-stack.md) for shell snippets and merge guidance. |
| **Tools below** | Same CLIs on both platforms once installed; only **install paths** and **shell init** differ. |
| **Shell** | Examples assume **zsh** (as in `modern-terminal-stack.md`). Most tools also support **bash** with their documented `init` lines. |

---

## Feature overview

| Feature | What you get |
|---------|----------------|
| **Starship** | Fast, informative prompt (git branch, Ruby/Node versions, exit status, etc.). |
| **zoxide** | “Smart `cd`” — jump to directories you use often by fuzzy name (`z`, `zi`). |
| **Atuin** | Syncable, searchable shell history; richer than default reverse search. |
| **fzf** | Fuzzy finder for files, git, history, and anything you pipe into it. |
| **ripgrep (`rg`)** | Fast recursive search in code; respects `.gitignore` by default. |
| **`fd`** | Fast, user-friendly `find` alternative for paths and file types. |
| **`eza`** | Modern `ls` with colors, git status, tree layout. |
| **`bat`** | Syntax-highlighted file view (pager-friendly `cat`). |
| **`tmux`** | Terminal multiplexer — sessions survive disconnects; split panes/windows. |
| **`git`** | Version control (works with any host: GitLab, Bitbucket, self-hosted, etc.). |
| **Lazygit** *(optional)* | TUI for staging, commits, branches, and logs. |
| **Neovim** *(optional)* | Modal editor in the terminal. |
| **Claude Code** *(via script when `npm` exists)* | Anthropic terminal coding agent (`claude`). |
| **Cursor** *(manual)* | Editor + **Cursor CLI** (`cursor`); not installed by `install.sh`. |

Ruby version managers (**rbenv**, **mise**, **asdf**) are **not** installed by this repo; you add them per machine.

---

## Install the stack

### macOS (this repo)

```bash
cd /path/to/terminal-config
./install.sh --dry-run   # optional preview
./install.sh
```

Then merge hooks into `~/.zshrc` and add `~/.config/starship.toml` as described in **modern-terminal-stack.md** (and run `./install.sh --dotfiles-status` to see gaps).

### Linux (equivalent packages)

There is **no** `install.sh` for Linux here; use your distro (or **Linuxbrew**) to install the **same tool names** where available.

**Debian / Ubuntu** (examples — names vary by release; check `apt search`):

```bash
sudo apt update
sudo apt install -y git tmux ripgrep fd-find fzf bat
# eza (preferred) vs old exa — install what your release ships, e.g.:
sudo apt install -y eza 2>/dev/null || sudo apt install -y exa
# `fd` binary may be `fdfind` — symlink or alias `fd` if scripts expect `fd`
# `bat` binary may be `batcat` — e.g. sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
# starship / zoxide / atuin — if missing from apt, use Linuxbrew or upstream install scripts
```

**Fedora / RHEL-family:**

```bash
sudo dnf install -y git tmux ripgrep fd-find fzf bat eza starship zoxide
```

**Arch Linux:**

```bash
sudo pacman -S --needed git tmux ripgrep fd fzf bat eza starship zoxide atuin
```

**Universal option:** [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux) — then use the same `brew install …` list as in **modern-terminal-stack.md §1**.

**Atuin / Starship / eza:** if your distro lacks them, use **upstream install docs**, **Linuxbrew**, or **static binaries** from each project’s releases.

**Claude Code** (any OS with Node):

```bash
npm install -g @anthropic-ai/claude-code
```

**Cursor:** download from [cursor.com](https://cursor.com); install the **`cursor`** shell command from the app (same idea on Linux as on macOS).

---

## How to use each feature

Usage is **identical** on macOS and Linux once the binary is on your `PATH` and shell hooks are loaded.

### Starship (prompt)

**Shell init (zsh):** add once to `~/.zshrc`:

```bash
eval "$(starship init zsh)"
```

**Config:** `~/.config/starship.toml` (same path on macOS and Linux).

**Try it:** open a new terminal; run `starship explain` to see which modules fired.

---

### zoxide (smart directory jump)

**Shell init (zsh):**

```bash
eval "$(zoxide init zsh)"
```

**Use:**

| Command | Purpose |
|---------|---------|
| `z foo` | Jump to a directory whose path was scored matching `foo`. |
| `zi foo` | Interactive pick when several paths match (`fzf` integration if configured). |
| `zoxide query -l` | List ranked paths (exact flags: `zoxide --help`). |

Keep normal `cd` available (e.g. `alias cdd='builtin cd'`) if you use scripts that rely on classic `cd`.

---

### Atuin (history)

**Shell init (zsh):**

```bash
eval "$(atuin init zsh)"
```

**Use:**

| Action | Purpose |
|--------|---------|
| **Ctrl+R** (if bound) | Open Atuin’s history UI (replace default reverse-i-search if you bind it). |
| `atuin import auto` | One-time migration from shell history files. |
| `atuin sync` / account | Optional encrypted sync (see Atuin docs). |

**Linux/macOS:** config usually under `~/.config/atuin/`. Do not run `eval "$(atuin init zsh)"` twice in the same `.zshrc`.

---

### fzf (fuzzy finder)

**Typical zsh setup** (after Homebrew’s fzf install script or your distro’s layout):

```bash
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
```

**Use:**

| Pattern | Example |
|---------|---------|
| Files under cwd | `fd . \| fzf` or `find . -type f \| fzf` |
| Checkout git branch | `git branch \| fzf` (often wrapped in functions) |
| Pick from command output | `some-cmd \| fzf` |

On Debian, fzf keybindings may live under `/usr/share/doc/fzf/examples/` — follow distro docs if `~/.fzf.zsh` is not used.

---

### ripgrep (`rg`)

**Use:**

```bash
rg pattern
rg -t rb TODO
rg -l pattern   # files with matches only
rg -n pattern   # line numbers (default in recent versions)
```

Same flags on macOS and Linux.

---

### `fd`

**Use:**

```bash
fd name                 # paths matching name
fd -e rb                # Ruby extension
fd -t f pattern         # files only
```

On some Debian/Ubuntu installs the binary is **`fdfind`**; create a symlink or alias `fd` if needed.

---

### `eza`

**Use:**

```bash
eza
eza -la --git
eza --tree --level 2
```

**Note:** older distros shipped **`exa`** (unmaintained). Prefer **`eza`** where available.

---

### `bat`

**Use:**

```bash
bat file.rb
bat -n file.rb          # line numbers
bat -p file.rb          # plain (no decorations), good for piping
```

On Debian/Ubuntu the binary is often **`batcat`**; symlink to `bat` if scripts expect `bat`.

---

### `tmux`

**Use:**

| Command | Purpose |
|---------|---------|
| `tmux` | New session. |
| `tmux new -s work` | Named session. |
| `tmux attach -t work` | Reattach. |
| `Ctrl+b` then `d` | Detach (default prefix). |

Sessions persist on **both** macOS and Linux until you kill them or reboot (unless you use a persistent user session / server).

---

### `git`

**Use:** standard workflow (`clone`, `status`, `diff`, `commit`, `push`, etc.) against **any** remote.

This stack does **not** require GitHub or the `gh` CLI.

---

### Lazygit *(optional)*

**Run:** `lazygit` inside a repo.

**Keyboard-driven** staging, commits, branches, and log view — same on macOS and Linux.

---

### Neovim *(optional)*

**Run:** `nvim` or `nvim file.rb`.

Config: `~/.config/nvim/` on both platforms.

---

### Claude Code

**Run:** `claude` (after `npm install -g @anthropic-ai/claude-code`).

**Use:** follow `claude --help` for subcommands; keep secrets out of prompts; align with org policy.

**PATH:** if `claude` is not found, add npm’s global `bin` to `PATH` in `~/.zshrc` (same fix on macOS and Linux).

---

### Cursor (editor + CLI)

**Editor:** install from vendor site.

**CLI:** install **`cursor`** into `PATH` from the app’s command palette (wording varies by version).

**Use:**

```bash
cursor /path/to/project
cursor .
```

**Config:** `~/.cursor/cli-config.json` (and project `.cursor/cli.json`). See **modern-terminal-stack.md §2**.

---

## Quick reference: shell hooks (zsh)

Add these **in order** after `PATH` / version managers (same file on macOS and Linux, paths adjusted):

1. `eval "$(starship init zsh)"`
2. `eval "$(zoxide init zsh)"`
3. `eval "$(atuin init zsh)"`
4. `[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh` *(path may differ on some Linux fzf packages)*

Then aliases (e.g. `ls` → `eza`) as in **modern-terminal-stack.md §3**.

---

## Related files in this repo

| File | Role |
|------|------|
| [modern-terminal-stack.md](./modern-terminal-stack.md) | Architecture, `.zshrc` / Starship examples, Cursor + Claude Code, existing-config merge guide. |
| [install.sh](./install.sh) | **macOS** Homebrew + fzf integration + optional global Claude Code. |

If you want a **Linux shell script** mirroring `install.sh` for apt/dnf/pacman, say which distro family you use first (names differ too much for one safe generic script without your target).
