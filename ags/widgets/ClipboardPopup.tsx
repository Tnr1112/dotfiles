// ╔══════════════════════════════════════════════════════════╗
// ║  CLIPBOARDPOPUP.TSX — Historial de portapapeles          ║
// ║  Super+V → overlay centrado con búsqueda en tiempo real  ║
// ║  • cliphist list/decode/delete/wipe                      ║
// ║  • Animaciones: slide-in, slide-out-right, toast, flash  ║
// ╚══════════════════════════════════════════════════════════╝

import { Astal, Gtk } from "ags/gtk4"
import app from "ags/gtk4/app"
import { createState } from "astal"
import GLib from "gi://GLib"
import Gio from "gi://Gio"

// ─── Helpers para ejecutar comandos y capturar stdout ────────
function exec(cmd: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const proc = Gio.Subprocess.new(
      ["/bin/sh", "-c", cmd],
      Gio.SubprocessFlags.STDOUT_PIPE | Gio.SubprocessFlags.STDERR_PIPE
    )
    proc.communicate_utf8_async(null, null, (_, res) => {
      try {
        const [, stdout] = proc.communicate_utf8_finish(res)
        resolve(stdout?.trim() ?? "")
      } catch (e) {
        reject(e)
      }
    })
  })
}

function execSync(cmd: string): string {
  try {
    const [, out] = GLib.spawn_command_line_sync(cmd)
    return new TextDecoder().decode(out ?? new Uint8Array()).trim()
  } catch {
    return ""
  }
}

// ─── Tipos ───────────────────────────────────────────────────
interface ClipEntry {
  id: string
  preview: string
  isBinary: boolean
}

function parseCliphistList(raw: string): ClipEntry[] {
  return raw
    .split("\n")
    .filter(Boolean)
    .slice(0, 50)
    .map((line) => {
      const tabIdx = line.indexOf("\t")
      const id = line.slice(0, tabIdx)
      const preview = line.slice(tabIdx + 1).trim()
      const isBinary = preview.startsWith("[[ binary")
      return { id, preview, isBinary }
    })
}

// ─── Elemento individual de la lista ─────────────────────────
function ClipItem({
  entry,
  onCopy,
  onDelete,
}: {
  entry: ClipEntry
  onCopy: (entry: ClipEntry) => void
  onDelete: (entry: ClipEntry) => void
}) {
  const [removing, setRemoving] = createState(false)

  return (
    <revealer
      reveal-child={removing.as((r) => !r)}
      transition-type={Gtk.RevealerTransitionType.SLIDE_UP}
      transition-duration={200}
    >
      <button
        cssClasses={["clip-item"]}
        onClicked={() => onCopy(entry)}
        tooltip-text="Click para copiar"
      >
        <box spacing={8}>
          {/* Ícono */}
          <label
            cssClasses={["clip-icon"]}
            label={entry.isBinary ? "󰋩" : "󰆒"}
          />

          {/* Preview */}
          <label
            cssClasses={["clip-preview"]}
            label={entry.preview.slice(0, 60) + (entry.preview.length > 60 ? "…" : "")}
            hexpand
            xalign={0}
            ellipsize={3}
            max-width-chars={55}
          />

          {/* Botón eliminar */}
          <button
            cssClasses={["clip-delete-btn"]}
            tooltip-text="Eliminar"
            onClicked={(self) => {
              self.get_ancestor(Gtk.Window)  // evitar propagación
              setRemoving(true)
              setTimeout(() => onDelete(entry), 210)
            }}
          >
            <label label="󰅖" />
          </button>
        </box>
      </button>
    </revealer>
  )
}

// ─── Toast de confirmación ───────────────────────────────────
function Toast({ message, visible }: { message: string; visible: boolean }) {
  return (
    <revealer
      reveal-child={visible}
      transition-type={Gtk.RevealerTransitionType.CROSSFADE}
      transition-duration={250}
    >
      <label cssClasses={["clip-toast"]} label={message} />
    </revealer>
  )
}

