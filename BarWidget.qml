import QtQuick
import qs.Ui as Ui

Ui.BarWidget {
  id: root
  moduleName: "goarstne.omartube"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Ui.WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰗃"
    tooltipText: "OmarTube · transparency"
    onPressed: if (root.bar) root.bar.run("/usr/share/omarchy/bin/omarchy-shell shell toggle goarstne.omartube '{}'")
  }
}
