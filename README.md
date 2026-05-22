# zsh setup

Portable bundle of my zsh prompt config.

![preview](screenshots/preview.png)

## Usage
Once installed and you've opened a new shell:

- **`cd <Tab>`** — opens a fuzzy directory menu (also works for `git checkout`, `brew install`, `kill`, and every other command)
- **`↑` / `↓`** to navigate the menu — start typing to filter
- **`Enter`** to select — **`Esc`** (or `Ctrl+C`) to cancel and go back
- **`Ctrl+R`** — fuzzy search through shell history
- **`Ctrl+T`** — fuzzy file picker (inserts the chosen path into your current command)
- **`Alt+C`** — fuzzy `cd` into a subdirectory
- **`**<Tab>`** — alternate trigger for fuzzy picker mid-command (e.g. `vim **<Tab>`)
- **`→`** (right arrow) — accept the grey ghost-text suggestion from `zsh-autosuggestions`

## Contents
- `install.sh` — bootstraps everything on a fresh macOS, Ubuntu/Debian, or Arch/CachyOS
- `uninstall.sh` — reverts the machine (removes oh-my-zsh, theme, .zshrc, fzf, font)
- `mytheme.zsh-theme` — the custom oh-my-zsh theme (powerline-style segments: 📂 path, ⎇ branch, 👾 venv, ⚡ time)
- `zshrc` — drop-in `~/.zshrc` with theme, fzf keybindings, custom plugins (fzf-tab, autosuggestions, fast-syntax-highlighting), and tab-completion settings

## Install (fresh machine)
```sh
chmod +x install.sh
./install.sh
```

The script auto-detects the OS (macOS, Ubuntu/Debian, or Arch/CachyOS) and uses the right package manager:

1. **OS detection** — exits early on anything other than macOS, Ubuntu/Debian, or Arch/CachyOS
2. **Package manager** — installs Homebrew on macOS; runs `apt-get update` and installs `curl git unzip fontconfig` on Ubuntu; runs `pacman -Sy` on Arch/CachyOS
3. **zsh** — `brew install zsh` (macOS), `apt-get install zsh` (Ubuntu), or `pacman -S --needed zsh` (Arch/CachyOS)
4. **Meslo Nerd Font**
   - macOS: `brew install --cask font-meslo-lg-nerd-font`
   - Ubuntu: downloads `Meslo.zip` from the [nerd-fonts v3.4.0 release](https://github.com/ryanoasis/nerd-fonts/releases/tag/v3.4.0) into `~/.local/share/fonts/Meslo/`, then runs `fc-cache`
   - Arch/CachyOS: installs the official `ttf-meslo-nerd` package from the Arch repositories, then refreshes the font cache
5. **fzf** — `brew install fzf`, `apt-get install fzf`, or `pacman -S --needed fzf`; keybindings wired up by `~/.zshrc`
6. **oh-my-zsh** — installed via the official unattended installer (skipped if already present)
7. **Custom plugins** — cloned into `~/.oh-my-zsh/custom/plugins/`:
   - [fzf-tab](https://github.com/Aloxaf/fzf-tab) — fuzzy `<Tab>` completion for every command
   - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) — ghost-text history suggestions (accept with `→`)
   - [fast-syntax-highlighting](https://github.com/zdharma-continuum/fast-syntax-highlighting) — colors commands as you type
8. **Theme + `~/.zshrc`** — theme copied into `~/.oh-my-zsh/custom/themes/`, existing `~/.zshrc` backed up with a timestamp suffix
9. **Default shell** — `chsh -s "$(command -v zsh)"`

After it finishes, set your terminal font to **MesloLGM Nerd Font** (or any Meslo Nerd Font variant) — that step has to be done in the terminal app's preferences:
- macOS Terminal.app / iTerm2 — Settings → Profiles → Text → Font
- GNOME Terminal — Preferences → your profile → Text → Custom font
- Konsole — Settings → Edit Current Profile → Appearance → Font

### Arch/CachyOS notes

On Arch and CachyOS, the installer uses `pacman` for the system packages. It refreshes the package database with `pacman -Sy`, installs `zsh` and `fzf` with `--needed`, and uses the repository package `ttf-meslo-nerd` instead of downloading the font zip manually.

### Activating the new shell

`chsh` only changes the **default login shell** — your current terminal session is still running the old one. To see the new prompt + plugins:

- **Right now, in the same terminal:** run `exec zsh`. It replaces the running shell in-place and you'll see the new prompt, autosuggestions, and fuzzy tab immediately.
- **For every new terminal you open from now on:** **log out of your desktop session and log back in** (on Ubuntu/Linux) or **quit and reopen Terminal.app** (on macOS). New terminal windows will then start in zsh by default — no `exec zsh` needed.

If after logging back in your terminals still open in bash on Ubuntu, check `getent passwd $USER | cut -d: -f7` — it should print `/usr/bin/zsh`. If it doesn't, re-run `chsh -s "$(command -v zsh)"`. If it does but GNOME Terminal still launches bash, look in **Preferences → your profile → Command tab** and make sure "Run command as a login shell" / "Custom command" is unchecked.

## Uninstall
```sh
chmod +x uninstall.sh
./uninstall.sh
```
Asks for confirmation, then removes the theme, oh-my-zsh, `.zshrc` (+ backups), fzf, and the Meslo Nerd Font. On Ubuntu the font is removed from `~/.local/share/fonts/Meslo` and the font cache is refreshed. Leaves zsh itself and the system package manager in place.
