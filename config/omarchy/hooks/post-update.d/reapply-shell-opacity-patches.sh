#!/bin/bash
# Reapplies the manual system-file patches documented in omarchy-omablur's
# "Making blur actually visible" and omarchy-floating-bar's "Known
# limitation" README sections. Omarchy updates overwrite these shell files
# from scratch, silently dropping the edits -- this hook reapplies them
# after every `omarchy update` so the floating bar, notifications, menu,
# and keyboard panel stay translucent instead of turning solid again.

sudo python3 - <<'PYEOF'
patches = [
    (
        "/usr/share/omarchy/shell/Commons/Style.qml",
        "  property int gapsOut: 5\n",
        "  property int gapsOut: 5\n  property real shellOpacity: 1\n",
    ),
    (
        "/usr/share/omarchy/shell/Ui/KeyboardPanel.qml",
        "    color: Color.popups.background\n",
        "    color: Qt.rgba(Color.popups.background.r, Color.popups.background.g, Color.popups.background.b, 1)\n",
    ),
    (
        "/usr/share/omarchy/shell/Ui/KeyboardPanel.qml",
        "    opacity: root.open || root.popoutSwitching ? 1.0 : 0\n",
        "    opacity: (root.open || root.popoutSwitching ? 1.0 : 0) * Style.shellOpacity\n",
    ),
    (
        "/usr/share/omarchy/shell/Ui/KeyboardPanel.qml",
        "  property int gap: Style.gapsOut  // distance between bar edge and panel\n",
        "  readonly property real barEdgeMargin: bar && bar.floatGap !== undefined\n"
        "    ? Math.max(0, Number(bar.floatGap) || 0) : 0\n"
        "  property int gap: Style.gapsOut + barEdgeMargin  // distance between bar edge and panel\n",
    ),
    (
        "/usr/share/omarchy/shell/plugins/notifications/components/NotificationCard.qml",
        "  color: Color.notifications.background\n",
        "  color: Qt.rgba(Color.notifications.background.r, Color.notifications.background.g, Color.notifications.background.b, 1)\n"
        "  opacity: Style.shellOpacity\n",
    ),
    (
        "/usr/share/omarchy/shell/plugins/menu/Menu.qml",
        "      color: root.background\n",
        "      color: Qt.rgba(root.background.r, root.background.g, root.background.b, 1)\n"
        "      opacity: Style.shellOpacity\n",
    ),
    (
        "/usr/share/omarchy/shell/plugins/notifications/Service.qml",
        "  readonly property int barClearance: liveBarSize + Style.gapsOut\n",
        "  readonly property real barEdgeMargin: shell && shell.bar && shell.bar.barHidden !== undefined\n"
        "    && shell.bar.floatGap !== undefined ? Math.max(0, Number(shell.bar.floatGap) || 0) : 0\n"
        "  readonly property int barClearance: liveBarSize + barEdgeMargin + Style.gapsOut\n",
    ),
]

changed = 0
for path, old, new in patches:
    with open(path, "r") as f:
        content = f.read()
    if new in content:
        continue
    if old not in content:
        print(f"WARNING: expected text not found in {path} -- Omarchy's file layout changed; reapply by hand from the omarchy-omablur/omarchy-floating-bar READMEs")
        continue
    content = content.replace(old, new, 1)
    with open(path, "w") as f:
        f.write(content)
    print(f"patched: {path}")
    changed += 1

print(f"reapply-shell-opacity-patches: {changed} file(s) patched" if changed else "reapply-shell-opacity-patches: already up to date")
PYEOF

omarchy restart shell
