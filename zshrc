export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="mytheme"
plugins=(git zsh-autosuggestions fast-syntax-highlighting fzf-tab)

export PATH="$HOME/.local/bin:$PATH"

source "$ZSH/oh-my-zsh.sh"

# fzf — Ctrl+R history, Ctrl+T file picker, Alt+C cd picker, ** trigger
# Mix: Seoul256-Night structure + JellyX accents + VS Code Python syntax mapping
#   bg/fg : VS Code editor (#1e1e1e / #d4d4d4)
#   hl    : VS Code function-name yellow (#dcdcaa) — search-match feel
#   info  : VS Code comment green (#6a9955)
#   prompt: VS Code function blue (#569cd6)
#   pointer/marker: JellyX warm red/pink (#d75f5f / #d78787)
#   header: VS Code type teal (#4ec9b0)
export FZF_DEFAULT_OPTS="
  --color=fg:#d4d4d4,bg:#1e1e1e,hl:#dcdcaa
  --color=fg+:#ffffff,bg+:#2a2d2e,hl+:#dcdcaa
  --color=info:#6a9955,prompt:#569cd6,pointer:#d75f5f
  --color=marker:#d78787,spinner:#6a9955,header:#4ec9b0
  --color=border:#2a2d2e"
command -v fzf >/dev/null && source <(fzf --zsh)

# Make fzf-tab inherit the colors from FZF_DEFAULT_OPTS above (off by default)
zstyle ':fzf-tab:*' use-fzf-default-opts yes

# Tab completion enhancements
zstyle ':completion:*' menu select                                                  # arrow-key navigable menu
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'  # case-insensitive + partial-word
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}                               # color the menu
zstyle ':completion:*' group-name ''                                                # group results by type
