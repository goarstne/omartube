import QtQuick
import Quickshell
import qs.Ui
import qs.Commons

Item {
  id: root
  property var shell: null
  property var service: null
  property bool closingFromHost: false

  function open(payloadJson) {
    window.visible = true
    Qt.callLater(function() { (root.service && root.service.unfocusedSelected ? unfocusedSlider : focusedSlider).forceActiveFocus() })
  }
  function close() { closingFromHost = true; window.visible = false; closingFromHost = false }
  function requestClose() { if (shell) shell.hide("goarstne.omartube"); else window.visible = false }

  FloatingWindow {
    id: window
    title: "OmarTube controls"
    visible: false
    color: Color.background
    implicitWidth: 440
    implicitHeight: content.implicitHeight + 48
    minimumSize: Qt.size(360, content.implicitHeight + 48)
    onVisibleChanged: if (!visible && !root.closingFromHost) root.requestClose()

    FocusScope {
      anchors.fill: parent
      focus: true
      Keys.onEscapePressed: root.requestClose()

      Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 24
        spacing: Style.spacing.md

        Text {
          text: "OmarTube"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.iconLarge
          font.bold: true
        }
        Text {
          text: "Transparency · focused: " + (root.service ? root.service.focusedTransparency : 10) + "%"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }
        PanelSlider {
          id: focusedSlider
          width: parent.width
          minimum: 0; maximum: 90; step: 5; integer: true
          value: root.service ? root.service.focusedTransparency : 10
          enabled: !!root.service
          activeFocusOnTab: true
          onActiveFocusChanged: if (activeFocus && root.service) root.service.unfocusedSelected = false
          Accessible.role: Accessible.Slider
          Accessible.name: "Focused window transparency"
          Accessible.description: value + " percent"
          Keys.onLeftPressed: root.service.setTransparency(value - 5, root.service.unfocusedTransparency, true)
          Keys.onRightPressed: root.service.setTransparency(value + 5, root.service.unfocusedTransparency, true)
          Keys.onTabPressed: unfocusedSlider.forceActiveFocus()
          onMoved: function(v) { root.service.setTransparency(v, root.service.unfocusedTransparency, false) }
          onReleased: function(v) { root.service.setTransparency(v, root.service.unfocusedTransparency, true) }
          Rectangle { anchors.fill: parent; color: "transparent"; border.color: Color.accent; radius: 4; visible: focusedSlider.activeFocus }
        }
        Text {
          text: "Transparency · unfocused: " + (root.service ? root.service.unfocusedTransparency : 15) + "%"
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }
        PanelSlider {
          id: unfocusedSlider
          width: parent.width
          minimum: 0; maximum: 90; step: 5; integer: true
          value: root.service ? root.service.unfocusedTransparency : 15
          enabled: !!root.service
          activeFocusOnTab: true
          onActiveFocusChanged: if (activeFocus && root.service) root.service.unfocusedSelected = true
          Accessible.role: Accessible.Slider
          Accessible.name: "Unfocused window transparency"
          Accessible.description: value + " percent"
          Keys.onLeftPressed: root.service.setTransparency(root.service.focusedTransparency, value - 5, true)
          Keys.onRightPressed: root.service.setTransparency(root.service.focusedTransparency, value + 5, true)
          Keys.onBacktabPressed: focusedSlider.forceActiveFocus()
          onMoved: function(v) { root.service.setTransparency(root.service.focusedTransparency, v, false) }
          onReleased: function(v) { root.service.setTransparency(root.service.focusedTransparency, v, true) }
          Rectangle { anchors.fill: parent; color: "transparent"; border.color: Color.accent; radius: 4; visible: unfocusedSlider.activeFocus }
        }
        Text {
          width: parent.width
          text: "Press F in YouTube to fill the window with video.\nResize with Super + right-drag.\n0% transparency is fully opaque."
          wrapMode: Text.WordWrap
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
        Text {
          width: parent.width
          visible: text !== ""
          text: root.service ? root.service.error : ""
          wrapMode: Text.WordWrap
          color: Color.urgent
          font.family: Style.font.family
          font.pixelSize: Style.font.bodySmall
        }
        Row {
          spacing: Style.spacing.md
          Button { text: "Reset"; focusable: true; enabled: !!root.service; onClicked: root.service.setTransparency(10, 15, true) }
          Button { text: "Close"; focusable: true; onClicked: root.requestClose() }
        }
      }
    }
  }
}
