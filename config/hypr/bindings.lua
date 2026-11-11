-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Cycle workspaces on the current monitor only (workspaces are pinned to
-- monitors in hypr/monitors.lua, so this stays within DP-1 or DP-2).
o.bind("SUPER + SHIFT + CTRL + UP", "Previous workspace on this monitor", hl.dsp.focus({ workspace = "m-1" }))
o.bind("SUPER + SHIFT + CTRL + DOWN", "Next workspace on this monitor", hl.dsp.focus({ workspace = "m+1" }))

-- Switch monitor focus. Note: CTRL+ALT+TAB / CTRL+ALT+SHIFT+TAB already do
-- this by default; these are just left/right-labeled duplicates of the same
-- action for a 2-monitor setup.
o.bind("SUPER + SHIFT + CTRL + LEFT", "Focus previous monitor", hl.dsp.focus({ monitor = "-1" }))
o.bind("SUPER + SHIFT + CTRL + RIGHT", "Focus next monitor", hl.dsp.focus({ monitor = "+1" }))

-- SUPER+J is `togglesplit`, which only exists in the dwindle layout; on a
-- scrolling workspace (e.g. 5) it raises "no such layoutmsg for scrolling".
-- Only send it when the active workspace is actually dwindle.
hl.unbind("SUPER + J")
o.bind("SUPER + J", "Toggle window split (dwindle only)", "sh -c '[ \"$(hyprctl activeworkspace -j | jq -r .tiledLayout)\" = dwindle ] && hyprctl dispatch \"hl.dsp.layout(\\\"togglesplit\\\")\"'")

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end

-- Global workspace numbers, as before Omarchy 4.5. Omarchy 4.5 gives every
-- monitor its own block of ten (LG 1-10, Xiaomi 11-20) and renumbers
-- workspaces on every reload; this keeps the 1/3/5 (LG) and 2/4/6 (Xiaomi)
-- pins in hypr/monitors.lua instead. Delete this block to go back to
-- Omarchy's per-monitor workspaces.
o.workspaces.reconcile = function() end

for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  local id = tostring(workspace)
  hl.unbind("SUPER + " .. key)
  hl.unbind("SUPER + SHIFT + " .. key)
  hl.unbind("SUPER + SHIFT + ALT + " .. key)
  o.bind("SUPER + " .. key, "Switch to workspace " .. id, hl.dsp.focus({ workspace = id }))
  o.bind("SUPER + SHIFT + " .. key, "Move window to workspace " .. id, hl.dsp.window.move({ workspace = id }))
  o.bind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. id, hl.dsp.window.move({ workspace = id, follow = false }))
end

hl.unbind("SUPER + TAB")
hl.unbind("SUPER + SHIFT + TAB")
hl.unbind("SUPER + CTRL + TAB")
o.bind("SUPER + TAB", "Next workspace", hl.dsp.focus({ workspace = "e+1" }))
o.bind("SUPER + SHIFT + TAB", "Previous workspace", hl.dsp.focus({ workspace = "e-1" }))
o.bind("SUPER + CTRL + TAB", "Former workspace", hl.dsp.focus({ workspace = "previous" }))

-- Moving a workspace to another monitor keeps its number.
for _, direction in ipairs({ "LEFT", "RIGHT", "UP", "DOWN" }) do
  hl.unbind("SUPER + SHIFT + ALT + " .. direction)
  o.bind("SUPER + SHIFT + ALT + " .. direction, "Move workspace to " .. direction:lower() .. " monitor",
    hl.dsp.workspace.move({ monitor = direction:sub(1, 1):lower() }))
end
