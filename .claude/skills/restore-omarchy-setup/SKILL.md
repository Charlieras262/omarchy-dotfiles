---
name: restore-omarchy-setup
description: Reapply Charlie's personal Omarchy/Hyprland customizations (workspace-to-monitor pinning, app window rules, blur/translucency, custom workspaces bar widget) on a freshly installed or updated Omarchy system, adapting the implementation if Omarchy's internal APIs have changed since this was written.
---

# Restore Omarchy setup

This repo is a snapshot of one user's Omarchy customizations (see
`README.md` in the repo root for the full list and rationale). Use this
skill when asked to restore, reapply, or adapt that setup -- on a fresh
install, a new machine, or after an Omarchy update broke something.

**Always load the repo's `omarchy` skill first** (or the general Omarchy
customization skill available in the current environment) -- it has the
authoritative, current rules for where config lives and how to validate
changes (`hyprctl reload` / `hyprctl configerrors` after Hyprland edits,
never editing `/usr/share/omarchy/` or `$OMARCHY_PATH` directly, cloning
plugins instead of editing built-ins, etc.). This skill only adds the
*specifics* of what this particular setup needs and how those specifics
were discovered, in case they need to be rediscovered.

## Fast path: same Omarchy version

Just run `./install.sh` from the repo root. It backs up existing files and
copies the snapshot into place. Read its final output for two manual
follow-ups (monitor names, app window classes may have drifted).

## Slow path: something doesn't work after an Omarchy update

Don't assume the snapshot's Lua/QML syntax is still correct -- Omarchy and
Hyprland's Lua config API are not a stable, versioned interface. Re-derive
instead of guessing. This is the process that built the snapshot in the
first place:

1. **For a Hyprland Lua config question** (new `hl.*` function, changed
   window/layer rule fields, workspace rule syntax): the *authoritative*
   source is the C++ headers shipped with the Hyprland package, not
   memory or the web -- Hyprland's own Lua config support is new enough
   that docs lag the implementation.
   ```bash
   # Enumerate window-rule effect names (the exact strings hl.window_rule
   # accepts as table keys):
   grep -n '"[a-z_]*"' /usr/include/hyprland/src/config/lua/bindings/LuaBindingsInternal.hpp
   # Same idea for layer rules:
   cat /usr/include/hyprland/src/desktop/rule/layerRule/LayerRuleEffectContainer.hpp
   # Workspace selector syntax (m+1/m-1 for "next/prev workspace on this
   # monitor", used by the custom keybinds) isn't in these headers -- it's
   # only documented on wiki.hypr.land's Dispatchers page (fetch it, or
   # search for the exact selector prefixes if the fetch gets truncated).
   ```
   Cross-check any function/table-key you plan to use against how
   `$OMARCHY_PATH/default/hypr/**/*.lua` already calls it -- that's live,
   working reference code for the same Hyprland version installed.

2. **For an Omarchy shell (Quickshell bar/menu/notifications) question**:
   read the actual QML source under `$OMARCHY_PATH/shell/`, don't guess
   property names.
   ```bash
   # Find how a built-in bar widget is implemented, to clone/adapt it:
   find "$OMARCHY_PATH/shell/plugins/bar/widgets" -iname "*Workspaces*"
   # Find which shell.toml [section] keys exist and what they fall back to
   # (this is also how bar height / translucency alpha keys were found):
   grep -n "background-alpha\|composed(\|function composed" \
     "$OMARCHY_PATH/shell/Commons/Color.qml"
   # Find a layer surface's WlrLayershell.namespace (needed to target it
   # with a Hyprland layer_rule for blur):
   grep -rn "WlrLayershell.namespace" "$OMARCHY_PATH/shell/"
   ```
   Never edit files under `$OMARCHY_PATH/shell/` -- clone the plugin into
   `~/.config/omarchy/plugins/` first (`omarchy plugin clone <id>`), same
   as `charlie.workspaces` was built.

3. **For an app's window class/title** (needed for `o.window(...)` rules
   like Dota 2, WhatsApp, Discord, the Windows VM): don't hardcode guesses
   from memory or forum posts as the final answer -- open the app and read
   its real properties, then adjust the rule:
   ```bash
   hyprctl clients   # look for the app's "class:" and "title:" fields
   ```
   The repo's `hyprland.lua` has a comment above each app-specific rule
   noting how its match value was obtained; update both the rule and that
   comment if the value changes.

4. After any change: `hyprctl reload && hyprctl configerrors` for
   Hyprland-side files; `omarchy restart shell` for shell.json/shell.toml/
   plugin QML changes (shell.toml alone hot-reloads, but a full restart is
   the safe fallback if a change doesn't seem to take).

5. Update `README.md` and this file with whatever changed, so the next
   restore (human or AI) starts from the corrected version instead of
   rediscovering the same thing.
