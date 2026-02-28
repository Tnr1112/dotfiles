#!/usr/bin/env -S ags run
// ╔══════════════════════════════════════════════════════════╗
// ║            AGS v2 — Punto de entrada principal           ║
// ║         Barra + Popup Clipboard — Tokyo Night            ║
// ╚══════════════════════════════════════════════════════════╝

import app from "ags/gtk4/app"
import Bar from "./widgets/Bar"
import ClipboardPopup from "./widgets/ClipboardPopup"

// Cargar hoja de estilos globales
app.start({
  css: `${SRC}/style/main.css`,
  main() {
    // Obtener todos los monitores y crear una barra por monitor
    const monitors = app.get_monitors()
    monitors.forEach((monitor, index) => {
      Bar(monitor, index)
    })

    // Popup de clipboard (global, una instancia)
    ClipboardPopup()
  },
})
