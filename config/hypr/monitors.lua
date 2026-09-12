-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Charlie's known monitors, identified by their EDID description (stable
-- across cables/ports/monitor swaps) instead of DP-N connector names, which
-- change every time a cable or port changes. "height" is each panel's
-- native height -- when rotated 90° that becomes its on-screen width, which
-- the other monitor's x position needs to sit flush against.
local KNOWN = {
  aoc =    { match = "AOC 24G2W1G3",              mode = "1920x1080@144", height = 1080 },
  lg =     { match = "LG Electronics LG ULTRAGEAR", mode = "2560x1440@144", height = 1440 },
  xiaomi = { match = "Xiaomi Corporation Mi monitor", mode = "3440x1440@144", height = 1440 },
}

local function find(monitors, key)
  local wanted = KNOWN[key].match
  for _, m in ipairs(monitors) do
    if m.description and m.description:find(wanted, 1, true) then
      return m
    end
  end
  return nil
end

-- Picks which known monitor plays "vertical, rotated 90°, on the left" vs
-- "horizontal, to its right" for whichever pair is currently connected, then
-- applies both hl.monitor() rules and the workspace pins (1/3/5 on the
-- vertical one, 2/4/6 on the horizontal one) to match. Re-run on every
-- monitor hotplug so swapping cables, ports, or even which secondary
-- monitor is plugged in (e.g. the Xiaomi going out for repair) just works
-- without editing this file.
local function apply_layout()
  local monitors = hl.get_monitors()
  local lg = find(monitors, "lg")
  local aoc = find(monitors, "aoc")
  local xiaomi = find(monitors, "xiaomi")

  local vertical_key, vertical, horizontal_key, horizontal
  if xiaomi and lg then
    vertical_key, vertical, horizontal_key, horizontal = "lg", lg, "xiaomi", xiaomi
  elseif aoc and lg then
    vertical_key, vertical, horizontal_key, horizontal = "aoc", aoc, "lg", lg
  elseif aoc and xiaomi then
    vertical_key, vertical, horizontal_key, horizontal = "aoc", aoc, "xiaomi", xiaomi
  end

  if vertical and horizontal then
    local horizontal_x = math.floor(KNOWN[vertical_key].height / omarchy_monitor_scale)

    hl.monitor({
      output = vertical.name,
      mode = KNOWN[vertical_key].mode,
      position = "0x0",
      scale = omarchy_monitor_scale,
      transform = 1,
    })
    hl.monitor({
      output = horizontal.name,
      mode = KNOWN[horizontal_key].mode,
      position = horizontal_x .. "x0",
      scale = omarchy_monitor_scale,
    })

    hl.workspace_rule({ workspace = "1", monitor = vertical.name, default = true, persistent = true })
    hl.workspace_rule({ workspace = "3", monitor = vertical.name, persistent = true })
    hl.workspace_rule({ workspace = "5", monitor = vertical.name, persistent = true })
    hl.workspace_rule({ workspace = "2", monitor = horizontal.name, default = true, persistent = true })
    hl.workspace_rule({ workspace = "4", monitor = horizontal.name, persistent = true })
    hl.workspace_rule({ workspace = "6", monitor = horizontal.name, persistent = true })
  else
    -- Only one monitor, or an unrecognized one -- don't guess a rotation or
    -- workspace split, just let Hyprland auto-arrange it.
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })
  end
end

apply_layout()
hl.on("monitor.added", function() hl.exec_cmd("hyprctl reload") end)
hl.on("monitor.removed", function() hl.exec_cmd("hyprctl reload") end)
