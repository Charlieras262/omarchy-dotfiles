-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1.25

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })
-- DP-1: Xiaomi 34" ultrawide, resolución nativa, sin rotar, a la derecha del LG en vertical
hl.monitor({ output = "DP-1", mode = "3440x1440@144", position = "1440x0", scale = omarchy_monitor_scale })

-- DP-2: LG UltraGear 27" en vertical (rotado 90°), a la izquierda
hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = omarchy_monitor_scale, transform = 1 })

-- Pin workspaces to a monitor: 1/3/5 on DP-2 (LG UltraGear, vertical), 2/4/6 on DP-1 (Xiaomi ultrawide).
hl.workspace_rule({ workspace = "1", monitor = "DP-2", default = true, persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-2", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "DP-2", persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-1", default = true, persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "6", monitor = "DP-1", persistent = true })
-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
