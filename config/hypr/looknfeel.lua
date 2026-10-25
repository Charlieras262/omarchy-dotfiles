-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
hl.config({
  decoration = {
    -- Use round window corners.
    rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
    blur = {
      enabled = true,
      size = 8,
      passes = 3,
      new_optimizations = true,
      ignore_opacity = true,
    },
  }
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })
-- Blur + see-through everywhere the Omarchy shell draws a surface: bar,
-- notifications, menus, popups, OSD, polkit prompts, etc.
hl.layer_rule({ match = { namespace = "^omarchy-.*$" }, blur = true, blur_popups = true, ignore_alpha = 0.2 })

-- macOS-style workspace switching: slide + fade with a slight overshoot.
hl.curve("mybezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.5, bezier = "mybezier", style = "slidefade" })

-- BEGIN charlieras262.omablur
hl.config({
  decoration = {
    rounding = 8,
    blur = {
      enabled = true,
      size = 9,
      passes = 2,
      new_optimizations = true,
      ignore_opacity = true,
    },
  },
})
-- END charlieras262.omablur
