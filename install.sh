#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║         HYPRLAND RICE INSTALLER — Arch Linux Only               ║
# ║         Tokyo Night · AGS v2 · Kitty · Zsh · cava               ║
# ║                                                                  ║
# ║  Uso:                                                            ║
# ║    ./install.sh              → instalador interactivo            ║
# ║    ./install.sh --uninstall  → eliminar symlinks del rice        ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ──────────────────── COLORES ─────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'  # No Color

# ──────────────────── HELPERS ────────────────────────────────────
ok()   { echo -e "${GREEN}  ✓${NC}  $*"; }
info() { echo -e "${BLUE}  →${NC}  $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC}  $*"; }
err()  { echo -e "${RED}  ✗${NC}  $*" >&2; }
step() { echo -e "\n${BOLD}${PURPLE}══ $* ══${NC}"; }
ask()  { echo -e "${CYAN}  ?${NC}  $*"; }

# Directorio raíz del repo (donde se ejecuta install.sh)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
AUR_HELPER=""

# ──────────────────── VERIFICAR ARCH ────────────────────────────
check_arch() {
  if [[ ! -f /etc/arch-release ]]; then
    err "Este rice está optimizado para Arch Linux."
    err "Tu sistema no es Arch (no se encontró /etc/arch-release)."
    echo -e "\n${DIM}  Si usas Arch con kernel personalizado, crea /etc/arch-release vacío para continuar.${NC}"
    exit 1
  fi
  ok "Arch Linux detectado"
}

# ──────────────────── DETECTAR AUR HELPER ───────────────────────
detect_aur_helper() {
  if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
    ok "AUR helper encontrado: paru"
  elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    ok "AUR helper encontrado: yay"
  else
    warn "No se encontró yay ni paru."
    ask "¿Instalar yay desde AUR? [S/n]"
    read -r resp
    if [[ "${resp,,}" != "n" ]]; then
      install_yay
    else
      err "Se necesita un AUR helper para instalar algunos paquetes. Abortando."
      exit 1
    fi
  fi
}

