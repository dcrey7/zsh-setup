#!/usr/bin/env bash
# Bootstraps a complete zsh prompt setup on a fresh macOS:
#   Homebrew -> Meslo Nerd Font -> fzf -> oh-my-zsh -> custom plugins -> theme + .zshrc -> default shell
# Custom plugins: fzf-tab, zsh-autosuggestions, fast-syntax-highlighting
# Idempotent -- safe to re-run.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
echo "==> 1/8  Homebrew"
if ! command -v brew >/dev/null 2>&1; then
  echo "    Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Make brew available in this shell session
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "    Already installed: $(brew --version | head -1)"
fi

# ---------------------------------------------------------------------------
echo "==> 2/8  zsh"
if ! command -v zsh >/dev/null 2>&1; then
  echo "    Installing zsh via Homebrew..."
  brew install zsh
else
  echo "    Already installed: $(zsh --version)"
fi

# ---------------------------------------------------------------------------
echo "==> 3/8  Meslo Nerd Font"
if brew list --cask font-meslo-lg-nerd-font >/dev/null 2>&1; then
  echo "    Already installed."
else
  echo "    Installing via Homebrew Cask..."
  brew install --cask font-meslo-lg-nerd-font
fi

# ---------------------------------------------------------------------------
echo "==> 4/8  fzf"
if brew list fzf >/dev/null 2>&1; then
  echo "    Already installed: $(fzf --version)"
else
  echo "    Installing via Homebrew..."
  brew install fzf
fi
echo "    Keybindings wired up by '~/.zshrc' via 'source <(fzf --zsh)'"

# ---------------------------------------------------------------------------
echo "==> 5/8  oh-my-zsh"
if [[ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
  echo "    Already installed at ~/.oh-my-zsh"
else
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "    Found partial install at ~/.oh-my-zsh, removing first..."
    rm -rf "$HOME/.oh-my-zsh"
  fi
  echo "    Downloading and installing..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# ---------------------------------------------------------------------------
echo "==> 6/8  oh-my-zsh custom plugins (fzf-tab, autosuggestions, fast-syntax-highlighting)"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "    ERROR: ~/.oh-my-zsh missing -- step 5 must have failed. Re-run install.sh." >&2
  exit 1
fi
plugin_root="$HOME/.oh-my-zsh/custom/plugins"
mkdir -p "$plugin_root"

# name|repo-url -- fzf-tab MUST be loaded last in ~/.zshrc plugins=(...) per its docs,
# but the clone order here doesn't matter.
zsh_extras=(
  "fzf-tab|https://github.com/Aloxaf/fzf-tab"
  "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
  "fast-syntax-highlighting|https://github.com/zdharma-continuum/fast-syntax-highlighting"
)

for entry in "${zsh_extras[@]}"; do
  name="${entry%%|*}"
  url="${entry##*|}"
  dest="$plugin_root/$name"
  if [[ -d "$dest/.git" ]]; then
    echo "    [$name] already cloned, pulling latest..."
    git -C "$dest" pull --ff-only || echo "    [$name] pull failed, keeping existing copy"
  elif [[ -e "$dest" ]]; then
    echo "    [$name] stale (non-git) directory, removing and re-cloning..."
    rm -rf "$dest"
    git clone --depth=1 "$url" "$dest"
  else
    echo "    [$name] cloning..."
    git clone --depth=1 "$url" "$dest"
  fi
done

# ---------------------------------------------------------------------------
echo "==> 7/8  Custom theme + .zshrc"
mkdir -p "$HOME/.oh-my-zsh/custom/themes"
cp "$SCRIPT_DIR/mytheme.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/mytheme.zsh-theme"
echo "    Theme installed at ~/.oh-my-zsh/custom/themes/mytheme.zsh-theme"

if [[ -f "$HOME/.zshrc" ]]; then
  backup="$HOME/.zshrc.backup.$(date +%Y%m%d-%H%M%S)"
  cp "$HOME/.zshrc" "$backup"
  echo "    Backed up existing ~/.zshrc -> $backup"
fi
cp "$SCRIPT_DIR/zshrc" "$HOME/.zshrc"
echo "    Wrote new ~/.zshrc"

# ---------------------------------------------------------------------------
echo "==> 8/8  Default shell"
zsh_path="$(command -v zsh)"
if [[ "${SHELL:-}" != "$zsh_path" ]]; then
  # Add to /etc/shells if missing (chsh requires this)
  if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
    echo "    Adding $zsh_path to /etc/shells (sudo required)..."
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi
  echo "    Setting zsh as default login shell..."
  chsh -s "$zsh_path"
else
  echo "    Already set to $zsh_path"
fi

# ---------------------------------------------------------------------------
cat <<'EOF'

✓ Done.

Final manual step (one time, can't be scripted reliably):
  Open Terminal.app → Settings (⌘,) → Profiles → your active profile
  → Text tab → Change Font... → pick "MesloLGL Nerd Font" or "MesloLGS Nerd Font"

Then open a new terminal (or run: exec zsh) to see the prompt.
EOF
