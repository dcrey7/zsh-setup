#!/usr/bin/env bash
# Bootstraps a complete zsh prompt setup on a fresh macOS, Ubuntu, or Arch:
#   pkg manager -> Meslo Nerd Font -> fzf -> oh-my-zsh -> custom plugins -> theme + .zshrc -> default shell
# macOS uses Homebrew; Ubuntu uses apt + a direct Nerd Font download; Arch uses pacman.
# Custom plugins: fzf-tab, zsh-autosuggestions, fast-syntax-highlighting
# Idempotent -- safe to re-run.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
echo "==> 0/8  Detecting OS"
case "$(uname -s)" in
  Darwin)
    OS="macos"
    echo "    macOS detected."
    ;;
  Linux)
    if [[ -r /etc/os-release ]] && grep -qiE '^(ID|ID_LIKE)=.*(ubuntu|debian)' /etc/os-release; then
      OS="ubuntu"
      echo "    Ubuntu/Debian detected."
    elif [[ -r /etc/os-release ]] && grep -qiE '^(ID|ID_LIKE)=.*(arch|cachyos)' /etc/os-release; then
      OS="arch"
      echo "    Arch/CachyOS detected."
    else
      echo "    ERROR: Linux detected but not Ubuntu/Debian or Arch/CachyOS. Only macOS, Ubuntu/Debian, and Arch/CachyOS are supported." >&2
      exit 1
    fi
    ;;
  *)
    echo "    ERROR: Unsupported OS '$(uname -s)'. Only macOS, Ubuntu/Debian, and Arch/CachyOS are supported." >&2
    exit 1
    ;;
esac

# ---------------------------------------------------------------------------
echo "==> 1/8  Package manager"
if [[ "$OS" == "macos" ]]; then
  if ! command -v brew >/dev/null 2>&1; then
    echo "    Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  else
    echo "    Already installed: $(brew --version | head -1)"
  fi
elif [[ "$OS" == "ubuntu" ]]; then
  echo "    Refreshing apt index (sudo required)..."
  sudo apt-get update -y
  echo "    Installing prerequisites (curl, git, unzip, fontconfig)..."
  sudo apt-get install -y curl git unzip fontconfig
elif [[ "$OS" == "arch" ]]; then
  if ! command -v pacman >/dev/null 2>&1; then
    echo "    ERROR: pacman not found on Arch system." >&2
    exit 1
  fi
  echo "    Refreshing pacman database..."
  sudo pacman -Sy --noconfirm
fi

# ---------------------------------------------------------------------------
echo "==> 2/8  zsh"
if ! command -v zsh >/dev/null 2>&1; then
  if [[ "$OS" == "macos" ]]; then
    echo "    Installing zsh via Homebrew..."
    brew install zsh
  elif [[ "$OS" == "ubuntu" ]]; then
    echo "    Installing zsh via apt..."
    sudo apt-get install -y zsh
  elif [[ "$OS" == "arch" ]]; then
    echo "    Installing zsh via pacman..."
    sudo pacman -S --noconfirm --needed zsh
  fi
else
  echo "    Already installed: $(zsh --version)"
fi

# ---------------------------------------------------------------------------
echo "==> 3/8  Meslo Nerd Font"
if [[ "$OS" == "macos" ]]; then
  if brew list --cask font-meslo-lg-nerd-font >/dev/null 2>&1; then
    echo "    Already installed."
  else
    echo "    Installing via Homebrew Cask..."
    brew install --cask font-meslo-lg-nerd-font
  fi
elif [[ "$OS" == "ubuntu" ]]; then
  font_dir="$HOME/.local/share/fonts/Meslo"
  if fc-list 2>/dev/null | grep -qi 'MesloLG.*Nerd Font'; then
    echo "    Already installed (found via fc-list)."
  else
    echo "    Downloading Meslo Nerd Font v3.4.0..."
    mkdir -p "$font_dir"
    tmp_zip="$(mktemp --suffix=.zip)"
    curl -fL -o "$tmp_zip" \
      https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Meslo.zip
    unzip -o -q "$tmp_zip" -d "$font_dir"
    rm -f "$tmp_zip"
    echo "    Refreshing font cache..."
    fc-cache -f "$font_dir"
  fi