install_yay() {
  step "Instalando yay"
  info "Instalando dependencias de build..."
  sudo pacman -S --needed --noconfirm git base-devel
  local tmpdir
  tmpdir=$(mktemp -d)
  git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
  (cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmpdir"
  AUR_HELPER="yay"
  ok "yay instalado"
}

# ──────────────────── INSTALAR PAQUETES ────────────────────────
pkg_pacman() {
  info "pacman: $*"
  sudo pacman -S --needed --noconfirm "$@"
}

pkg_aur() {
  info "AUR ($AUR_HELPER): $*"
  "$AUR_HELPER" -S --needed --noconfirm "$@"
}

# ──────────────────── COMPONENTES ───────────────────────────────

install_hyprland() {
  step "Hyprland + Ecosistema"
  pkg_pacman \
    hyprland \
    hyprpaper \
    hyprlock \
    hypridle \
    xdg-desktop-portal-hyprland \
    xdg-desktop-portal-gtk \
    qt5-wayland \
    qt6-wayland \
    polkit-gnome \
    grim \
    slurp \
    wl-clipboard \
    brightnessctl \
    playerctl \
    pipewire \
    pipewire-pulse \
    wireplumber \
    gvfs \
    dbus
  ok "Hyprland y ecosistema instalados"
}

install_ags() {
  step "AGS v2 (Aylur's Widget System)"
  # Intentar desde AUR primero
  if "$AUR_HELPER" -Ss "^ags$" &>/dev/null || \
     "$AUR_HELPER" -Ss "^ags-bin$" &>/dev/null; then
    pkg_aur ags-bin || pkg_aur ags
  else
    warn "ags no encontrado en AUR. Instalando dependencias y compilando desde fuente..."
    pkg_pacman nodejs npm gjs gobject-introspection
    pkg_aur \
      astal-io-git \
      astal-hyprland-git \
      astal-mpris-git \
      astal-cava-git \
      astal-tray-git \
      astal-network-git

    local tmpdir
    tmpdir=$(mktemp -d)
    git clone https://github.com/aylur/ags.git "$tmpdir/ags"
    (cd "$tmpdir/ags" && npm install && npm run build)
    install -Dm755 "$tmpdir/ags/dist/ags" "$HOME/.local/bin/ags"
    rm -rf "$tmpdir"
  fi
  ok "AGS instalado"
}

install_astal_libs() {
  step "Librerías Astal (módulos AGS)"
  pkg_aur \
    astal-io-git \
    astal-hyprland-git \
    astal-mpris-git \
    astal-cava-git \
    astal-tray-git \
    astal-network-git \
    astal-battery-git \
    astal-auth-git 2>/dev/null || \
  warn "Algunas librerías Astal no pudieron instalarse. Verifica manualmente."
  ok "Librerías Astal instaladas"
}

install_terminal() {
  step "Terminal: Kitty + Zsh + Starship + plugins"

  pkg_pacman kitty zsh starship bat eza

  # Cambiar shell por defecto a Zsh si no lo es ya
  if [[ "$SHELL" != */zsh ]]; then
    info "Cambiando shell por defecto a Zsh..."
    chsh -s "$(which zsh)"
    ok "Shell cambiado a Zsh (efectivo en el próximo inicio de sesión)"
  else
    ok "Zsh ya es la shell por defecto"
  fi

  # Instalar plugins Zsh
  local ZSH_DIR="$HOME/.zsh"
  mkdir -p "$ZSH_DIR"

  if [[ ! -d "$ZSH_DIR/zsh-autosuggestions" ]]; then
    info "Clonando zsh-autosuggestions..."
    git clone --depth=1 \
      https://github.com/zsh-users/zsh-autosuggestions \
      "$ZSH_DIR/zsh-autosuggestions"
    ok "zsh-autosuggestions instalado"
  else
    ok "zsh-autosuggestions ya existe"
  fi

  if [[ ! -d "$ZSH_DIR/zsh-syntax-highlighting" ]]; then
    info "Clonando zsh-syntax-highlighting..."
    git clone --depth=1 \
      https://github.com/zsh-users/zsh-syntax-highlighting \
      "$ZSH_DIR/zsh-syntax-highlighting"
    ok "zsh-syntax-highlighting instalado"
  else
    ok "zsh-syntax-highlighting ya existe"
  fi

  if [[ ! -d "$ZSH_DIR/zsh-history-substring-search" ]]; then
    info "Clonando zsh-history-substring-search..."
    git clone --depth=1 \
      https://github.com/zsh-users/zsh-history-substring-search \
      "$ZSH_DIR/zsh-history-substring-search"
    ok "zsh-history-substring-search instalado"
  else
    ok "zsh-history-substring-search ya existe"
  fi

  ok "Stack de terminal instalado"
}

install_clipboard() {
  step "Clipboard: cliphist + wl-clipboard"
  pkg_pacman cliphist wl-clipboard
  ok "Gestión de portapapeles instalada"
}

install_cava() {
  step "cava — Visualizador de audio"
  pkg_pacman cava
  ok "cava instalado"
}

install_nerd_fonts() {
  step "Fuentes: JetBrainsMono Nerd Font"

  # Arch tiene el paquete nerd font oficial en extra
  if pkg_pacman ttf-jetbrains-mono-nerd; then
    ok "JetBrainsMono Nerd Font instalada desde repos"
  else
    # Fallback: descarga manual desde nerd-fonts releases
    warn "Instalando desde GitHub releases (fallback)..."
    local FONT_DIR="$HOME/.local/share/fonts/NerdFonts"
    local FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz"
    local TMPFILE
    TMPFILE=$(mktemp --suffix=.tar.xz)

    mkdir -p "$FONT_DIR"
    info "Descargando JetBrainsMono Nerd Font..."
    curl -fL --progress-bar "$FONT_URL" -o "$TMPFILE"
    tar -xJf "$TMPFILE" -C "$FONT_DIR" --wildcards '*.ttf' 2>/dev/null || true
    rm -f "$TMPFILE"
    fc-cache -fv "$FONT_DIR" &>/dev/null
    ok "JetBrainsMono Nerd Font instalada en $FONT_DIR"
  fi

  # Verificar instalación
  if fc-list | grep -qi "JetBrainsMono Nerd"; then
    ok "Fuente verificada: $(fc-list | grep -i 'JetBrainsMono Nerd' | head -1)"
  else
    warn "La fuente puede no estar registrada todavía. Ejecuta: fc-cache -fv"
  fi
}

# ──────────────────── SYMLINKS / BACKUP ─────────────────────────

backup_and_link() {
  step "Aplicando dotfiles"

  local configs=(
    "hypr"
    "ags"
    "kitty"
    "cava"
  )
  local home_files=(
    "starship.toml"
  )

  # Crear directorio de backup
  local any_backup=false
  for cfg in "${configs[@]}"; do
    if [[ -e "$HOME/.config/$cfg" && ! -L "$HOME/.config/$cfg" ]]; then
      any_backup=true
      break
    fi
  done
  if [[ -e "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
    any_backup=true
  fi

  if $any_backup; then
    info "Haciendo backup de configs existentes en: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
  fi

  # Configs de ~/.config/
  for cfg in "${configs[@]}"; do
    local src="$REPO_DIR/$cfg"
    local dst="$HOME/.config/$cfg"
    if [[ ! -d "$src" ]]; then
      warn "No se encontró $src, saltando..."
      continue
    fi
    if [[ -e "$dst" && ! -L "$dst" ]]; then
      mv "$dst" "$BACKUP_DIR/"
      ok "Backup: $dst → $BACKUP_DIR/$cfg"
    elif [[ -L "$dst" ]]; then
      rm "$dst"
    fi
    mkdir -p "$(dirname "$dst")"
    ln -sf "$src" "$dst"
    ok "Symlink: $dst → $src"
  done

  # starship.toml → ~/.config/starship.toml
  local s_src="$REPO_DIR/starship.toml"
  local s_dst="$HOME/.config/starship.toml"
  if [[ -e "$s_dst" && ! -L "$s_dst" ]]; then
    mv "$s_dst" "$BACKUP_DIR/starship.toml"
    ok "Backup: $s_dst → $BACKUP_DIR/starship.toml"
  elif [[ -L "$s_dst" ]]; then
    rm "$s_dst"
  fi
  ln -sf "$s_src" "$s_dst"
  ok "Symlink: $s_dst → $s_src"

  # .zshrc → ~/.zshrc
  local z_src="$REPO_DIR/zsh/.zshrc"
  local z_dst="$HOME/.zshrc"
  if [[ -e "$z_dst" && ! -L "$z_dst" ]]; then
    mv "$z_dst" "$BACKUP_DIR/.zshrc"
    ok "Backup: $z_dst → $BACKUP_DIR/.zshrc"
  elif [[ -L "$z_dst" ]]; then
    rm "$z_dst"
  fi
  ln -sf "$z_src" "$z_dst"
  ok "Symlink: $z_dst → $z_src"

  ok "Dotfiles aplicados. Backup en: $BACKUP_DIR"
}

# ──────────────────── DESINSTALAR ────────────────────────────────
uninstall_rice() {
  step "Desinstalando rice (eliminando symlinks)"

  local links=(
    "$HOME/.config/hypr"
    "$HOME/.config/ags"
    "$HOME/.config/kitty"
    "$HOME/.config/cava"
    "$HOME/.config/starship.toml"
    "$HOME/.zshrc"
  )

  local removed=0
  for link in "${links[@]}"; do
    if [[ -L "$link" ]]; then
      rm "$link"
      ok "Eliminado symlink: $link"
      removed=$((removed + 1))
    else
      info "No es un symlink (saltando): $link"
    fi
  done

  echo ""
  ok "$removed symlinks eliminados."

  # Restaurar backup si existe
  local latest_backup
  latest_backup=$(ls -td "$HOME"/.config-backup-* 2>/dev/null | head -1 || true)
  if [[ -n "$latest_backup" ]]; then
    ask "¿Restaurar backup de $latest_backup? [s/N]"
    read -r resp
    if [[ "${resp,,}" == "s" ]]; then
      for item in "$latest_backup"/*; do
        local name
        name=$(basename "$item")
        local dst
        if [[ "$name" == ".zshrc" ]]; then
          dst="$HOME/.zshrc"
        elif [[ "$name" == "starship.toml" ]]; then
          dst="$HOME/.config/starship.toml"
        else
          dst="$HOME/.config/$name"
        fi
        cp -r "$item" "$dst"
        ok "Restaurado: $dst"
      done
      ok "Backup restaurado desde $latest_backup"
    fi
  fi
}

# ──────────────────── RESUMEN FINAL ─────────────────────────────
print_summary() {
  echo ""
  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${GREEN}║          Instalación completada  ✓              ║${NC}"
  echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${BOLD}Próximos pasos:${NC}"
  echo -e "  ${CYAN}1.${NC} Agrega un wallpaper en: ${YELLOW}~/.config/hypr/wallpaper.jpg${NC}"
  echo -e "  ${CYAN}2.${NC} Agrega tu avatar en: ${YELLOW}~/.face${NC} (para hyprlock)"
  echo -e "  ${CYAN}3.${NC} Reinicia Hyprland o inicia sesión:"
  echo -e "     ${DIM}Hyprland${NC}"
  echo ""
  echo -e "${BOLD}Atajos principales:${NC}"
  echo -e "  ${PURPLE}Super+Return${NC}  → Kitty"
  echo -e "  ${PURPLE}Super+V${NC}       → Portapapeles histórico"
  echo -e "  ${PURPLE}Super+D${NC}       → Launcher"
  echo -e "  ${PURPLE}Print${NC}         → Captura de área"
  echo -e "  ${PURPLE}Super+Escape${NC}  → Bloquear pantalla"
  echo -e "  ${PURPLE}Super+Shift+R${NC} → Recargar AGS"
  echo ""
  echo -e "  ${DIM}Ejecuta ${NC}${YELLOW}cava${NC} en la terminal para el visualizador standalone"
  echo ""
}

# ──────────────────── MENÚ PRINCIPAL ────────────────────────────
show_menu() {
  clear
  echo -e "${BOLD}${PURPLE}"
  echo "   ╦ ╦╦ ╦╔═╗╦═╗╦  ╔═╗╔╗╔╔╦╗  ╦═╗╦╔═╗╔═╗"
  echo "   ╠═╣╚╦╝╠═╝╠╦╝║  ╠═╣║║║ ║║  ╠╦╝║║  ║╣ "
  echo "   ╩ ╩ ╩ ╩  ╩╚═╩═╝╩ ╩╝╚╝═╩╝  ╩╚═╩╚═╝╚═╝"
  echo -e "${NC}"
  echo -e "${DIM}   Tokyo Night · AGS v2 · Kitty · Arch Linux${NC}"
  echo ""
  echo -e "  ${BOLD}Selecciona los componentes a instalar:${NC}"
  echo ""
  echo -e "  ${CYAN}1)${NC} Instalar ${BOLD}todo${NC}                   ${DIM}(recomendado)${NC}"
  echo -e "  ${CYAN}2)${NC} Hyprland + ecosistema"
  echo -e "  ${CYAN}3)${NC} AGS v2 + librerías Astal       ${DIM}(barra animada)${NC}"
  echo -e "  ${CYAN}4)${NC} Terminal                       ${DIM}(Kitty + Zsh + Starship)${NC}"
  echo -e "  ${CYAN}5)${NC} Portapapeles                   ${DIM}(cliphist + wl-clipboard)${NC}"
  echo -e "  ${CYAN}6)${NC} Fuentes Nerd Font              ${DIM}(JetBrainsMono)${NC}"
  echo -e "  ${CYAN}7)${NC} cava                           ${DIM}(visualizador de audio)${NC}"
  echo -e "  ${CYAN}8)${NC} Aplicar dotfiles               ${DIM}(symlinks + backup)${NC}"
  echo -e "  ${CYAN}9)${NC} ${BOLD}Todo${NC} + aplicar dotfiles        ${DIM}(instalación completa)${NC}"
  echo -e "  ${CYAN}0)${NC} Salir"
  echo ""
}

# ──────────────────── PUNTO DE ENTRADA ───────────────────────────
main() {
  # Flag --uninstall
  if [[ "${1:-}" == "--uninstall" || "${1:-}" == "uninstall" ]]; then
    check_arch
    uninstall_rice
    exit 0
  fi

  check_arch
  detect_aur_helper

  while true; do
    show_menu
    ask "Tu elección [0-9]:"
    read -r choice

    case "$choice" in
      1)
        install_hyprland
        install_ags
        install_astal_libs
        install_terminal
        install_clipboard
        install_cava
        install_nerd_fonts
        ;;
      2) install_hyprland ;;
      3) install_ags; install_astal_libs ;;
      4) install_terminal ;;
      5) install_clipboard ;;
      6) install_nerd_fonts ;;
      7) install_cava ;;
      8) backup_and_link ;;
      9)
        install_hyprland
        install_ags
        install_astal_libs
        install_terminal
        install_clipboard
        install_cava
        install_nerd_fonts
        backup_and_link
        print_summary
        exit 0
        ;;
      0) echo -e "\n${DIM}Saliendo...${NC}"; exit 0 ;;
      *) warn "Opción inválida: $choice" ;;
    esac

    echo ""
    ask "¿Volver al menú? [S/n]"
    read -r back
    if [[ "${back,,}" == "n" ]]; then
      break
    fi
  done

  print_summary
}

main "$@"
