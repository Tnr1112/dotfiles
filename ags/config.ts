// ╔══════════════════════════════════════════════════════════╗
// ║          AGS CONFIG — Tokyo Night Color Palette          ║
// ╚══════════════════════════════════════════════════════════╝

export const colors = {
  bg:           "#1a1b26",
  bgDark:       "#16161e",
  bgDarker:     "#13131a",
  bgHighlight:  "#292e42",
  fg:           "#a9b1d6",
  fgBright:     "#c0caf5",
  fgDark:       "#787c99",
  comment:      "#565f89",

  blue:         "#7aa2f7",
  blueLight:    "#7dcfff",
  purple:       "#bb9af7",
  purpleDark:   "#9d7cd8",
  cyan:         "#2ac3de",
  teal:         "#73daca",
  green:        "#9ece6a",
  yellow:       "#e0af68",
  orange:       "#ff9e64",
  red:          "#f7768e",
  redDark:      "#db4b4b",

  border:       "#101014",
  accent:       "#3d59a1",
} as const

// ── Colores de la barra de cava (gradiente graves → agudos) ──
export const cavaGradient = [
  colors.blue,
  colors.blueLight,
  colors.purple,
  colors.cyan,
  colors.teal,
  colors.green,
  colors.yellow,
  colors.red,
] as const

// ── Configuración general ────────────────────────────────────
export const config = {
  barHeight:        36,
  barMargin:        6,
  borderRadius:     12,
  transition:       "300ms cubic-bezier(0.34, 1.56, 0.64, 1)",
  transitionFast:   "150ms ease-out",
  transitionSlow:   "500ms ease-in-out",

  // Clipboard
  clipboardMaxItems: 50,
  clipboardPreviewLength: 60,

  // Música — nombre del proceso del reproductor MPRIS (vacío = cualquiera)
  musicPlayer: "",

  // Cava
  cavaBars: 20,

  workspaces: 9,
} as const
