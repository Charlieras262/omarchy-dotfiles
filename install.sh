#!/usr/bin/env bash
# Reapplies Charlie's personal Omarchy customizations after a fresh install.
# Safe to re-run: it backs up whatever is already in place before overwriting.
#
# What this restores:
#   - Auto-detected monitor layout: whichever known monitor (AOC/LG/Xiaomi)
#     is connected gets matched by EDID description (not DP-N port name), so
#     cable/port swaps and monitor substitutions (e.g. one going out for
#     repair) just work. Workspaces 1/3/5 pinned to the vertical monitor,
#     2/4/6 to the horizontal one (persistent)
#   - App-to-workspace window rules (terminal/browser/steam/dota2/discord/
#     whatsapp/windows-vm) + Steam main window forced to tile
#   - Extra keybinds: cycle workspaces on the current monitor, focus
#     left/right monitor
#   - Blur + translucency across all Omarchy shell surfaces (bar, menu,
#     notifications, popups, tooltip), taller bar, no menu button in the bar
#   - Input tweaks: intl keyboard variant, numlock on by default (both
#     uncommented in Omarchy's own template, everything else left stock)
#   - Windows VM launch wrapper: using the VM's SMB shared folder from inside
#     Windows resets ~/Windows to mode 2700 (setgid), which trips
#     omarchy-windows-vm's own mount-safety check and makes the next launch
#     fail instantly. The wrapper clears that bit (no sudo needed, Charlie
#     owns the folder) before every launch; the .desktop launcher (Super +
#     Space) points at it instead of omarchy-windows-vm directly.
#   - Pill-shaped active-workspace indicator: published as its own plugin,
#     https://github.com/Charlieras262/omarchy-pill-workspaces -- installed
#     via `omarchy plugin add`, not copied from this repo
#   - Floating, rounded-corner bar: published as its own plugin,
#     https://github.com/Charlieras262/omarchy-floating-bar -- installed
#     via `omarchy plugin add`, not copied from this repo
#   - Rounding/blur tuning bar panel: published as its own plugin,
#     https://github.com/Charlieras262/omarchy-omablur -- installed via
#     `omarchy plugin add`, not copied from this repo
#
# See README.md for the reasoning behind each piece and for things that may
# need re-checking (monitor names, app window classes) after a reinstall.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_DIR="$HOME/.config/hypr"
OMARCHY_CFG_DIR="$HOME/.config/omarchy"
LOCAL_BIN_DIR="$HOME/.local/bin"
LOCAL_APPS_DIR="$HOME/.local/share/applications"
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
backup_and_copy "$SCRIPT_DIR/config/hypr/input.lua"      "$HYPR_DIR/input.lua"

echo "== Omarchy shell config =="
backup_and_copy "$SCRIPT_DIR/config/omarchy/shell.json" "$OMARCHY_CFG_DIR/shell.json"
backup_and_copy "$SCRIPT_DIR/config/omarchy/shell.toml" "$OMARCHY_CFG_DIR/shell.toml"

echo "== Windows VM launch wrapper =="
backup_and_copy "$SCRIPT_DIR/local/bin/omarchy-windows-vm-launch-fixed" "$LOCAL_BIN_DIR/omarchy-windows-vm-launch-fixed"
chmod +x "$LOCAL_BIN_DIR/omarchy-windows-vm-launch-fixed"
if [[ -f "$LOCAL_APPS_DIR/windows-vm.desktop" ]]; then
  backup_and_copy "$SCRIPT_DIR/local/share/applications/windows-vm.desktop" "$LOCAL_APPS_DIR/windows-vm.desktop"
else
  echo "note: windows-vm.desktop not found -- run 'omarchy windows vm install' first, then re-run this script to point its launcher at the wrapper"
fi

echo "== Pill workspace indicator (published plugin) =="
omarchy plugin add https://github.com/Charlieras262/omarchy-pill-workspaces.git --enable --yes \
  || echo "warning: 'omarchy plugin add' failed -- install it by hand: omarchy plugin add https://github.com/Charlieras262/omarchy-pill-workspaces.git --enable"

echo "== Floating rounded bar (published plugin) =="
omarchy plugin add https://github.com/Charlieras262/omarchy-floating-bar.git --enable --yes \
  || echo "warning: 'omarchy plugin add' failed -- install it by hand: omarchy plugin add https://github.com/Charlieras262/omarchy-floating-bar.git --enable"

echo "== Rounding/blur tuning panel (published plugin) =="
omarchy plugin add https://github.com/Charlieras262/omarchy-omablur.git --enable --yes \
  || echo "warning: 'omarchy plugin add' failed -- install it by hand: omarchy plugin add https://github.com/Charlieras262/omarchy-omablur.git --enable"

echo "== post-update hook: reapply shell-opacity patches after 'omarchy update' =="
omarchy hook install post-update "$SCRIPT_DIR/config/omarchy/hooks/post-update.d/reapply-shell-opacity-patches.sh" \
  || echo "warning: 'omarchy hook install' failed -- install it by hand: omarchy hook install post-update $SCRIPT_DIR/config/omarchy/hooks/post-update.d/reapply-shell-opacity-patches.sh"

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
1. Monitor layout is matched by EDID description (see the KNOWN table at
   the top of config/hypr/monitors.lua), not by DP-N port name, so cable/
   port changes and swapping AOC<->Xiaomi as the LG's partner need no edits.
   A genuinely new/replacement monitor does need one: find its description
   with `hyprctl monitors all` and add it to KNOWN.

2. Window-rule class/title matches can drift with app updates. If Dota 2,
   WhatsApp, or the Windows VM stop landing on their assigned workspace,
   open them and check the real values with:
     hyprctl clients
   then update the matching o.window(...) call in config/hypr/hyprland.lua.

3. This only restores the files this setup actually touched. It does not
   touch your theme (~/.config/omarchy/themes/... or the active theme
   selection) -- that's assumed to be handled separately (pick it again
   from the Omarchy theme menu after a fresh install).

4. omarchy-floating-bar contains a workaround for an Omarchy bug (cloned
   "kind: bar" plugins fail to render -- basecamp/omarchy#8007). Check
   https://github.com/Charlieras262/omarchy-floating-bar for whether it's
   still needed (it becomes redundant once basecamp/omarchy#8146 ships in
   a stable release).

5. Neither omarchy-floating-bar nor omarchy-omablur can safely automate
   the FIRST application of this step: both need a manual, one-time root
   edit to a couple of Omarchy's own system files (so notifications/popups
   clear the floating bar's edge margin, and so the shell dims in sync
   with blur). Follow the "Known limitation"/"Making blur actually
   visible" section of each plugin's README and copy the snippets in by
   hand with sudoedit. A `post-update` hook (installed above) reapplies
   the same edits automatically after every `omarchy update`, since an
   update silently drops them -- but it still needs that first manual
   pass on a fresh install, before any patch exists to reapply.
EOF
