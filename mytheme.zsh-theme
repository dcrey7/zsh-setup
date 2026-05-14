zmodload zsh/datetime
setopt PROMPT_SUBST
export VIRTUAL_ENV_DISABLE_PROMPT=1   # suppress venv's auto "(name)" prefix

# Colors
USER_BG="#8B4513"; USER_FG="#ffffff"   # saddle brown (deep reddish-brown)
PATH_BG="#1e3a8a"; PATH_FG="#ffffff"
GIT_BG="#15803d";  GIT_FG="#ffffff"
PY_BG="#c2410c";   PY_FG="#ffffff"
TIME_BG="#7e22ce"; TIME_FG="#ffffff"   # purple

SEP=$''     # powerline right-arrow
BRANCH=$''  # powerline branch glyph
BOLT=$'⚡️'  # ⚡ with VS-16 → forces yellow emoji rendering

preexec() { _cmd_start=$EPOCHREALTIME }
precmd() {
  if [[ -n $_cmd_start ]]; then
    local e=$(( EPOCHREALTIME - _cmd_start ))
    if (( e < 1 )); then _cmd_elapsed=$(printf "%.0fms" $((e*1000)))
    else                  _cmd_elapsed=$(printf "%.2fs" $e); fi
    unset _cmd_start
  else
    _cmd_elapsed=""
  fi
}

_git_branch() { git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null }

_build_prompt() {
  print -n "%K{$USER_BG}%F{$USER_FG} 🕺 %n "
  local prev=$USER_BG

  print -n "%K{$PATH_BG}%F{$prev}${SEP}%F{$PATH_FG} 🗂️  %~ "
  prev=$PATH_BG

  local b=$(_git_branch)
  if [[ -n $b ]]; then
    print -n "%K{$GIT_BG}%F{$prev}${SEP}%F{$GIT_FG} ${BRANCH} ${b} "
    prev=$GIT_BG
  fi

  if [[ -n $VIRTUAL_ENV ]]; then
    print -n "%K{$PY_BG}%F{$prev}${SEP}%F{$PY_FG} 👾 ${VIRTUAL_ENV##*/} "
    prev=$PY_BG
  fi

  if [[ -n $_cmd_elapsed ]]; then
    print -n "%K{$TIME_BG}%F{$prev}${SEP}%F{$TIME_FG} ${BOLT} ${_cmd_elapsed} "
    prev=$TIME_BG
  fi

  print -n "%k%F{$prev}${SEP}%f"
}

PROMPT='$(_build_prompt)
> '

RPROMPT=''
