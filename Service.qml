import QtQuick
import Quickshell.Io
import Quickshell.Hyprland

Item {
  id: root
  property var shell: null
  property var preview: null
  property string error: ""
  property bool unfocusedSelected: false

  readonly property var saved: {
    var entries = shell && shell.shellConfig ? shell.shellConfig.plugins || [] : []
    for (var i = 0; i < entries.length; i++)
      if (entries[i].id === "goarstne.omartube") return entries[i]
    return ({})
  }
  readonly property int focusedTransparency: preview ? preview.focused : bounded(saved.focusedTransparency, 10)
  readonly property int unfocusedTransparency: preview ? preview.unfocused : bounded(saved.unfocusedTransparency, 15)

  function bounded(value, fallback) {
    return typeof value === "number" && isFinite(value) ? Math.max(0, Math.min(90, Math.round(value))) : fallback
  }

  function setTransparency(focused, unfocused, persist) {
    preview = { focused: bounded(focused, 10), unfocused: bounded(unfocused, 15) }
    if (!persist || !shell) return
    var next = preview
    shell.mutateShellConfig(function(config) {
      var entries = config.plugins || []
      var entry = entries.find(function(item) { return item.id === "goarstne.omartube" })
      if (!entry) { entry = { id: "goarstne.omartube" }; entries.push(entry) }
      entry.focusedTransparency = next.focused
      entry.unfocusedTransparency = next.unfocused
      config.plugins = entries
    })
  }

  onSavedChanged: { preview = null; applyTimer.restart() }
  onFocusedTransparencyChanged: applyTimer.restart()
  onUnfocusedTransparencyChanged: applyTimer.restart()
  onShellChanged: applyTimer.restart()

  Timer {
    id: applyTimer
    interval: 60
    onTriggered: {
      if (!root.shell) return
      if (applyProcess.running) { restart(); return }
      applyProcess.command = ["/usr/bin/hyprctl", "eval", "omartube_set_transparency(" + root.focusedTransparency + "," + root.unfocusedTransparency + ")"]
      applyProcess.running = true
    }
  }

  Process {
    id: applyProcess
    environment: ({ PATH: "/usr/bin:/bin" })
    stdout: StdioCollector {
      onStreamFinished: root.error = text.trim() === "ok" ? "" : "Unable to apply transparency. Check the OmarTube window rules."
    }
    onExited: function(code) { if (code !== 0) root.error = "Unable to reach Hyprland." }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) { if (event.name === "configreloaded") applyTimer.restart() }
  }

  IpcHandler {
    target: "goarstne.omartube"
    function setTransparency(focused: int, unfocused: int): void { root.setTransparency(focused, unfocused, true) }
    function status(): string {
      return JSON.stringify({ focused: root.focusedTransparency, unfocused: root.unfocusedTransparency, error: root.error })
    }
  }
}
