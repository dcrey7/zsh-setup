#!/usr/bin/env bash
# Removes the zsh setup: oh-my-zsh, the custom theme, ~/.zshrc, related caches,
# fzf, and the Meslo Nerd Font. zsh itself and the system package manager are left in place.
# Supports macOS (Homebrew) and Ubuntu/Debian (apt).
set -euo pipefail

# ---------------------------------------------------------------------------
case "$(uname -s)" in
  Darwin) OS="macos" ;;
  Linux)
    if [[ -r /etc/os-release ]] && grep -qiE '^(ID|ID_LIKE)=.*(ubuntu|debian)' /etc/os-release; then
      OS="ubuntu"
    else
      echo "ERROR: Linux detected but not Ubuntu/Debian. Only macOS and Ubuntu are supported." >&2
      exit 1
    fi
    ;;
  *)
    echo "ERROR: Unsupported OS '$(uname -s)'. Only macOS and Ubuntu are supported." >&2
    exit 1
    ;;
esac

echo "This will undo the zsh setup ($OS):"
echo "  - Remove oh-my-zsh custom plugins (fzf-tab, zsh-autosuggestions, fast-syntax-highlighting)"
echo "  - Remove ~/.oh-my-zsh"
echo "  - Remove ~/.zshrc and backups (.zshrc.backup.*, .zshrc.pre-oh-my-zsh)"
echo "  - Remove oh-my-zsh's completion caches (.zcompdump*, .zcompcache)"
echo "  - Remove fzf shell-integration files (~/.fzf.zsh, ~/.fzf.bash if present)"
if [[ "$OS" == "macos" ]]; then
  echo "  - Uninstall fzf (brew)"
  echo "  - Uninstall Meslo Nerd Font (brew cask)"
else
  echo "  - Uninstall fzf (apt)"
  echo "  - Remove Meslo Nerd Font from ~/.local/share/fonts/Meslo and refresh font cache"
fi
echo ""
echo "It will NOT touch:"
echo "  • zsh itself"
if [[ "$OS" == "macos" ]]; then
  echo "  • Homebrew"
else
  echo "  • apt / system packages other than fzf"
fi
echo "  • Your shell history (.zsh_history)"
echo "  • Other personal zsh files (.zprofile, .zshenv, etc.)"
echo "  • Terminal app font setting (manual step shown at end)"
echo ""
read -r -p "Continue? [y/N] " confirm
[[ "${confirm:-}" =~ ^[Yy] ]] || { echo "Aborted."; exit 0; }

# ---------------------------------------------------------------------------
echo "==> 1/5  oh-my-zsh custom plugins (fzf-tab, autosuggestions, fast-syntax-highlighting)"
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
echo "==> 2/5  oh-my-zsh"
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  rm -rf "$HOME/.oh-my-zsh"
  echo "    Removed ~/.oh-my-zsh"
else
  echo "    Not present, skipping."
fi

# ---------------------------------------------------------------------------
echo "==> 3/5  ~/.zshrc, backups, fzf integration files, and oh-my-zsh caches"
removed=0
for f in \
  "$HOME/.zshrc" \
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
for g in "$HOME"/.zshrc.backup.* "$HOME"/.zcompdump*; do
  [[ -e "$g" ]] || continue
  rm -rf "$g"
  echo "    Removed $g"
  removed=$((removed + 1))
done
echo "    Total: $removed file(s)/dir(s) removed"

# ---------------------------------------------------------------------------
echo "==> 4/5  fzf"
if [[ "$OS" == "macos" ]]; then
  if command -v brew >/dev/null 2>&1 && brew list fzf >/dev/null 2>&1; then
    brew uninstall fzf
  else
    echo "    Not installed via Homebrew, skipping."
  fi
else
  if dpkg -s fzf >/dev/null 2>&1; then
    sudo apt-get remove -y fzf
  else
    echo "    Not installed via apt, skipping."
  fi
fi

# ---------------------------------------------------------------------------
echo "==> 5/5  Meslo Nerd Font"
if [[ "$OS" == "macos" ]]; then
  if command -v brew >/dev/null 2>&1 && brew list --cask font-meslo-lg-nerd-font >/dev/null 2>&1; then
    brew uninstall --cask font-meslo-lg-nerd-font
  else
    echo "    Not installed via Homebrew, skipping."
  fi
else
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
fi

# ---------------------------------------------------------------------------
echo ""
echo "✓ Done. oh-my-zsh + theme removed; zsh + package manager kept."
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
echo "Open a new terminal afterwards to see the plain default zsh prompt."
