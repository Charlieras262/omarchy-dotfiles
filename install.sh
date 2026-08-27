#!/usr/bin/env bash
# Reapplies Charlie's personal Omarchy customizations after a fresh install.
# Safe to re-run: it backs up whatever is already in place before overwriting.
#
# What this restores:
#   - Workspaces 1/3/5 pinned to DP-1, 2/4/6 pinned to DP-2 (persistent)
#   - App-to-workspace window rules (terminal/browser/steam/dota2/discord/
#     whatsapp/windows-vm) + Steam main window forced to tile
#   - Extra keybinds: cycle workspaces on the current monitor, focus
#     left/right monitor
#   - Blur + translucency across all Omarchy shell surfaces (bar, menu,
#     notifications, popups, tooltip), taller bar, no menu button in the bar
#   - Pill-shaped active-workspace indicator: published as its own plugin,
#     https://github.com/Charlieras262/omarchy-pill-workspaces -- installed
#     via `omarchy plugin add`, not copied from this repo
#   - Floating, rounded-corner bar: published as its own plugin,
#     https://github.com/Charlieras262/omarchy-floating-bar -- installed
#     via `omarchy plugin add`, not copied from this repo
#
# See README.md for the reasoning behind each piece and for things that may
# need re-checking (monitor names, app window classes) after a reinstall.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_DIR="$HOME/.config/hypr"
OMARCHY_CFG_DIR="$HOME/.config/omarchy"
BACKUP_SUFFIX=".bak.$(date +%s)"

if ! command -v omarchy >/dev/null 2>&1; then
  echo "error: 'omarchy' command not found. Run this on an Omarchy system." >&2
  exit 1
fi

backup_and_copy() {
  local src="$1" dest="$2"
  if [[ -e "$dest" ]] && ! cmp -s "$src" "$dest"; then
    cp "$dest" "$dest$BACKUP_SUFFIX"
    echo "backed up $dest -> $dest$BACKUP_SUFFIX"
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  echo "wrote $dest"
}

echo "== Hyprland config =="
backup_and_copy "$SCRIPT_DIR/config/hypr/monitors.lua"   "$HYPR_DIR/monitors.lua"
backup_and_copy "$SCRIPT_DIR/config/hypr/bindings.lua"   "$HYPR_DIR/bindings.lua"
backup_and_copy "$SCRIPT_DIR/config/hypr/hyprland.lua"   "$HYPR_DIR/hyprland.lua"
backup_and_copy "$SCRIPT_DIR/config/hypr/looknfeel.lua"  "$HYPR_DIR/looknfeel.lua"

echo "== Omarchy shell config =="
backup_and_copy "$SCRIPT_DIR/config/omarchy/shell.json" "$OMARCHY_CFG_DIR/shell.json"
backup_and_copy "$SCRIPT_DIR/config/omarchy/shell.toml" "$OMARCHY_CFG_DIR/shell.toml"

echo "== Pill workspace indicator (published plugin) =="
omarchy plugin add https://github.com/Charlieras262/omarchy-pill-workspaces.git --enable --yes \
  || echo "warning: 'omarchy plugin add' failed -- install it by hand: omarchy plugin add https://github.com/Charlieras262/omarchy-pill-workspaces.git --enable"

echo "== Floating rounded bar (published plugin) =="
omarchy plugin add https://github.com/Charlieras262/omarchy-floating-bar.git --enable --yes \
  || echo "warning: 'omarchy plugin add' failed -- install it by hand: omarchy plugin add https://github.com/Charlieras262/omarchy-floating-bar.git --enable"

echo
echo "== Reloading =="
hyprctl reload || echo "warning: 'hyprctl reload' failed -- is Hyprland running?"
errors="$(hyprctl configerrors 2>/dev/null || true)"
if [[ -n "$errors" ]]; then
  echo "warning: hyprctl configerrors reported:"
  echo "$errors"
fi
omarchy restart shell || echo "warning: 'omarchy restart shell' failed"

cat <<'EOF'

== Done. Please double-check by hand ==
1. Monitor names may differ on new/replaced hardware:
     hyprctl monitors all
   If your outputs aren't DP-1/DP-2, edit config/hypr/monitors.lua's
   hl.workspace_rule() monitor fields (and the hl.monitor() calls) to match.

2. Window-rule class/title matches can drift with app updates. If Dota 2,
   WhatsApp, or the Windows VM stop landing on their assigned workspace,
   open them and check the real values with:
     hyprctl clients
   then update the matching o.window(...) call in config/hypr/hyprland.lua.

3. This only restores the files this setup actually touched. It does not
   touch hypr/input.lua, hypr/autostart.lua, or your theme -- those are
   assumed to still be Omarchy defaults or handled separately.

4. omarchy-floating-bar contains a workaround for an Omarchy bug (cloned
   "kind: bar" plugins fail to render -- basecamp/omarchy#8007). Check
   https://github.com/Charlieras262/omarchy-floating-bar for whether it's
   still needed (it becomes redundant once basecamp/omarchy#8146 ships in
   a stable release).
EOF
