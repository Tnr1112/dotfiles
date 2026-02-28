// ╔══════════════════════════════════════════════════════════╗
// ║              SYSTRAY.TSX — Bandeja del sistema           ║
// ╚══════════════════════════════════════════════════════════╝

import Tray from "gi://AstalTray"
import { createBinding } from "astal"
import { Gtk } from "ags/gtk4"

export default function SysTray() {
  const tray = Tray.get_default()
  const items = createBinding(tray, "items")

  return (
    <box cssClasses={["systray"]} spacing={4}>
      {items.as((list) =>
        list.map((item) => {
          const menu = item.create_menu()

          return (
            <button
              cssClasses={["systray-item"]}
              onClicked={(self) => {
                menu?.popup_at_widget(
                  self,
                  Gdk.Gravity.SOUTH,
                  Gdk.Gravity.NORTH,
                  null,
                )
              }}
              tooltip-markup={createBinding(item, "tooltip-markup")}
            >
              <image
                gicon={createBinding(item, "gicon")}
                pixel-size={16}
              />
            </button>
          )
        })
      )}
    </box>
  )
}
