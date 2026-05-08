# 2026-05-08 23:26 CEST — Add Ubuntu support to install/uninstall scripts

## Summary
Previously the setup only worked on macOS (Homebrew-only). Added an OS detection
step at the top of both scripts and branched the OS-specific work so the same
repo bootstraps cleanly on macOS or Ubuntu/Debian.

Out of scope: Fedora (`dnf`), Arch (`pacman`), other Linux flavors. They exit
early with a clear error.

## Files changed

### `install.sh`
- Added **step 0/8: OS detection** — uses `uname -s` and `/etc/os-release`
  (`ID` / `ID_LIKE` matching `ubuntu|debian`). Exits with an error on anything
  else.
- **Step 1/8** renamed from "Homebrew" to "Package manager":
  - macOS: existing Homebrew install logic
  - Ubuntu: `sudo apt-get update` + installs `curl git unzip fontconfig`
- **Step 2/8 zsh**: Ubuntu now uses `apt-get install -y zsh`.
- **Step 3/8 Meslo Nerd Font**: Ubuntu branch downloads
  `Meslo.zip` from the nerd-fonts **v3.4.0** GitHub release into
  `~/.local/share/fonts/Meslo/`, then runs `fc-cache -f`. Idempotent via
  `fc-list | grep -qi 'MesloLG.*Nerd Font'`.
- **Step 4/8 fzf**: Ubuntu uses `apt-get install -y fzf` (idempotency via
  `dpkg -s fzf`).
- Steps 5–8 (oh-my-zsh, plugins, theme + `.zshrc`, default shell) are
  unchanged — they're OS-agnostic.
- Final manual-step message branches per OS: macOS shows
  Terminal.app/iTerm2 paths; Ubuntu shows GNOME Terminal / Konsole / Tilix /
  Alacritty / kitty hints.

### `uninstall.sh`
- Same OS detection block at the top.
- Step 4/5 fzf: Ubuntu uses `sudo apt-get remove -y fzf`.
- Step 5/5 Meslo Nerd Font: Ubuntu removes `~/.local/share/fonts/Meslo` and
  refreshes the font cache with `fc-cache -f`.
- Confirmation banner and trailing manual-step message also branch per OS.

### `README.md`
- "fresh macOS" → "fresh macOS or Ubuntu" wording everywhere.
- Replaced the macOS-only step list with an OS-aware one (9 numbered steps).
- Added per-terminal font-config hints (Terminal.app, iTerm2, GNOME Terminal,
  Konsole).
- Uninstall paragraph now mentions the Ubuntu font-removal path
  (`~/.local/share/fonts/Meslo` + `fc-cache`).

### Untouched
- `zshrc`, `mytheme.zsh-theme`, `screenshots/` — pure shell/asset content,
  works the same on both OSes.

## Verification
- `bash -n install.sh && bash -n uninstall.sh` → syntax OK.
- Did not run the install end-to-end on this machine (would actually install
  packages and replace `~/.zshrc` — should be tested on a fresh Ubuntu VM
  before relying on it).

## Notes / follow-ups
- Nerd Font version is pinned to **v3.4.0** in `install.sh`. When the upstream
  cuts a new release, bump that URL.
- Ubuntu 24.04+ ships zsh 5.9 and fzf ≥ 0.48 (which supports `fzf --zsh` for
  the keybinding source). On much older Ubuntus the `source <(fzf --zsh)` line
  in `zshrc` would be a no-op; not handling that since we're targeting recent
  Ubuntu.
- `/etc/shells` already contains `/usr/bin/zsh` on Ubuntu, so the
  "add to /etc/shells" branch in step 8 typically no-ops there.
