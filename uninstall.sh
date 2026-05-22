#!/usr/bin/env bash
# Removes the zsh setup: oh-my-zsh, the custom theme, ~/.zshrc, related caches,
# fzf, and the Meslo Nerd Font. zsh itself and the system package manager are left in place
# except on Arch, where install.sh installs zsh and uninstall.sh removes the same package set.
# Supports macOS (Homebrew), Ubuntu/Debian (apt), and Arch/CachyOS (pacman).
set -euo pipefail

# ---------------------------------------------------------------------------
case "$(uname -s)" in
  Darwin) OS="macos" ;;
  Linux)
    if [[ -r /etc/os-release ]] && grep -qiE '^(ID|ID_LIKE)=.*(ubuntu|debian)' /etc/os-release; then
      OS="ubuntu"
    elif [[ -r /etc/os-release ]] && grep -qiE '^(ID|ID_LIKE)=.*(arch|cachyos)' /etc/os-release; then
      OS="arch"
    else
      echo "ERROR: Linux detected but not Ubuntu/Debian or Arch/CachyOS." >&2
      exit 1
    fi
    ;;
  *)
    echo "ERROR: Unsupported OS '$(uname -s)'." >&2
    exit 1
    ;;
esac

revert_default_shell() {
  local target_shell="$1"
  local login_user="${USER:-$(whoami)}"
  local current_shell
  current_shell="$(getent passwd "$login_user" 2>/dev/null | cut -d: -f7 || true)"

  if [[ "$current_shell" == "$target_shell" ]]; then
    echo "    Default shell already $target_shell"
    return 0
  fi

  if ! grep -qx "$target_shell" /etc/shells 2>/dev/null; then
    echo "    Adding $target_shell to /etc/shells (sudo required)..."
    echo "$target_shell" | sudo tee -a /etc/shells >/dev/null || true
  fi

  if chsh -s "$target_shell" 2>/dev/null; then
    echo "    Default shell reverted via chsh"
  elif sudo -n chsh -s "$target_shell" "$login_user" 2>/dev/null; then
    echo "    Default shell reverted via passwordless sudo"
  elif sudo chsh -s "$target_shell" "$login_user"; then
    echo "    Default shell reverted via sudo (may have prompted for password)"
  else
    echo "    WARNING: could not revert default shell"
    echo "    Run this manually: sudo chsh -s $target_shell $login_user"
  fi
}

echo "This will undo the zsh setup ($OS):"
echo "  - Remove oh-my-zsh custom plugins (fzf-tab, zsh-autosuggestions, fast-syntax-highlighting)"
echo "  - Remove ~/.oh-my-zsh"
echo "  - Restore the latest ~/.zshrc.backup.* if present, otherwise remove ~/.zshrc"
echo "  - Remove old backups (.zshrc.backup.*, .zshrc.pre-oh-my-zsh)"
echo "  - Remove oh-my-zsh's completion caches (.zcompdump*, .zcompcache)"
echo "  - Remove fzf shell-integration files (~/.fzf.zsh, ~/.fzf.bash if present)"
if [[ "$OS" == "macos" ]]; then
  echo "  - Uninstall fzf (brew)"
  echo "  - Uninstall Meslo Nerd Font (brew cask)"
elif [[ "$OS" == "ubuntu" ]]; then
  echo "  - Uninstall fzf (apt)"
  echo "  - Remove Meslo Nerd Font from ~/.local/share/fonts/Meslo and refresh font cache"
else
  echo "  - Uninstall zsh, fzf, and Meslo Nerd Font (pacman)"
fi
echo "  - Revert the default login shell"
echo ""
echo "It will NOT touch:"
if [[ "$OS" == "macos" ]]; then
  echo "  • zsh itself"
  echo "  • Homebrew"
elif [[ "$OS" == "ubuntu" ]]; then
  echo "  • zsh itself"
  echo "  • apt / system packages other than fzf"
else
  echo "  • pacman / system packages other than zsh, fzf, and ttf-meslo-nerd"
fi
echo "  • Your shell history (.zsh_history)"
echo "  • Other personal zsh files (.zprofile, .zshenv, etc.)"
echo "  • Terminal app font setting (manual step shown at end)"
echo ""
if [[ "${1:-}" != "-y" && "${1:-}" != "--yes" ]]; then
  read -r -p "Continue? [y/N] " confirm
  [[ "${confirm:-}" =~ ^[Yy] ]] || { echo "Aborted."; exit 0; }
fi

# ---------------------------------------------------------------------------
echo "==> 1/6  oh-my-zsh custom plugins (fzf-tab, autosuggestions, fast-syntax-highlighting)"
plugin_root="$HOME/.oh-my-zsh/custom/plugins"
removed=0
for name in fzf-tab zsh-autosuggestions fast-syntax-highlighting; do
  if [[ -d "$plugin_root/$name" ]]; then
    rm -rf "$plugin_root/$name"
    echo "    Removed $plugin_root/$name"
    removed=$((removed + 1))
  fi
