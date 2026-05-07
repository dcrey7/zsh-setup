#!/usr/bin/env bash
# Removes the zsh setup: oh-my-zsh, the custom theme, ~/.zshrc, related caches,
# fzf, and the Meslo Nerd Font. zsh itself and Homebrew are left in place.
set -euo pipefail

echo "This will undo the zsh setup:"
echo "  - Remove oh-my-zsh custom plugins (fzf-tab, zsh-autosuggestions, fast-syntax-highlighting)"
echo "  - Remove ~/.oh-my-zsh"
echo "  - Remove ~/.zshrc and backups (.zshrc.backup.*, .zshrc.pre-oh-my-zsh)"
echo "  - Remove oh-my-zsh's completion caches (.zcompdump*, .zcompcache)"
echo "  - Remove fzf shell-integration files (~/.fzf.zsh, ~/.fzf.bash if present)"
echo "  - Uninstall fzf (brew)"
echo "  - Uninstall Meslo Nerd Font (brew cask)"
echo ""
echo "It will NOT touch:"
echo "  • zsh itself (system /bin/zsh stays -- macOS default)"
echo "  • Homebrew"
echo "  • Your shell history (.zsh_history)"
echo "  • Other personal zsh files (.zprofile, .zshenv, etc.)"
echo "  • Terminal.app font setting (manual step shown at end)"
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
if command -v brew >/dev/null 2>&1 && brew list fzf >/dev/null 2>&1; then
  brew uninstall fzf
else
  echo "    Not installed via Homebrew, skipping."
fi

# ---------------------------------------------------------------------------
echo "==> 5/5  Meslo Nerd Font"
if command -v brew >/dev/null 2>&1 && brew list --cask font-meslo-lg-nerd-font >/dev/null 2>&1; then
  brew uninstall --cask font-meslo-lg-nerd-font
else
  echo "    Not installed via Homebrew, skipping."
fi

# ---------------------------------------------------------------------------
cat <<'EOF'

✓ Done. oh-my-zsh + theme removed; zsh + Homebrew kept.

To finish -- reset Terminal.app's font to default (manual, one time):
  Terminal → Settings (⌘,) → Profiles → your active profile
  → Text tab → Change Font... → pick "SF Mono Regular 11" (macOS default)

Open a new terminal afterwards. You'll see the plain default zsh prompt:
  thomas@host current-folder %
EOF
