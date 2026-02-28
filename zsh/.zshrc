# ╔══════════════════════════════════════════════════════════╗
# ║           .ZSHRC — Tokyo Night Zsh Config                ║
# ║  • Starship prompt                                       ║
# ║  • zsh-autosuggestions (ghost text animado)              ║
# ║  • zsh-syntax-highlighting (colores Tokyo Night)         ║
# ║  • History, completions, keybinds Vi                     ║
# ╚══════════════════════════════════════════════════════════╝

# ── Instant prompt (Powerlevel10k override — no usado pero útil) ──
# (Si alguna vez cambian a p10k, este bloque es necesario)
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# ──────────────────── HISTORIAL ──────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY        # guarda timestamp
setopt SHARE_HISTORY           # comparte entre terminales abiertos
setopt INC_APPEND_HISTORY      # añade al historial en tiempo real
setopt HIST_IGNORE_DUPS        # no guarda duplicados consecutivos
setopt HIST_IGNORE_ALL_DUPS    # elimina duplicados más antiguos
setopt HIST_FIND_NO_DUPS       # no muestra duplicados al buscar
setopt HIST_IGNORE_SPACE       # no guarda líneas que empiecen con espacio
setopt HIST_REDUCE_BLANKS      # limpia espacios extra

# ──────────────────── OPCIONES GENERALES ─────────────────────
setopt AUTO_CD              # cd sin escribir 'cd'
setopt AUTO_PUSHD           # guarda directorio anterior en pila
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS # permite comentarios # en el prompt
setopt NO_BEEP              # sin pitidos

# ──────────────────── COMPLETIONS ────────────────────────────
autoload -Uz compinit
# Regenerar compdump solo si tiene más de 24h (velocidad)
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# Estilo del menú de completado
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:warnings' format '%F{red}Sin coincidencias para: %d%f'
zstyle ':completion::complete:*' gain-privileges 1

# ──────────────────── VI MODE ────────────────────────────────
bindkey -v
export KEYTIMEOUT=1

# Navegar con hjkl en el menú de completado
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

# Cursor cambia entre insert (beam) y normal (block) en vi mode
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'   # block cursor
  elif [[ ${KEYMAP} == main ]] || [[ ${KEYMAP} == viins ]] || [[ -z ${KEYMAP} ]] || [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'   # beam cursor
  fi
}
zle -N zle-keymap-select

function zle-line-init {
  echo -ne '\e[5 q'  # beam cursor al iniciar línea
}
zle -N zle-line-init

# Mantener Ctrl+R para búsqueda de historial en vi mode
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward
bindkey '^P' up-line-or-search
bindkey '^N' down-line-or-search
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^W' backward-kill-word

# ──────────────────── VARIABLES DE ENTORNO ───────────────────
export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="less"
export LESS="-R --mouse"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"  # bat como pager de man
export STARSHIP_CONFIG="$HOME/.config/starship.toml"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export PATH="$HOME/.local/bin:$PATH"

# Colores en ls / eza
export LS_COLORS="di=1;34:ln=1;36:ex=1;32:*.tar=1;31:*.zip=1;31"

# ──────────────────── ALIASES ─────────────────────────────────
alias ls="ls --color=auto -hF"
alias ll="ls -lAhF --color=auto"
alias la="ls -lAhF --color=auto"
alias tree="tree -C"
alias grep="grep --color=auto"
alias diff="diff --color=auto"
alias ip="ip --color=auto"

# Eza (si está instalado, reemplaza ls)
if command -v eza &>/dev/null; then
  alias ls="eza --icons --group-directories-first"
  alias ll="eza -lAhF --icons --group-directories-first --git"
  alias la="eza -lAhF --icons --group-directories-first --git"
  alias tree="eza --tree --icons"
fi

# Editor
alias v="nvim"
alias vi="nvim"
alias vim="nvim"

# Clipboard
alias cb="cliphist list | fzf --no-sort | cliphist decode | wl-copy"

# Hyprland
alias hreload="hyprctl reload"
alias hkill="hyprctl kill"
alias hclients="hyprctl clients"

# Git
alias g="git"
alias gst="git status"
alias gco="git checkout"
alias gcm="git commit -m"
alias gp="git push"
alias gl="git log --oneline --graph --decorate"

