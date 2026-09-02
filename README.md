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

### Input tweaks (`config/hypr/input.lua`)

Omarchy ships this file as a template of commented-out examples; only two
lines are actually uncommented here: `kb_variant = "intl"` and
`numlock_by_default = true`. Everything else in the file is still the
stock template, kept as-is so future examples Omarchy adds to it aren't
lost by a plain overwrite.

### Extra keybinds (`config/hypr/bindings.lua`)

- `SUPER+SHIFT+CTRL+UP/DOWN` -- cycle workspaces on the *current monitor
  only* (`hl.dsp.focus({ workspace = "m-1" / "m+1" })`), which only makes
  sense because workspaces are pinned to monitors above.
- `SUPER+SHIFT+CTRL+LEFT/RIGHT` -- focus left/right monitor. Functionally
  the same as Omarchy's stock `CTRL+ALT+TAB` / `CTRL+ALT+SHIFT+TAB`; kept as
  a second binding because the arrow-key scheme was requested specifically.

### Blur, translucency, and rounding (`config/hypr/looknfeel.lua`,
`config/omarchy/shell.toml`, `config/omarchy/shell.json`)

- `decoration.blur` is on (`size = 8, passes = 3` in the base config --
  `omarchy-omablur`'s own marked block further down the file, added by that
  plugin itself, currently overrides this to whatever preset/slider value
  was last set there; the base value here is just Omarchy's shipped
  default, kept as the fallback for a fresh install with that plugin not
  yet added), plus a Hyprland layer
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

### Floating, rounded-corner bar: published plugin, not copied here

Same pattern as the pill indicator above: started as a `charlie.bar` clone
kept in this repo, then generalized and published as its own public,
opensource plugin:

**https://github.com/Charlieras262/omarchy-floating-bar** (MIT)

Install it with `omarchy plugin add
https://github.com/Charlieras262/omarchy-floating-bar.git --enable` (which
is what `install.sh` does). It floats the bar off the screen edges with
rounded corners; the gap auto-detects from Hyprland's own
`general:gaps_out` (via `hyprctl -j getoption general:gaps_out` at
startup) so it matches the gap already used between windows, rather than
introducing a second, inconsistent gap value -- overridable per-instance
via `floatGap` in `shell.json` if you want it different from your window
gap. See that repo's README for the full option table and for **why it
needs a workaround** for `basecamp/omarchy#8007` (cloned `"kind": "bar"`
plugins failing to render) until `basecamp/omarchy#8146` ships in a stable
release.

### Rounding/blur tuning panel: published plugin, not copied here

Same pattern again: a bar-widget popup (master on/off switch, three fixed
presets, a Custom mode with rounding/blur-intensity sliders) that applies
live via `hyprctl eval` and persists to a marked block in
`~/.config/hypr/looknfeel.lua` (which is why that file's diff after
installing this plugin will show a `-- BEGIN charlieras262.omablur` /
`-- END` block -- leave it, it's meant to be there):

**https://github.com/Charlieras262/omarchy-omablur** (MIT)

Install it with `omarchy plugin add
https://github.com/Charlieras262/omarchy-omablur.git --enable` (which is
what `install.sh` does).

### Manual system-file patches these two plugins need (not automated, not in this repo)

Both `omarchy-omablur` (shell-wide opacity dimming synced to blur) and
`omarchy-floating-bar` (notifications/popups clearing the floating bar's
edge margin) need a one-time edit to a couple of Omarchy's own files under
`/usr/share/omarchy/shell/`. Neither plugin ships a script to automate this
-- doing that as root against a plugin's own git-managed, user-writable
checkout was a real security finding on the marketplace listing (the
checkout can change on every `omarchy plugin update`, turning an auto-run
`sudo` script into a code-execution path). So this is a manual step, not
something `install.sh` can do:

1. `omarchy-omablur`'s README, "Making blur actually visible" -- four
   `sudoedit` snippets (`Commons/Style.qml`, `Ui/KeyboardPanel.qml`,
   `notifications/components/NotificationCard.qml`, `plugins/menu/Menu.qml`).
2. `omarchy-floating-bar`'s README, "Known limitation" -- two `sudoedit`
   snippets (`plugins/notifications/Service.qml`, `Ui/KeyboardPanel.qml`).

An Omarchy update to any of those six files silently drops the edit --
reapply from the README if blur stops dimming the shell, or if toasts/
panels start overlapping the floating bar again.

### LUKS TPM2 auto-unlock (not in this repo -- see the skill)

The root disk unlocks itself at boot via the TPM (`clevis`), skipping the
passphrase prompt on the Plymouth "OMARCHY" screen; the manual passphrase
stays as a fallback keyslot. This is host-specific, security-sensitive state
(TPM enrollment + an mkinitcpio hook + a LUKS keyslot) that can't be copied
by `install.sh` -- it has to be re-derived per machine. See
`.claude/skills/restore-luks-tpm-autounlock/SKILL.md` for the full
procedure, the exact commands, and a PCR11-vs-PCR7 gotcha that cost a couple
of failed reboots to track down.

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
