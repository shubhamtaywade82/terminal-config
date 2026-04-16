# terminal-config

Personal **terminal stack** for a fast **zsh** environment: prompt, smart history, fuzzy search, modern file/list tools, **tmux**, and hooks for **Cursor** + **Claude Code**. Config snippets and docs live here; dotfiles on each machine are merged by hand (this repo does not overwrite your `~/.zshrc`).

---

## What’s in this repo

| File | Description |
|------|-------------|
| [README.md](./README.md) | This file — orientation and quick start. |
| [modern-terminal-stack.md](./modern-terminal-stack.md) | Architecture, example `~/.zshrc` + Starship TOML, Cursor & Claude Code, merging with **existing** configs, checklists. |
| [FEATURES_AND_USAGE.md](./FEATURES_AND_USAGE.md) | Feature list and **how to use** each tool on **macOS and Linux**. |
| [install.sh](./install.sh) | **macOS only** — Homebrew installs, fzf integration script, optional global Claude Code (`npm`). |

---

## Quick start (macOS)

1. **Install packages** (review first if you like):

   ```bash
   ./install.sh --dry-run
   ./install.sh
   ```

   Options: `--skip-optional` (no lazygit/neovim), `--skip-claude`, `--skip-fzf-setup`, `--dotfiles-status` (read-only report).

2. **Wire up the shell** — Copy or merge sections from [modern-terminal-stack.md §3](./modern-terminal-stack.md) into `~/.zshrc` (Starship, zoxide, Atuin, fzf, aliases). See **§3b** so you don’t duplicate hooks.

3. **Starship** — Create or merge `~/.config/starship.toml` (example in **§4** of the same doc).

4. **Cursor** — Install the app and add the **`cursor`** shell command to `PATH` from the app.

5. **Check gaps** — After install:

   ```bash
   ./install.sh --dotfiles-status
   ```

   The script also prints **Still add manually** when something (e.g. hooks, `starship.toml`, `cursor` / `claude` on `PATH`) looks missing.

---

## Linux

`install.sh` is **not** used on Linux. Install the same tools with your distro or [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux), then use the same shell hooks and usage notes in [FEATURES_AND_USAGE.md](./FEATURES_AND_USAGE.md).

---

## Safety

- `install.sh` does **not** edit `~/.zshrc`, Starship, Cursor JSON, or Atuin config; it installs Homebrew formulae, runs the **fzf** installer (writes **`~/.fzf.zsh`**), and optionally **`npm install -g @anthropic-ai/claude-code`**.
- Re-running `./install.sh` is safe for already-installed Homebrew formulae; use `brew upgrade` when you want newer versions.
- Details: [modern-terminal-stack.md](./modern-terminal-stack.md) (install + existing-config sections).

---

## Requirements

- **macOS** for `install.sh`.
- **Homebrew** on PATH for `install.sh`.
- **Node / npm** on PATH if you want the script to install **Claude Code** (or use `--skip-claude`).