// ─── Popup principal ─────────────────────────────────────────
export default function ClipboardPopup() {
  const [entries, setEntries]       = createState<ClipEntry[]>([])
  const [query, setQuery]           = createState("")
  const [toast, setToast]           = createState("")
  const [toastVisible, setToastV]   = createState(false)
  const [confirmWipe, setConfirmW]  = createState(false)

  async function loadEntries() {
    const raw = await exec("cliphist list")
    setEntries(parseCliphistList(raw))
  }

  function showToast(msg: string) {
    setToast(msg)
    setToastV(true)
    setTimeout(() => setToastV(false), 2000)
  }

  async function handleCopy(entry: ClipEntry) {
    await exec(`echo "${entry.id}\t${entry.preview}" | cliphist decode | wl-copy`)
    showToast("  Copiado al portapapeles")
    // Cerrar el popup tras copiar
    const win = app.get_window("clipboard-popup")
    if (win) win.visible = false
  }

  async function handleDelete(entry: ClipEntry) {
    await exec(`echo "${entry.id}\t${entry.preview}" | cliphist delete`)
    setEntries(entries.get().filter((e) => e.id !== entry.id))
    showToast("  Entrada eliminada")
  }

  async function handleWipe() {
    if (!confirmWipe.get()) {
      setConfirmW(true)
      setTimeout(() => setConfirmW(false), 3000)
      return
    }
    await exec("cliphist wipe")
    setEntries([])
    setConfirmW(false)
    showToast("  Historial limpiado")
  }

  // Filtrado en tiempo real
  const filtered = query.as((q) => {
    const q2 = q.toLowerCase()
    return entries.get().filter(
      (e) => !q2 || e.preview.toLowerCase().includes(q2)
    )
  })

  return (
    <window
      name="clipboard-popup"
      application={app}
      visible={false}
      layer={Astal.Layer.OVERLAY}
      exclusivity={Astal.Exclusivity.NORMAL}
      keymode={Astal.Keymode.ON_DEMAND}
      cssClasses={["clipboard-popup"]}
      onShow={() => {
        loadEntries()
        setQuery("")
        setConfirmW(false)
      }}
      onKeyPressEvent={(self, event) => {
        // ESC cierra el popup
        const key = event.get_keyval()[1]
        if (key === 0xff1b) self.visible = false
      }}
    >
      <box vertical cssClasses={["clipboard-inner"]} spacing={8}>

        {/* ── Header ── */}
        <box cssClasses={["clipboard-header"]} spacing={8}>
          <label cssClasses={["clipboard-title"]} label="󰆒  Portapapeles" hexpand xalign={0} />

          {/* Botón limpiar todo */}
          <button
            cssClasses={confirmWipe.as((c) =>
              c ? ["clip-wipe-btn", "confirming"] : ["clip-wipe-btn"]
            )}
            tooltip-text={confirmWipe.as((c) =>
              c ? "¿Confirmar? Click de nuevo" : "Limpiar historial"
            )}
            onClicked={handleWipe}
          >
            <label label={confirmWipe.as((c) => (c ? "󰗩 ¿Seguro?" : "󰃢"))} />
          </button>
        </box>

        {/* ── Toast ── */}
        <Toast message={toast} visible={toastVisible.get()} />

        {/* ── Barra de búsqueda ── */}
        <entry
          cssClasses={["clipboard-search"]}
          placeholder-text="  Buscar..."
          text={query}
          onChanged={(self) => setQuery(self.text)}
        />

        {/* ── Lista ── */}
        <scrolledwindow
          cssClasses={["clipboard-scroll"]}
          vexpand
          hscrollbar-policy={Gtk.PolicyType.NEVER}
          vscrollbar-policy={Gtk.PolicyType.AUTOMATIC}
        >
          <box vertical cssClasses={["clipboard-list"]} spacing={2}>
            {filtered.as((list) => {
              if (list.length === 0) {
                return (
                  <label
                    cssClasses={["clipboard-empty"]}
                    label="Sin entradas"
                    halign={3 /* CENTER */}
                  />
                )
              }
              return list.map((entry) => (
                <ClipItem
                  entry={entry}
                  onCopy={handleCopy}
                  onDelete={handleDelete}
                />
              ))
            })}
          </box>
        </scrolledwindow>

        {/* ── Footer ── */}
        <box cssClasses={["clipboard-footer"]} spacing={4}>
          <label
            cssClasses={["clipboard-hint"]}
            label={entries.as((e) => `${e.length} entradas  ·  Super+V para cerrar  ·  ESC para cerrar`)}
          />
        </box>
      </box>
    </window>
  )
}
