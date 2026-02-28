// ╔══════════════════════════════════════════════════════════╗
// ║                CLOCK.TSX — Reloj con flip                ║
// ╚══════════════════════════════════════════════════════════╝

import { createPoll, createState } from "astal"

export default function Clock() {
  // Actualiza cada segundo
  const time = createPoll("", 1000, () => {
    const d = new Date()
    const hh = String(d.getHours()).padStart(2, "0")
    const mm = String(d.getMinutes()).padStart(2, "0")
    const ss = String(d.getSeconds()).padStart(2, "0")
    return `${hh}:${mm}:${ss}`
  })

  const date = createPoll("", 60000, () => {
    return new Date().toLocaleDateString("es-ES", {
      weekday: "short",
      day: "2-digit",
      month: "short",
    })
  })

  // Tracking del minuto anterior para disparar animación de flip
  const [flipping, setFlipping] = createState(false)
  let lastMinute = -1

  const timeWithFlip = createPoll("", 1000, () => {
    const d = new Date()
    const currentMinute = d.getMinutes()
    if (currentMinute !== lastMinute) {
      lastMinute = currentMinute
      setFlipping(true)
      setTimeout(() => setFlipping(false), 400)
    }
    const hh = String(d.getHours()).padStart(2, "0")
    const mm = String(currentMinute).padStart(2, "0")
    const ss = String(d.getSeconds()).padStart(2, "0")
    return `${hh}:${mm}:${ss}`
  })

  return (
    <box cssClasses={["clock-widget"]} spacing={4} vertical={false}>
      {/* Fecha */}
      <label
        cssClasses={["clock-date"]}
        label={date}
      />
      {/* Separador visual */}
      <label cssClasses={["clock-sep"]} label="│" />
      {/* Hora con animación flip en cambio de minuto */}
      <label
        cssClasses={flipping.as((f) => f ? ["clock-time", "flip"] : ["clock-time"])}
        label={timeWithFlip}
      />
    </box>
  )
}