elif [[ "$OS" == "arch" ]]; then
  if pacman -Qq ttf-meslo-nerd >/dev/null 2>&1; then
    echo "    Meslo Nerd Font already installed."
  else
    sudo pacman -S --noconfirm --needed ttf-meslo-nerd
  fi
  fc-cache -fv >/dev/null 2>&1 || true
fi

# ---------------------------------------------------------------------------
echo "==> 4/8  fzf"
if [[ "$OS" == "macos" ]]; then
  if brew list fzf >/dev/null 2>&1; then
    echo "    Already installed: $(fzf --version)"
  else
    echo "    Installing via Homebrew..."
    brew install fzf
  fi
elif [[ "$OS" == "ubuntu" ]]; then
  if dpkg -s fzf >/dev/null 2>&1; then
    echo "    Already installed: $(fzf --version)"
  else
    echo "    Installing via apt..."
    sudo apt-get install -y fzf
  fi
elif [[ "$OS" == "arch" ]]; then
  sudo pacman -S --noconfirm --needed fzf
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
login_user="${USER:-$(whoami)}"
current_shell="$(getent passwd "$login_user" 2>/dev/null | cut -d: -f7 || true)"
if [[ "$current_shell" == "$zsh_path" ]]; then
  echo "    Already set to zsh ($zsh_path)."
else
  # Add to /etc/shells if missing (chsh requires this)
  if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
    echo "    Adding $zsh_path to /etc/shells (sudo required)..."
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi
  echo "    Setting zsh as default login shell..."
  if chsh -s "$zsh_path" 2>/dev/null; then
    echo "    Default shell set to zsh via chsh."
  elif sudo -n chsh -s "$zsh_path" "$login_user" 2>/dev/null; then
    echo "    Default shell set to zsh via passwordless sudo."
  elif sudo chsh -s "$zsh_path" "$login_user"; then
    echo "    Default shell set to zsh via sudo (you may have typed your password)."
  else
    echo "    WARNING: could not set zsh as default shell."
    echo "    Run this manually: sudo chsh -s $zsh_path $login_user"
  fi
fi

# ---------------------------------------------------------------------------
echo ""
echo "✓ Done."
echo ""
echo "Final manual step (one time, can't be scripted reliably):"
echo "  Set your terminal font to a Meslo Nerd Font variant (e.g. 'MesloLGM Nerd Font')."
if [[ "$OS" == "macos" ]]; then
  cat <<'EOF'
    Terminal.app  -> Settings (⌘,) -> Profiles -> active profile
                  -> Text tab -> Change Font... -> "MesloLGM Nerd Font"
    iTerm2        -> Settings (⌘,) -> Profiles -> Text -> Font
EOF
else
  cat <<'EOF'
    GNOME Terminal -> Preferences -> your profile -> Text
                   -> tick "Custom font" -> "MesloLGM Nerd Font"
    Konsole        -> Settings -> Edit Current Profile -> Appearance -> Font
    Tilix / Terminator / Alacritty / kitty -> see each app's font setting
EOF
fi
echo ""
echo "Activating the new shell:"
echo "  - Right now, in this same terminal:  exec zsh"
echo "    (replaces the running shell in-place; you'll see the new prompt + plugins immediately)"
if [[ "$OS" == "macos" ]]; then
  echo "  - For every NEW terminal from now on:  quit and reopen Terminal.app"
else
  echo "  - For every NEW terminal from now on:  log out of your desktop session and log back in"
  echo "    (chsh only takes effect for new login sessions, not for already-running ones)"
fi
