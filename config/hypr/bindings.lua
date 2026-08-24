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
o.bind("SUPER + SHIFT + CTRL + LEFT", "Focus left monitor", hl.dsp.focus({ monitor = "l" }))
o.bind("SUPER + SHIFT + CTRL + RIGHT", "Focus right monitor", hl.dsp.focus({ monitor = "r" }))
