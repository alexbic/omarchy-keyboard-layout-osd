import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import qs.Commons
import qs.Ui

Item {
  id: root

  property bool showing: false
  property string layout: ""
  property string keyboardName: ""
  property int displayMs: 1100

  function labelFor(value) {
    var text = String(value || "")
    var lower = text.toLowerCase()
    if (lower.indexOf("spanish") !== -1 || lower === "es") return "ES"
    if (lower.indexOf("english") !== -1 || lower === "en" || lower === "us") return "EN"
    if (lower.indexOf("russian") !== -1 || lower === "ru") return "RU"
    return text.substring(0, 3).toUpperCase()
  }

  function showLayout(value, name) {
    var next = labelFor(value)
    if (!next) return
    root.layout = next
    root.keyboardName = String(name || "")
    root.showing = true
    hideTimer.restart()
  }

  function eventParts(event) {
    try {
      if (event && event.parse) return event.parse(2)
    } catch (error) {}
    return String(event && event.data ? event.data : "").split(",")
  }

  // Also provides a harmless manual test path: omarchy-shell wiz.keyboard-osd test RU
  IpcHandler {
    target: "wiz.keyboard-osd"
    function test(value: string): string {
      root.showLayout(value, "manual-test")
      return "ok"
    }
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (!event || String(event.name || "") !== "activelayout") return
      var parts = eventParts(event)
      // Hyprland's event is: keyboard-name, active-keymap description.
      // Fcitx5, Waynergy and system buttons use virtual/non-typing keyboards
      // and may announce layout activity while inserting pasted/voice text.
      // Only a real typing keyboard is allowed to open this OSD.
      var keyboard = String(parts[0] || "")
      if (/^(hl-virtual-keyboard|power-button|sleep-button|lid-switch|video-bus)/.test(keyboard)) return
      showLayout(parts[1], keyboard)
    }
  }

  Timer {
    id: hideTimer
    interval: root.displayMs
    onTriggered: root.showing = false
  }

  PanelWindow {
    id: panel
    visible: root.showing
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "wiz-keyboard-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    BorderSurface {
      id: card
      width: Style.space(170)
      height: Style.space(130)
      anchors.centerIn: parent
      color: Util.alpha(Color.background, 0.86)
      borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(2)))
      radius: Style.cornerRadius
      opacity: root.showing ? 1 : 0
      scale: root.showing ? 1 : 0.94

      Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
      }
      Behavior on scale {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
      }

      Column {
        anchors.centerIn: parent
        spacing: Style.space(5)

        Text {
          width: card.width
          text: root.layout
          textFormat: Text.PlainText
          horizontalAlignment: Text.AlignHCenter
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.displayLarge + Style.space(8)
          font.bold: true
        }
      }
    }
  }
}
