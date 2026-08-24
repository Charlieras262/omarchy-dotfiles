import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "omarchy.workspaces"

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }

    return null
  }

  function workspaceIds() {
    var ids = [1, 2, 3, 4, 5, 6]
    var values = Hyprland.workspaces.values

    for (var i = 0; i < values.length; i++) {
      var id = values[i].id
      if (id > 0 && id <= 10 && ids.indexOf(id) === -1) ids.push(id)
    }

    ids.sort(function(left, right) { return left - right })
    return ids
  }

  function focusWorkspace(id) {
    if (!root.bar) return
    root.bar.run("hyprctl dispatch " + Util.shellQuote("hl.dsp.focus({ workspace = \"" + id + "\" })"))
  }

  // Relative luminance (0-1). Used to pick whichever theme text color
  // actually contrasts against the active indicator, since some themes pair
  // a light indicator with a light foreground (or vice versa).
  function luminance(c) {
    return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
  }

  readonly property color activeIndicatorColor: Color.foreground
  readonly property color activeTextColor: Math.abs(luminance(activeIndicatorColor) - luminance(Color.background))
    > Math.abs(luminance(activeIndicatorColor) - luminance(Color.foreground))
    ? Color.background
    : Color.foreground

  readonly property real trailingGap: root.vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.workspaceIds().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.workspaceIds()

      Item {
        id: cell
        required property int modelData

        readonly property var workspace: root.workspaceById(modelData)
        readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === modelData

        implicitWidth: root.vertical ? root.barSize : Style.space(20)
        implicitHeight: root.barSize

        Rectangle {
          anchors.fill: parent
          anchors.topMargin: 6
          anchors.bottomMargin: 6
          color: cell.focused ? root.activeIndicatorColor : "transparent"
          radius: 6
        }

        WidgetButton {
          anchors.fill: parent
          bar: root.bar
          text: cell.modelData === 10 ? "0" : String(cell.modelData)
          foreground: cell.focused ? root.activeTextColor : Color.foreground
          useActiveColor: false
          opacity: cell.occupied || cell.focused ? 1 : 0.5
          horizontalMargin: 6
          verticalPadding: 6
          onPressed: function() { root.focusWorkspace(cell.modelData) }
        }
      }
    }
  }
}
