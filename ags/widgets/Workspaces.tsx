// ╔══════════════════════════════════════════════════════════╗
// ║           WORKSPACES.TSX — Indicadores animados          ║
// ╚══════════════════════════════════════════════════════════╝

import Hyprland from "gi://AstalHyprland"
import { createBinding } from "astal"
import { config } from "../config"

export default function Workspaces() {
  const hypr = Hyprland.get_default()

  const focusedWs = createBinding(hypr, "focused-workspace")
  const workspaces = createBinding(hypr, "workspaces")

  // Genera array de IDs 1..N garantizando que existan siempre los primeros slots
  const wsIds = Array.from({ length: config.workspaces }, (_, i) => i + 1)

  return (
    <box cssClasses={["workspaces"]} spacing={4}>
      {wsIds.map((id) => {
        const isActive = focusedWs.as((ws) => ws?.id === id)
        const hasWindows = workspaces.as((list) => {
          const found = list.find((w) => w.id === id)
          return (found?.get_clients()?.length ?? 0) > 0
        })

        return (
          <button
            cssClasses={isActive.as((active) => {
              const classes = ["workspace-btn"]
              if (active) classes.push("active")
              if (hasWindows.get()) classes.push("occupied")
              return classes
            })}
            onClicked={() => hypr.dispatch("workspace", String(id))}
            tooltip-text={`Workspace ${id}`}
          >
            <label
              label={isActive.as((active) => (active ? "󰮯" : hasWindows.get() ? "󰊠" : "󰊡"))}
              cssClasses={["workspace-icon"]}
            />
          </button>
        )
      })}
    </box>
  )
}
