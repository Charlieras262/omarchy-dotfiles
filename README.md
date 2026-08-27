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
| Steam | 3 | `class = "steam"` |
| Steam games (see below) | 6 | `class = "<game class>"` |
| Discord | 5 | `class = "discord"` |
| WhatsApp (web app) | 5 | `class = "chrome-web.whatsapp.com__..."` |
| Windows VM (FreeRDP) | 4 | `title = "Windows VM - Omarchy"` |

The main Steam window is also forced to tile (`{ class = "steam", title =
"Steam" }, { tile = true }`), overriding Omarchy's default float for that
window. Friends List and other Steam popups are untouched.

**Steam games -> workspace 6** is a plain list, not automatic detection.
An earlier attempt hooked `hl.on("window.open", ...)` and checked each new
window's process for the `SteamAppId` environment variable Steam sets on
game processes -- this does **not** work on this install, because Steam's
Linux Runtime sandboxes games with pressure-vessel/bwrap, which builds a
curated environment for the sandboxed process that drops `SteamAppId`
before the game ever sees it (confirmed by logging `class`/`pid`/detection
result for a real Dota 2 launch: the class and pid were captured correctly,
but the env var was absent). So instead, `hyprland.lua` has a maintained
list:

```lua
local steam_game_classes = {
  "dota2",
}
```

To add a game: open it, run `hyprctl clients` while it's running, copy the
`class:` value shown for its window, and add it as another entry in that
table (escaping regex special characters the same way the WhatsApp rule
does, if the class needs it).

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

### Pill workspace indicator: published plugin, not copied here

The active-workspace pill (rounded, theme-colored, auto-contrast number)
started as a clone of `omarchy.workspaces` kept in this repo, then got
generalized (configurable slot count/color/radius/inset instead of
hardcoded values) and published as its own public, opensource plugin:

**https://github.com/Charlieras262/omarchy-pill-workspaces** (MIT)

Install it with `omarchy plugin add
https://github.com/Charlieras262/omarchy-pill-workspaces.git --enable`
(which is what `install.sh` does) rather than copying files from this repo
-- that plugin's own repo is now the source of truth, and `omarchy plugin
update` pulls new versions of it independently of this dotfiles repo.

### Floating, rounded-corner bar: `charlie.bar` (`config/omarchy/plugins/
charlie.bar/`)

Cloned from the built-in `omarchy.bar` (`omarchy plugin clone omarchy.bar`)
and edited to:

- Add a configurable gap (`floatGap`, default 8px) between the bar surface
  and whichever screen edges it's anchored to -- set via layer-shell
  `margins` on the bar's `PanelWindow`, applied uniformly to all four
  margins (the compositor only honors the ones that are actually anchored,
  so this reads correctly as "top + both sides" for a top bar without
  branching per position).
- Make the `PanelWindow` surface itself fully transparent and draw the
  actual bar background in a child `Rectangle` with a configurable
  `radius` (`cornerRadius`, default 14px) instead -- so the corners outside
  that radius show the desktop through them rather than being a square
  window with rounded content clipped inside it.
- Both values are read from `shell.json`'s `bar:` entry
  (`"floatGap": 8, "cornerRadius": 14`) the same way `position` and
  `transparent` are, with those defaults as fallback if absent.

**This required a workaround for a genuine Omarchy bug**
(`basecamp/omarchy#8007`, filed from this setup): cloning *any* `"kind":
"bar"` plugin -- even completely unedited -- never renders, because the bar
loads via `Loader.source` (a URL), which can't supply QML `required
property` values at construction the way the built-in bar's
`sourceComponent` can; `configureBar()` in `shell.qml` only sets them
shortly *after* construction, which is too late for a `required` property.

The workaround (confirmed independently by another user on the issue, on
completely different hardware): drop `required` from the three properties
at the top of the cloned `Bar.qml` (`omarchyPath`, `barWidgetRegistry`,
`barConfig`) and give them inline defaults instead --
`configureBar()` still assigns the real values immediately after, and
nothing in `Bar.qml` reads them before that point. See the comment above
those three properties in `config/omarchy/plugins/charlie.bar/Bar.qml`.

**basecamp/omarchy PR #8146** fixes this properly from the other side
(passing the properties as `Loader.setSource(url, initialProperties)`
arguments, so cloned bars can keep `required`). Once that PR merges into a
stable Omarchy release, this workaround should be reverted -- restore
`required` on all three properties -- since it becomes redundant with the
upstream fix. Check `gh pr view 8146 --repo basecamp/omarchy` for status.

Because it's a *clone*, Omarchy updates to the stock `omarchy.bar` won't
touch this file, but they also won't reach it -- if Omarchy ships a
meaningfully different stock version later (especially once #8146 lands),
diff it against `$OMARCHY_PATH/shell/plugins/bar/Bar.qml` and re-apply the
`floatGap`/`cornerRadius` additions by hand.

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
