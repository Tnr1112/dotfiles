// ╔══════════════════════════════════════════════════════════╗
// ║          MUSICPLAYER.TSX — Widget MPRIS animado          ║
// ║  • Album art giratorio cuando reproduce                  ║
// ║  • Marquee para títulos largos                           ║
// ║  • Borde pulso al ritmo del estado de reproducción      ║
// ║  • Slide-in al aparecer, slide-out al desaparecer        ║
// ╚══════════════════════════════════════════════════════════╝

import Mpris from "gi://AstalMpris"
import { createBinding, createState } from "astal"
import { Gtk } from "ags/gtk4"

function PlayerWidget({ player }: { player: Mpris.Player }) {
  const isPlaying = createBinding(player, "playback-status").as(
    (s) => s === Mpris.PlaybackStatus.PLAYING
  )
  const title  = createBinding(player, "title")
  const artist = createBinding(player, "artist")
  const cover  = createBinding(player, "cover-art")

  // Clases CSS dinámicas — activan animaciones
  const artClasses = isPlaying.as((p) =>
    p ? ["music-cover", "spinning"] : ["music-cover"]
  )
  const widgetClasses = isPlaying.as((p) =>
    p ? ["music-player", "is-playing"] : ["music-player"]
  )
  const titleClasses = title.as((t) =>
    t && t.length > 25 ? ["music-title", "marquee"] : ["music-title"]
  )

  return (
    <revealer
      reveal-child={isPlaying}
      transition-type={Gtk.RevealerTransitionType.SLIDE_RIGHT}
      transition-duration={350}
    >
      <box cssClasses={widgetClasses} spacing={8}>
        {/* Album art con rotación */}
        <box cssClasses={["music-cover-wrapper"]}>
          <image
            cssClasses={artClasses}
            file={cover.as((c) => c ?? "")}
            pixel-size={28}
            visible={cover.as((c) => !!c)}
          />
          {/* Ícono fallback cuando no hay cover */}
          <label
            cssClasses={["music-cover-fallback"]}
            label="󰎈"
            visible={cover.as((c) => !c)}
          />
        </box>

        {/* Info de la pista */}
        <box vertical cssClasses={["music-info"]} spacing={1}>
          <label
            cssClasses={titleClasses}
            label={title.as((t) => t ?? "Sin título")}
            max-width-chars={28}
            ellipsize={3 /* Pango.EllipsizeMode.END */}
            xalign={0}
          />
          <label
            cssClasses={["music-artist"]}
            label={artist.as((a) => a ?? "")}
            max-width-chars={22}
            ellipsize={3}
            xalign={0}
            visible={artist.as((a) => !!a)}
          />
        </box>

        {/* Controles */}
        <box cssClasses={["music-controls"]} spacing={2}>
          <button
            cssClasses={["music-btn"]}
            onClicked={() => player.previous()}
            tooltip-text="Anterior"
          >
            <label label="󰒮" />
          </button>

          <button
            cssClasses={["music-btn", "music-btn-play"]}
            onClicked={() => player.play_pause()}
            tooltip-text={isPlaying.as((p) => (p ? "Pausar" : "Reproducir"))}
          >
            <label label={isPlaying.as((p) => (p ? "󰏤" : "󰐊"))} />
          </button>

          <button
            cssClasses={["music-btn"]}
            onClicked={() => player.next()}
            tooltip-text="Siguiente"
          >
            <label label="󰒭" />
          </button>
        </box>
      </box>
    </revealer>
  )
}

export default function MusicPlayer() {
  const mpris = Mpris.get_default()
  const players = createBinding(mpris, "players")

  return (
    <box cssClasses={["music-container"]} spacing={4}>
      {players.as((list) => {
        if (list.length === 0) {
          return (
            <box cssClasses={["music-empty"]} spacing={4}>
              <label cssClasses={["music-empty-icon"]} label="󰎊" />
            </box>
          )
        }
        // Mostrar solo el primer player activo
        const active = list.find(
          (p) => p.playback_status === Mpris.PlaybackStatus.PLAYING
        ) ?? list[0]
        return <PlayerWidget player={active} />
      })}
    </box>
  )
}
