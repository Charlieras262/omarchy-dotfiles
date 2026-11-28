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
        "    color: Commons.Color.popups.background\n",
        "    color: Qt.rgba(Commons.Color.popups.background.r, Commons.Color.popups.background.g, Commons.Color.popups.background.b, 1)\n",
    ),
    (
        "/usr/share/omarchy/shell/Ui/KeyboardPanel.qml",
        "    opacity: shown\n",
        "    opacity: shown * Style.shellOpacity\n",
    ),
    (
        "/usr/share/omarchy/shell/Ui/KeyboardPanel.qml",
        "  property int gap: Style.gapsOut  // distance between bar edge and panel\n",
        "  readonly property real barEdgeMargin: bar && bar.floatGap !== undefined\n"
        "    ? Math.max(0, Number(bar.floatGap) || 0) : 0\n"
        "  property int gap: Style.gapsOut + barEdgeMargin  // distance between bar edge and panel\n",
    ),
    (
        "/usr/share/omarchy/shell/plugins/notifications/Toast.qml",
        "    color: Commons.Color.notifications.background\n",
        "    color: Qt.rgba(Commons.Color.notifications.background.r, Commons.Color.notifications.background.g, Commons.Color.notifications.background.b, 1)\n"
        "    opacity: Style.shellOpacity\n",
    ),
    (
        "/usr/share/omarchy/shell/plugins/menu/Menu.qml",
        "      color: root.background\n",
        "      color: Qt.rgba(root.background.r, root.background.g, root.background.b, 1)\n"
        "      opacity: Style.shellOpacity\n",
    ),
    (
        "/usr/share/omarchy/shell/plugins/notifications/Service.qml",
        "    return Delivery.deckMargins(barPosition, Delivery.barThickness(barRef, screenName, defaultBarSize), Style.gapsOut)\n",
        "    var edgeMargin = barRef && barRef.floatGap !== undefined ? Math.max(0, Number(barRef.floatGap) || 0) : 0\n"
        "    return Delivery.deckMargins(barPosition, Delivery.barThickness(barRef, screenName, defaultBarSize) + edgeMargin, Style.gapsOut)\n",
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