# Navegar
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Cava en ventana flotante
alias vis="kitty --class=cava-float --title=cava cava"

# ──────────────────── FUNCIONES ÚTILES ───────────────────────

# Crear directorio y entrar en él
mkcd() { mkdir -p "$1" && cd "$1" }

# Extraer cualquier archivo comprimido
extract() {
  case "$1" in
    *.tar.bz2) tar xjf "$1"   ;;
    *.tar.gz)  tar xzf "$1"   ;;
    *.tar.xz)  tar xJf "$1"   ;;
    *.tar.zst) tar --zst -xf "$1" ;;
    *.tar)     tar xf "$1"    ;;
    *.bz2)     bunzip2 "$1"   ;;
    *.gz)      gunzip "$1"    ;;
    *.zip)     unzip "$1"     ;;
    *.7z)      7z x "$1"      ;;
    *.rar)     unrar x "$1"   ;;
    *) echo "No sé cómo extraer '$1'" ;;
  esac
}

# Ver código fuente con bat + colores
bcat() { bat --style=numbers,changes,header "$@" }

# ──────────────────── PLUGINS (ORDEN CRÍTICO) ────────────────

# 1. Autosuggestions — primero
if [[ -f ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#565f89,italic'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=1

# Aceptar sugerencia completa con →
bindkey '^ ' autosuggest-accept     # Ctrl+Space
bindkey '^f' autosuggest-accept     # Ctrl+F

# 2. History substring search
if [[ -f ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh ]]; then
  source ~/.zsh/zsh-history-substring-search/zsh-history-substring-search.zsh
  HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='bg=#292e42,fg=#7aa2f7,bold'
  HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND='bg=#292e42,fg=#f7768e,bold'
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down
fi

# 3. Syntax highlighting — SIEMPRE AL FINAL
if [[ -f ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source ~/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Activar todos los highlighters disponibles
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor line)

# Mapeo de colores — Tokyo Night completo
ZSH_HIGHLIGHT_STYLES[default]='fg=#a9b1d6'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f7768e,bold'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#bb9af7,bold'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#7aa2f7,underline'
ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#7aa2f7,bold'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#7dcfff,italic'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#bb9af7'
ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=#73daca,italic,underline'
ZSH_HIGHLIGHT_STYLES[path]='fg=#73daca,underline'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#565f89'
ZSH_HIGHLIGHT_STYLES[path_prefix]='fg=#73daca,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#ff9e64,bold'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#bb9af7,underline'
ZSH_HIGHLIGHT_STYLES[command-substitution]='fg=#7aa2f7'
ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg=#2ac3de,bold'
ZSH_HIGHLIGHT_STYLES[process-substitution]='fg=#7aa2f7'
ZSH_HIGHLIGHT_STYLES[process-substitution-delimiter]='fg=#2ac3de,bold'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#e0af68'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#e0af68'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#bb9af7'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#9ece6a'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#9ece6a'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#9ece6a'
ZSH_HIGHLIGHT_STYLES[rc-quote]='fg=#73daca'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#e0af68,bold'
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=#e0af68'
ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=#e0af68'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#c0caf5'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#bb9af7,bold'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#565f89,italic'
ZSH_HIGHLIGHT_STYLES[named-fd]='fg=#73daca'
ZSH_HIGHLIGHT_STYLES[numeric-fd]='fg=#e0af68'
ZSH_HIGHLIGHT_STYLES[arg0]='fg=#7aa2f7,bold'         # comando en sí
ZSH_HIGHLIGHT_STYLES[command]='fg=#7aa2f7,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#7dcfff,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=#7aa2f7'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#7aa2f7'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#7aa2f7'

# Brackets — resaltado de pares ( ) [ ] { }
ZSH_HIGHLIGHT_STYLES[bracket-error]='fg=#f7768e,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=#7aa2f7,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=#bb9af7,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=#73daca,bold'
ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg=#e0af68,bold'
ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]='underline'

# Cursor highlighter — el caracter bajo el cursor
ZSH_HIGHLIGHT_STYLES[cursor]='standout'

# ──────────────────── STARSHIP — AL FINAL ────────────────────
eval "$(starship init zsh)"
