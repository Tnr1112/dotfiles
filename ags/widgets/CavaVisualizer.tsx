// ╔══════════════════════════════════════════════════════════╗
// ║       CAVAVISUALIZER.TSX — Visualizador en barra         ║
// ║  • Barras reactivas a AstalCava (Float32Array)           ║
// ║  • Gradiente de color Tokyo Night graves→agudos          ║
// ║  • Solo visible cuando hay música reproduciéndose        ║
// ╚══════════════════════════════════════════════════════════╝

import Cava from "gi://AstalCava"
import Mpris from "gi://AstalMpris"
import { createBinding } from "astal"
import { Gtk } from "ags/gtk4"

// Paleta de colores para el gradiente (graves a agudos)
const GRADIENT = [
  "#7aa2f7", // blue    — graves
  "#7dcfff", // sky
  "#bb9af7", // purple
  "#2ac3de", // cyan
  "#73daca", // teal
  "#9ece6a", // green
  "#e0af68", // yellow
  "#f7768e", // red     — agudos
] as const

const BAR_COUNT = 20

/** Interpola un color del gradiente según posición 0..1 */
function pickColor(t: number): string {
  const idx = Math.min(
    Math.floor(t * (GRADIENT.length - 1)),
    GRADIENT.length - 2
  )
  return GRADIENT[idx]
}

export default function CavaVisualizer() {
  const cava  = Cava.get_default()
  const mpris = Mpris.get_default()

  const values   = createBinding(cava, "values")
  const players  = createBinding(mpris, "players")

  const isPlaying = players.as((list) =>
    list.some((p) => p.playback_status === Mpris.PlaybackStatus.PLAYING)
  )

  return (
    <revealer
      reveal-child={isPlaying}
      transition-type={Gtk.RevealerTransitionType.SLIDE_LEFT}
      transition-duration={400}
    >
      <box cssClasses={["cava-container"]} spacing={1}>
        {Array.from({ length: BAR_COUNT }, (_, i) => {
          const t = i / (BAR_COUNT - 1)
          const color = pickColor(t)

          const heightPx = values.as((vals: Float32Array | null) => {
            if (!vals || vals.length === 0) return 2
            // Mapear índice de barra al índice del array de cava
            const idx = Math.floor((i / BAR_COUNT) * vals.length)
            const v = Math.max(0, Math.min(1, vals[idx] ?? 0))
            return Math.max(2, Math.round(v * 28))
          })

          return (
            <box
              cssClasses={["cava-bar"]}
              vertical
              valign={4 /* Gtk.Align.END */}
              css={heightPx.as(
                (h) =>
                  `min-height: ${h}px; background-color: ${color}; border-radius: 2px 2px 0 0;`
              )}
            />
          )
        })}
      </box>
    </revealer>
  )
}
