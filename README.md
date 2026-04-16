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
| [install-linux.sh](./install-linux.sh) | **Linux (Debian/Ubuntu/WSL)** — `apt` core packages, upstream installers where apt is thin, `~/.fzf.zsh` for distro fzf paths, optional global Claude Code (`npm`). |

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

## Quick start (Linux — Debian / Ubuntu / WSL)

1. **Install packages** (review first if you like):

   ```bash
   chmod +x install-linux.sh   # once
   ./install-linux.sh --dry-run
   ./install-linux.sh
   ```

   Options match the mac script where it makes sense: `--skip-optional`, `--skip-claude`, `--skip-fzf-setup`, `--dotfiles-status`.

2. **Wire up the shell** — Same as macOS: merge [modern-terminal-stack.md §3](./modern-terminal-stack.md) into `~/.zshrc`. Ensure **`~/.local/bin`** and **`~/.atuin/bin`** are on `PATH` if installers put binaries there.

3. **Starship**, **Cursor**, **Check gaps** — Same steps as in [Quick start (macOS)](#quick-start-macos), using `./install-linux.sh --dotfiles-status` for the report.

Other distros (Fedora, Arch) or [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux): install the same tools manually; see [FEATURES_AND_USAGE.md § Install the stack](./FEATURES_AND_USAGE.md#install-the-stack).

---

## Safety

- `install.sh` does **not** edit `~/.zshrc`, Starship, Cursor JSON, or Atuin config; it installs Homebrew formulae, runs the **fzf** installer (writes **`~/.fzf.zsh`**), and optionally **`npm install -g @anthropic-ai/claude-code`**.
- `install-linux.sh` does **not** edit `~/.zshrc`, Starship, Cursor JSON, or Atuin config; it runs **`apt-get`**, may run **upstream curl installers** (Starship, zoxide, Atuin), writes **`~/.fzf.zsh`** (unless `--skip-fzf-setup`), links **`~/.local/bin/bat`** / **`fd`** when the distro uses `batcat` / `fdfind`, and optionally **`npm install -g @anthropic-ai/claude-code`**.
- Re-running `./install.sh` is safe for already-installed Homebrew formulae; use `brew upgrade` when you want newer versions. Re-running `./install-linux.sh` is safe for already-installed `apt` packages; use `apt upgrade` when you want newer versions.
- Details: [modern-terminal-stack.md](./modern-terminal-stack.md) (install + existing-config sections).

---

## Requirements

- **macOS** for `install.sh`.
- **Homebrew** on PATH for `install.sh`.
- **Linux** with **`apt-get`** (Debian, Ubuntu, typical WSL images) for `install-linux.sh`; **`sudo`** for package installs (or run as root).
- **Node / npm** on PATH if you want the installers to install **Claude Code** (or use `--skip-claude`).
