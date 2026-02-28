// ╔══════════════════════════════════════════════════════════╗
// ║                  BAR.TSX — Barra principal               ║
// ╚══════════════════════════════════════════════════════════╝

import { Astal, Gdk } from "ags/gtk4"
import app from "ags/gtk4/app"
import Workspaces from "./Workspaces"
import Clock from "./Clock"
import MusicPlayer from "./MusicPlayer"
import CavaVisualizer from "./CavaVisualizer"
import SysTray from "./SysTray"
import { config } from "../config"

export default function Bar(monitor: Gdk.Monitor, index: number) {
  return (
    <window
      name={`bar-${index}`}
      application={app}
      gdkmonitor={monitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      layer={Astal.Layer.TOP}
      anchor={
        Astal.WindowAnchor.TOP |
        Astal.WindowAnchor.LEFT |
        Astal.WindowAnchor.RIGHT
      }
      marginTop={config.barMargin}
      marginLeft={config.barMargin}
      marginRight={config.barMargin}
      cssClasses={["bar"]}
    >
      <centerbox cssClasses={["bar-inner"]}>
        {/* Lado izquierdo: workspaces */}
        <box
          slot="start"
          cssClasses={["bar-left"]}
          spacing={6}
          hexpand={false}
        >
          <Workspaces />
        </box>

        {/* Centro: música + visualizador */}
        <box
          slot="center"
          cssClasses={["bar-center"]}
          spacing={8}
          hexpand={false}
        >
          <CavaVisualizer />
          <MusicPlayer />
        </box>

        {/* Lado derecho: systray + reloj */}
        <box
          slot="end"
          cssClasses={["bar-right"]}
          spacing={8}
          hexpand={false}
          halign={3 /* Gtk.Align.END */}
        >
          <SysTray />
          <Clock />
        </box>
      </centerbox>
    </window>
  )
}