done
[[ $removed -eq 0 ]] && echo "    No custom plugins present, skipping."

# ---------------------------------------------------------------------------
echo "==> 2/6  oh-my-zsh"
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  rm -rf "$HOME/.oh-my-zsh"
  echo "    Removed ~/.oh-my-zsh"
else
  echo "    Not present, skipping."
fi

# ---------------------------------------------------------------------------
echo "==> 3/6  ~/.zshrc, backups, fzf integration files, and oh-my-zsh caches"
removed=0
for f in \
  "$HOME/.zshrc.pre-oh-my-zsh" \
  "$HOME/.zcompcache" \
  "$HOME/.fzf.zsh" \
  "$HOME/.fzf.bash"; do
  if [[ -e "$f" ]]; then
    rm -rf "$f"
    echo "    Removed $f"
    removed=$((removed + 1))
  fi
done

backup_candidates=("$HOME"/.zshrc.backup.*)
if [[ -e "${backup_candidates[0]}" ]]; then
  latest_backup="$(printf '%s\n' "${backup_candidates[@]}" | sort | tail -n 1)"
  cp "$latest_backup" "$HOME/.zshrc"
  echo "    Restored $latest_backup -> $HOME/.zshrc"
  for g in "${backup_candidates[@]}"; do
    rm -rf "$g"
    echo "    Removed $g"
    removed=$((removed + 1))
  done
elif [[ -e "$HOME/.zshrc" ]]; then
  rm -rf "$HOME/.zshrc"
  echo "    Removed $HOME/.zshrc"
  removed=$((removed + 1))
else
  echo "    No ~/.zshrc backup present; ~/.zshrc already absent."
fi

for g in "$HOME"/.zcompdump*; do
  [[ -e "$g" ]] || continue
  rm -rf "$g"
  echo "    Removed $g"
  removed=$((removed + 1))
done
echo "    Total: $removed file(s)/dir(s) removed"

# ---------------------------------------------------------------------------
echo "==> 4/6  Packages"
if [[ "$OS" == "macos" ]]; then
  if command -v brew >/dev/null 2>&1 && brew list fzf >/dev/null 2>&1; then
    brew uninstall fzf
  else
    echo "    Not installed via Homebrew, skipping."
  fi
elif [[ "$OS" == "ubuntu" ]]; then
  if dpkg -s fzf >/dev/null 2>&1; then
    sudo apt-get remove -y fzf
  else
    echo "    Not installed via apt, skipping."
  fi
elif [[ "$OS" == "arch" ]]; then
  echo "    Removing Arch packages installed by install.sh..."
  sudo pacman -Rns --noconfirm zsh fzf ttf-meslo-nerd 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
echo "==> 5/6  Meslo Nerd Font"
if [[ "$OS" == "macos" ]]; then
  if command -v brew >/dev/null 2>&1 && brew list --cask font-meslo-lg-nerd-font >/dev/null 2>&1; then
    brew uninstall --cask font-meslo-lg-nerd-font
  else
    echo "    Not installed via Homebrew, skipping."
  fi
elif [[ "$OS" == "ubuntu" ]]; then
  font_dir="$HOME/.local/share/fonts/Meslo"
  if [[ -d "$font_dir" ]]; then
    rm -rf "$font_dir"
    echo "    Removed $font_dir"
    if command -v fc-cache >/dev/null 2>&1; then
      echo "    Refreshing font cache..."
      fc-cache -f
    fi
  else
    echo "    Not present at $font_dir, skipping."
  fi
elif [[ "$OS" == "arch" ]]; then
  echo "    Handled by pacman package removal, skipping."
fi

# ---------------------------------------------------------------------------
echo "==> 6/6  Default shell"
case "$OS" in
  macos) target_shell="/bin/zsh" ;;
  ubuntu) target_shell="/bin/bash" ;;
  arch) target_shell="/bin/bash" ;;
esac
revert_default_shell "$target_shell"

# ---------------------------------------------------------------------------
echo ""
echo "✓ Done. oh-my-zsh + theme removed."
echo ""
echo "To finish -- reset your terminal's font to default (manual, one time):"
if [[ "$OS" == "macos" ]]; then
  cat <<'EOF'
  Terminal -> Settings (⌘,) -> Profiles -> active profile
           -> Text tab -> Change Font... -> "SF Mono Regular 11" (macOS default)
EOF
else
  cat <<'EOF'
  GNOME Terminal -> Preferences -> your profile -> Text -> untick "Custom font"
  Konsole        -> Settings -> Edit Current Profile -> Appearance -> reset font
EOF
fi
echo ""
echo "Log out and back in afterwards so the reverted login shell takes effect."
