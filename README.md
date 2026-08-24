# My Omarchy setup

Personal Hyprland/Omarchy customizations, snapshotted so they can be
reapplied after a reinstall. Built with Claude Code across a few sessions;
see `.claude/skills/restore-omarchy-setup/SKILL.md` if you're asking an AI
assistant to redo this on a new install instead of running the script.

## Quick start

```bash
git clone <this-repo-url> ~/omarchy-dotfiles
cd ~/omarchy-dotfiles
./install.sh
```

The script backs up any existing file before overwriting it
(`<file>.bak.<timestamp>`), copies everything into place, then runs
`hyprctl reload` and `omarchy restart shell`. Read its final output --
it lists two things worth double-checking by hand after a reinstall
(monitor output names, app window classes).

## What's in here, and why

### Monitors: workspaces pinned per screen (`config/hypr/monitors.lua`)

Workspaces 1/3/5 live on `DP-1` (AOC 24", rotated), 2/4/6 on `DP-2` (LG
UltraGear). Done with `hl.workspace_rule({ workspace = "N", monitor = "...",
persistent = true })` -- `persistent = true` matters: without it a workspace
only "exists" (and only shows up in the bar) once something has been opened
on it at least once.

**If you swap a monitor or a cable moves it to a different port**, the
output name (`DP-1`/`DP-2`) can change. Check with `hyprctl monitors all`
and update both the `hl.monitor()` calls and the `hl.workspace_rule()` calls
here.

### App-to-workspace + Steam tiling (`config/hypr/hyprland.lua`)

Window rules assign apps to a workspace when they open (not autostart --
nothing launches on login, this only applies once you open the app
yourself):

| App | Workspace | Matched by |
|---|---|---|
| Terminal (any, via the `terminal` tag) | 1 | `tag = "terminal"` |
| Browser (chromium- or firefox-based) | 1 | `tag = "chromium-based-browser"` / `"firefox-based-browser"` |
| Steam | 3 | `class = "steam"` |
| Dota 2 | 6 | `class = "dota2"` |
| Discord | 5 | `class = "discord"` |
| WhatsApp (web app) | 5 | `class = "chrome-web.whatsapp.com__..."` |
| Windows VM (FreeRDP) | 4 | `title = "Windows VM - Omarchy"` |

The main Steam window is also forced to tile (`{ class = "steam", title =
"Steam" }, { tile = true }`), overriding Omarchy's default float for that
window. Friends List and other Steam popups are untouched.

**These class/title matches were read off the actual running windows via
`hyprctl clients` at the time this was written.** Chromium's web-app class
format and Dota 2's WM class are not guaranteed stable across app/driver
updates -- if one stops landing on the right workspace, open it, run
`hyprctl clients`, and update the corresponding line here.

### Extra keybinds (`config/hypr/bindings.lua`)

- `SUPER+SHIFT+CTRL+UP/DOWN` -- cycle workspaces on the *current monitor
  only* (`hl.dsp.focus({ workspace = "m-1" / "m+1" })`), which only makes
  sense because workspaces are pinned to monitors above.
- `SUPER+SHIFT+CTRL+LEFT/RIGHT` -- focus left/right monitor. Functionally
  the same as Omarchy's stock `CTRL+ALT+TAB` / `CTRL+ALT+SHIFT+TAB`; kept as
  a second binding because the arrow-key scheme was requested specifically.

### Blur, translucency, and rounding (`config/hypr/looknfeel.lua`,
`config/omarchy/shell.toml`, `config/omarchy/shell.json`)

- `decoration.blur` is on (`size = 8, passes = 3`), plus a Hyprland layer
  rule: `hl.layer_rule({ match = { namespace = "^omarchy-.*$" }, blur = true,
  blur_popups = true, ignore_alpha = 0.5 })`. The namespace regex covers
  every Omarchy shell surface (bar, menu, notifications, OSD, polkit,
  clipboard, emojis, ...) in one rule.
- `ignore_alpha = 0.5` is a threshold, not a toggle: pixels of a layer
  surface with alpha below it are excluded from blur, at/above it are
  blurred. This matters because the root/system menu draws a full-screen
  dim "scrim" *and* the menu box in the same surface -- without separating
  their alpha values, the whole screen behind the scrim gets blurred too.
  That's why `[menu] scrim-alpha = 0` in `shell.toml` (fully transparent,
  well under the 0.5 threshold) while `[menu] background-alpha = 0.62`
  (above it, so the box itself blurs). Same fix applied to `[polkit]` and
  `[image-picker]` scrims pre-emptively, since they have the same
  scrim+box structure.
- `shell.toml` `[bar] size-horizontal = 34` makes the bar taller (default
  26). This file is a **machine-level override** (`~/.config/omarchy/
  shell.toml`, distinct from any theme's own `shell.toml`) -- it survives
  theme switches.
- `shell.json`: `bar.transparent` is `false` -- that flag makes the bar
  *fully* see-through (literally `color: "transparent"` in the QML), which
  is not what "translucent" means here. Real translucency comes from the
  `background-alpha` values in `shell.toml` instead.
- `shell.json`: the `omarchy.menu` bar button was removed from the `left`
  layout (keyboard-only workflow: `SUPER+SPACE` / `SUPER+ESCAPE` still open
  the menus). `omarchy.active-window` was added right after the workspaces
  widget to show the focused window's title.

### Custom bar widget: `charlie.workspaces` (`config/omarchy/plugins/
charlie.workspaces/`)

Cloned from the built-in `omarchy.workspaces` (`omarchy plugin clone
omarchy.workspaces`) and edited:

- Seeds workspace IDs `[1..6]` instead of `[1..5]` -- the stock widget only
  ever shows a 6th+ workspace once it has been visited at least once in the
  session; combined with `persistent = true` above, workspace 6 now always
  shows.
- The focused workspace renders as a rounded rectangle (fixed 6px radius,
  not tied to the window-decoration rounding setting) filled with
  `Color.foreground` (the theme's text color) instead of swapping the
  number for an icon glyph.
- The number's own color picks whichever of `Color.background` /
  `Color.foreground` has more luminance contrast against that fill, so it
  stays legible across different theme color combinations.
- The colored rectangle has a 6px top/bottom inset so it reads as a wide
  pill rather than a full-height square; the click target (`WidgetButton`)
  still fills the whole bar-height cell.

Because it's a *clone*, Omarchy updates to the stock `omarchy.workspaces`
widget won't touch this file, but they also won't reach it -- if Omarchy
ships a meaningfully different stock version later, diff it against
`$OMARCHY_PATH/shell/plugins/bar/widgets/Workspaces.qml` and re-apply these
changes by hand.

## About "keeping this updated with Omarchy"

A script that automatically tracks Omarchy's own upstream changes isn't
something that can be built as a static file -- Omarchy's internal Lua/QML
APIs (the `hl.*` functions, `Color`/`Style` singletons, shell.toml schema)
aren't a documented stable interface, and this setup was built by reading
Hyprland's own C++ header comments and Omarchy's shipped QML source to find
the right calls. That process is what
`.claude/skills/restore-omarchy-setup/SKILL.md` documents, so that a future
AI session (or you) can re-derive correct syntax if something here breaks
after an Omarchy update, rather than blindly re-running a script against a
changed API.

Practical middle ground:
- `install.sh` is the fast path for "same Omarchy version, new machine/
  reinstall."
- After any major Omarchy update, run `hyprctl configerrors` and eyeball
  the bar/menu once. If something's off, point Claude Code (with the
  `restore-omarchy-setup` skill loaded from this repo, or just this
  README) at the specific symptom.
