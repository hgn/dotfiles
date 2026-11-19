-- Hyprland 0.57 - Tokyo Night
-- ALT+Return terminal · ALT+1..0 workspaces · SUPER (tap) launcher
-- Reference: /usr/share/hypr/hyprland.lua, https://wiki.hypr.land/configuring/

local home     = os.getenv("HOME")
local wm       = home .. "/.local/share/wm/bin/"
local terminal = "alacritty --config-file " .. home .. "/.config/alacritty/wm.toml"
local menu     = "pkill -x fuzzel || fuzzel"

------------------
---- MONITORS ----
------------------
-- laptop panel native, scale 1.0
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1 })
-- anything else (beamer, HDMI, USB-C/DP): mirror the laptop panel
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1, mirror = "eDP-1" })

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("swaybg -m fill -i " .. home .. "/.local/share/wm/wallpaper")
    hl.exec_cmd("waybar -c " .. home .. "/.config/waybar/config-hyprland.jsonc")
    hl.exec_cmd("mako")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("/usr/libexec/polkit-mate-authentication-agent-1")
    -- drop-down terminal lives in the special workspace "term"
    hl.exec_cmd(terminal .. " --class dropterm -o font.size=15 -o window.opacity=0.7", { workspace = "special:term silent" })
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 5,
        border_size = 3,
        col = {
            active_border   = { colors = { "rgba(7aa2f7ff)", "rgba(bb9af7ff)", "rgba(7dcfffff)" }, angle = 45 },
            inactive_border = "rgba(41486866)",
        },
        resize_on_border = true,
        layout = "scrolling",   -- niri-like columns everywhere, workspace 4 = monocle
    },

    -- master layout: one big window left (60%), the rest stacked right
    master = {
        mfact      = 0.6,
        new_status = "slave",
        orientation = "left",
    },

    -- scrolling layout (default): new columns 90% of the screen wide
    scrolling = {
        column_width = 0.9,
        explicit_column_widths = "0.5, 0.9, 1.0",
    },

    decoration = {
        rounding       = 14,
        rounding_power = 2.6,
        active_opacity   = 1.0,
        inactive_opacity = 0.88,
        dim_special      = 0.0,

        shadow = {
            enabled        = true,
            range          = 28,
            render_power   = 3,
            offset         = { 0, 6 },
            color          = "rgba(0b0b12bb)",
            color_inactive = "rgba(0b0b1266)",
        },

        glow = {
            enabled        = true,
            range          = 14,
            render_power   = 3,
            color          = "rgba(bb9af740)",
            color_inactive = "rgba(00000000)",
        },

        blur = {
            enabled   = true,
            size      = 8,
            passes    = 3,
            noise     = 0.02,
            contrast  = 1.0,
            brightness = 0.9,
            vibrancy  = 0.25,
            vibrancy_darkness = 0.2,
            popups    = true,
            special   = true,
        },

        -- jelly windows while dragging (compiz says hi)
        wobble = {
            enabled   = true,
            stiffness = 260,
            damping   = 18,
        },
    },

    animations = { enabled = true },
})

hl.curve("smoothOut", { type = "bezier", points = { {0.36, 0}, {0.66, -0.56} } })
hl.curve("overshot",  { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.08} } })
hl.curve("fluent",    { type = "bezier", points = { {0.25, 1}, {0.5, 1} } })
hl.curve("linear",    { type = "bezier", points = { {0, 0}, {1, 1} } })
hl.curve("bouncy",    { type = "spring", mass = 1, stiffness = 210, damping = 19 })
hl.curve("easeInOut", { type = "bezier", points = { {0.65, 0}, {0.35, 1} } })

hl.animation({ leaf = "windows",       enabled = true, speed = 5,   spring = "bouncy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 5,   spring = "bouncy", style = "popin 80%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 3,   bezier = "fluent", style = "popin 80%" })
hl.animation({ leaf = "windowsMove",   enabled = true, speed = 5,   spring = "bouncy" })
hl.animation({ leaf = "border",        enabled = true, speed = 8,   bezier = "fluent" })
-- no "loop": a permanently rotating gradient forces a redraw every frame (~10% CPU idle, battery)
hl.animation({ leaf = "borderangle",   enabled = true, speed = 30,  bezier = "fluent" })
hl.animation({ leaf = "fade",          enabled = true, speed = 4,   bezier = "fluent" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,   bezier = "overshot", style = "popin 90%" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 2.5, bezier = "fluent",  style = "fade" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 5,   bezier = "overshot", style = "slidefade 15%" })
-- drop-down terminal: drops in from the top, slides fully back up when hidden
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 5, bezier = "overshot", style = "slidefadevert -40%" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 7, bezier = "easeInOut", style = "slidefadevert -100%" })

hl.config({
    dwindle = { preserve_split = true, force_split = 2 },  -- new windows always to the right/bottom
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        disable_splash_rendering = true,
        background_color        = "rgb(1a1b26)",
        focus_on_activate       = true,
        animate_manual_resizes  = true,
        animate_mouse_windowdragging = true,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,
        close_special_on_empty  = false,
    },
    layers = { allow_new_top_layers_over_existing_fullscreen = true },
})

---------------
---- INPUT ----
---------------
hl.config({
    input = {
        kb_layout  = "de,us",
        kb_variant = ",altgr-intl",
        kb_options = "lv3:ralt_switch,grp:shifts_toggle",
        repeat_delay = 500,
        repeat_rate  = 33,
        follow_mouse = 1,
        sensitivity  = 0.06,
        touchpad = {
            natural_scroll       = true,
            tap_to_click         = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
        },
    },
})

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-----------------------------------
---- PER-WORKSPACE THEMES ---------
-----------------------------------
-- Every workspace is its own "room". Only one workspace is visible at a time
-- (beamer mirrors), so the global look is switched on workspace change.
-- term = alacritty colors for ALT+Return: ~/.config/alacritty/ws-<term>.toml
local GRAD_NEON  = { colors = { "rgba(ff7edbff)", "rgba(bb9af7ff)", "rgba(36f9f6ff)" }, angle = 45 }

local BASE = {
    general = { gaps_in = 3, gaps_out = 5, border_size = 0,
                col = { active_border = "rgba(00000000)", inactive_border = "rgba(00000000)" } },
    decoration = {
        rounding = 12, active_opacity = 1.0, inactive_opacity = 0.95,
        dim_inactive = false, dim_strength = 0.2,
        shadow = { enabled = true, range = 18, render_power = 3, offset = { 0, 4 }, sharp = false,
                   color = "rgba(000000aa)", color_inactive = "rgba(00000055)" },
        glow   = { enabled = false, range = 14, color = "rgba(00000000)", color_inactive = "rgba(00000000)" },
        blur   = { enabled = true, variant = 0, size = 8, passes = 3, vibrancy = 0.25 },
        wobble = { enabled = true },
    },
}

local THEMES = {
    -- 1 ink: minimal and dark, nothing but the content
    ink = { term = "ink", calm = true, cfg = { decoration = { wobble = { enabled = false } } } },
    -- 2 rose: Rosé Pine Moon, muted and warm, soft rose -> iris frame, round
    rose = { term = "rose", cfg = {
        general = { border_size = 2, col = { active_border = { colors = { "rgba(ea9a97ff)", "rgba(c4a7e7ff)" }, angle = 135 },
                                             inactive_border = "rgba(393552aa)" } },
        decoration = { rounding = 16, inactive_opacity = 0.92,
                       shadow = { range = 26, offset = { 0, 6 }, color = "rgba(1a1826aa)", color_inactive = "rgba(1a182655)" },
                       glow = { enabled = true, range = 10, color = "rgba(ea9a9733)" } },
    } },
    -- 3 synthwave: neon gradient, glow, glass
    synth = { term = "synth", cfg = {
        general = { border_size = 3, col = { active_border = GRAD_NEON, inactive_border = "rgba(41486866)" } },
        decoration = { rounding = 14, inactive_opacity = 0.85,
                       shadow = { range = 28, offset = { 0, 6 }, color = "rgba(0b0b12bb)", color_inactive = "rgba(0b0b1266)" },
                       glow = { enabled = true, range = 16, color = "rgba(ff7edb55)" } },
    } },
    -- 4 zen (monocle): edge to edge, no chrome at all
    zen = { term = "ink", cfg = {
        general = { gaps_in = 0, gaps_out = 0 },
        decoration = { rounding = 0, inactive_opacity = 1.0, shadow = { enabled = false } },
    } },
    -- 6 phosphor: green VT terminal, square, green frame and glow
    -- (no CRT screen_shader: switching it from a keybind froze the keyboard
    --  and crashed Hyprland 0.57 on 2026-11-19)
    phosphor = { term = "phosphor", hide_bar = true, calm = true, cfg = {
        general = { border_size = 2, col = { active_border = "rgba(33ff66ff)", inactive_border = "rgba(1a5c2aff)" } },
        decoration = { rounding = 0, inactive_opacity = 1.0,
                       shadow = { enabled = false },
                       glow = { enabled = true, range = 12, color = "rgba(33ff6650)" } },
    } },
    -- 5 glass: scrolling, no bar, edge to edge, no borders, fully opaque,
    -- standard alacritty colors (wm.toml) without transparency
    glass = { term = nil, term_opts = "-o window.opacity=1.0", calm = true, hide_bar = true, cfg = {
        general = { gaps_in = 0, gaps_out = 0, border_size = 0 },
        decoration = { rounding = 0, active_opacity = 1.0, inactive_opacity = 1.0,
                       shadow = { enabled = false },
                       -- plain kawase blur; "acrylic" is a lens with a 48px bulged edge
                       -- that visibly pulls the content inwards
                       blur = { variant = 0, size = 10, passes = 4, vibrancy = 0.45 } },
    } },
    -- 7 brutalist: gruvbox, thick ochre frame, hard offset shadow, no curves
    brutal = { term = "gruvbox", cfg = {
        general = { gaps_in = 6, gaps_out = 12, border_size = 4,
                    col = { active_border = "rgba(d79921ff)", inactive_border = "rgba(504945ff)" } },
        decoration = { rounding = 0, inactive_opacity = 1.0,
                       shadow = { range = 1, render_power = 1, sharp = true, offset = { 10, 10 },
                                  color = "rgba(000000ff)", color_inactive = "rgba(000000aa)" } },
    } },
}

WS_THEME = { ["1"] = "ink", ["2"] = "rose", ["3"] = "synth", ["4"] = "zen",
             ["5"] = "glass", ["6"] = "phosphor", ["7"] = "brutal" }
local DEFAULT_THEME = "ink"

local function merge(a, b)
    local r = {}
    for k, v in pairs(a) do r[k] = v end
    for k, v in pairs(b) do
        if type(v) == "table" and type(r[k]) == "table" and v.colors == nil and #v == 0 then
            r[k] = merge(r[k], v)
        else
            r[k] = v
        end
    end
    return r
end

CURRENT_THEME = nil
local function theme_for(ws)
    return THEMES[(ws ~= nil and WS_THEME[ws.name]) or DEFAULT_THEME] or THEMES[DEFAULT_THEME]
end
local function apply_theme(manage_bar)
    local t = theme_for(hl.get_active_workspace())
    if t == CURRENT_THEME then return end
    CURRENT_THEME = t
    hl.config(merge(BASE, t.cfg))
    -- calm themes: windows glide without the springy overshoot
    if t.calm then
        hl.animation({ leaf = "windows",     enabled = true, speed = 4, bezier = "fluent" })
        hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "fluent" })
    else
        hl.animation({ leaf = "windows",     enabled = true, speed = 5, spring = "bouncy" })
        hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, spring = "bouncy" })
    end
    -- themes with hide_bar run without waybar (stopped/started, so the
    -- state can never get out of sync like a SIGUSR1 toggle could)
    if not manage_bar then return end   -- config load: autostart owns waybar
    if t.hide_bar then
        hl.exec_cmd("pkill -x waybar")
    else
        hl.exec_cmd("pgrep -x waybar >/dev/null || waybar -c " .. home .. "/.config/waybar/config-hyprland.jsonc")
    end
end
hl.on("workspace.active", function() apply_theme(true) end)
apply_theme(false)

-- blur of the current theme (used to restore after the drop-down effect)
function theme_blur()
    local t = CURRENT_THEME or THEMES[DEFAULT_THEME]
    return merge(BASE.decoration.blur, (t.cfg.decoration or {}).blur or {})
end

-- ALT+Return: terminal in the colors of the current workspace
local function spawn_terminal()
    local t = theme_for(hl.get_active_workspace())
    if t.term == nil then
        hl.exec_cmd(terminal .. " " .. (t.term_opts or ""))   -- standard look (wm.toml)
    else
        hl.exec_cmd("alacritty --config-file " .. home .. "/.config/alacritty/ws-" .. t.term .. ".toml")
    end
end

---------------------
---- KEYBINDINGS ----
---------------------
-- Terminal + workspaces on ALT (your habit)
hl.bind("ALT + Return", spawn_terminal)
for i = 1, 10 do
    local key = i % 10
    hl.bind("ALT + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind("ALT + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end
-- Alt+Tab: monocle workspaces need the layout's own cycling (cycle_next
-- only sees the visible window there)
MONOCLE = { ["4"] = true }
local function alt_tab(dir)
    local ws = hl.get_active_workspace()
    if ws ~= nil and MONOCLE[ws.name] then
        hl.dispatch(hl.dsp.layout(dir == "prev" and "cycleprev" or "cyclenext"))
    else
        hl.dispatch(dir == "prev" and hl.dsp.window.cycle_next({ prev = true }) or hl.dsp.window.cycle_next())
    end
end
hl.bind("ALT + Tab",         function() alt_tab("next") end)
hl.bind("ALT + SHIFT + Tab", function() alt_tab("prev") end)

-- Launcher: tap the Windows key
hl.bind("SUPER + Super_L", hl.dsp.exec_cmd(menu), { release = true })
hl.bind("SUPER + D",       hl.dsp.exec_cmd(menu))

-- Window management on SUPER
hl.bind("SUPER + Q",      hl.dsp.window.close())
hl.bind("SUPER + F",      hl.dsp.window.fullscreen())
hl.bind("SUPER + M",      hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind("SUPER + V",      hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + P",      hl.dsp.window.pin())
hl.bind("SUPER + J",      hl.dsp.layout("swapwithmaster"))     -- active window <-> master
hl.bind("SUPER + O",      hl.dsp.layout("orientationnext"))    -- master left/top/right/bottom/center
hl.bind("SUPER + R",      hl.dsp.layout("colresize +conf"))    -- scrolling: column width 0.9 (start) → full → 1/2

-- Alt+arrows navigate on the scrolling workspaces; on the monocle ones the
-- binds are disabled so apps keep them (Firefox back/forward)
local alt_nav = {}
for _, d in ipairs({ "left", "right", "up", "down" }) do
    alt_nav[#alt_nav + 1] = hl.bind("ALT + " .. d, hl.dsp.focus({ direction = d }))
end
local function update_alt_nav()
    local ws = hl.get_active_workspace()
    local on = ws ~= nil and not MONOCLE[ws.name]
    for _, b in ipairs(alt_nav) do b:set_enabled(on) end
end
hl.on("workspace.active", update_alt_nav)
update_alt_nav()
for _, d in ipairs({ "left", "right", "up", "down" }) do
    hl.bind("SUPER + " .. d,         hl.dsp.focus({ direction = d }))
    hl.bind("SUPER + SHIFT + " .. d, hl.dsp.window.move({ direction = d }))
    hl.bind("SUPER + CTRL + " .. d,  hl.dsp.window.swap({ direction = d }))
end
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind("SUPER + mouse:273",  hl.dsp.window.resize(), { mouse = true })

-- Drop-down terminal (scratchpad)
-- if the terminal was closed, start a fresh one (it opens visible), else toggle
hl.bind("SUPER + Return", function()
    local running = false
    for _, w in ipairs(hl.get_windows()) do
        if w.class == "dropterm" then running = true end
    end
    if not running then
        hl.exec_cmd(terminal .. " --class dropterm -o font.size=15 -o window.opacity=0.7", { workspace = "special:term" })
    else
        hl.dispatch(hl.dsp.workspace.toggle_special("term"))
    end
end)

-- Water-drops blur (beads running down the glass) only while the drop-down terminal is shown.
-- Blur variants are global in Hyprland, and animated ones redraw every frame,
-- so switch it on/off with the special workspace.
-- variant 3 = drops, 5 = fluid_jar, 6 = crystal pattern (verified by screenshot;
-- numbering is not the stub order)
local SHIMMER = 3
-- while shown: drops effect + light blur so the desktop behind stays recognizable;
-- hidden: back to the blur of the current workspace theme
local function set_shimmer(on)
    if on then
        hl.config({ decoration = { blur = { variant = SHIMMER, size = 3, passes = 1 } } })
    else
        hl.config({ decoration = { blur = theme_blur() } })
    end
end
local function term_shown()
    local sp = hl.get_active_special_workspace()
    return sp ~= nil and (sp.name == "special:term" or sp.name == "term")
end
-- toggled via Super+Return: follow the special workspace state
hl.on("workspace.special_active", function()
    hl.timer(function()
        local sp = hl.get_active_special_workspace()
        local shown = term_shown()
        -- shown but empty (terminal was closed): hide the bare blur overlay
        if shown and sp.windows == 0 then
            hl.dispatch(hl.dsp.workspace.toggle_special("term"))
            shown = false
        end
        set_shimmer(shown)
    end, { timeout = 100, type = "oneshot" })
end)
-- terminal closed (Super+Q / exit): effect off and hide the empty overlay
hl.on("window.close", function(w)
    if w ~= nil and w.class == "dropterm" then
        set_shimmer(false)
        if term_shown() then hl.dispatch(hl.dsp.workspace.toggle_special("term")) end
    end
end)

-- Session / tools
hl.bind("SUPER + L",       hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind("SUPER + Escape",  hl.dsp.exec_cmd(wm .. "wm-power"))
hl.bind("SUPER + W",       hl.dsp.exec_cmd(wm .. "wm-wifi"))
hl.bind("SUPER + E",       hl.dsp.exec_cmd("nautilus"))
hl.bind("SUPER + N",       hl.dsp.exec_cmd("makoctl dismiss -a"))
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("makoctl restore"))
hl.bind("SUPER + SHIFT + R", hl.dsp.reload_config())
hl.bind("Print",           hl.dsp.exec_cmd(wm .. "wm-screenshot area"))
hl.bind("SHIFT + Print",   hl.dsp.exec_cmd(wm .. "wm-screenshot screen"))

-- Function keys: volume, mic, brightness (with OSD), media
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd(wm .. "wm-osd vol-up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd(wm .. "wm-osd vol-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd(wm .. "wm-osd vol-mute"), { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd(wm .. "wm-osd mic-mute"), { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(wm .. "wm-osd bri-up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(wm .. "wm-osd bri-down"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- monocle on workspace 4: every window full size, stacked;
-- Alt+Tab flips through them. All other workspaces use scrolling.
for ws in pairs(MONOCLE) do
    hl.workspace_rule({ workspace = ws, layout = "monocle" })
end

--------------------------------
---- WINDOWS AND LAYERS --------
--------------------------------
hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })

hl.window_rule({
    name  = "dropterm",
    match = { class = "^dropterm$" },
    float = true,
    size  = "monitor_w*0.7 monitor_h*0.55",
    move  = "monitor_w*0.15 60",
})

-- feh (XWayland) asks for fullscreen in a way Hyprland ignores: always fullscreen it
hl.window_rule({
    name       = "feh-fullscreen",
    match      = { class = "^feh$" },
    fullscreen = true,
})

hl.window_rule({
    name  = "float-tools",
    match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor|org.gnome.Calculator)$" },
    float = true,
    size  = "900 620",
    center = true,
})

hl.window_rule({
    name  = "float-dialogs",
    match = { title = "^(Open File|Open Folder|Save As|Datei öffnen|Speichern unter|Bild öffnen)(.*)$" },
    float = true,
    center = true,
})

hl.window_rule({
    name  = "firefox-pip",
    match = { title = "^(Picture-in-Picture|Bild-im-Bild)$" },
    float = true,
    pin   = true,
    size  = "640 360",
    move  = "monitor_w-660 monitor_h-380",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- glass behind bar, launcher and notifications
hl.layer_rule({ name = "waybar-blur", match = { namespace = "^waybar$" },        blur = true, ignore_alpha = 0.2 })
hl.layer_rule({ name = "fuzzel-blur", match = { namespace = "^launcher$" },      blur = true, ignore_alpha = 0.2, animation = "popin 85%" })
hl.layer_rule({ name = "mako-blur",   match = { namespace = "^notifications$" }, blur = true, ignore_alpha = 0.2, animation = "slide right" })
hl.layer_rule({ name = "wlogout",     match = { namespace = "^logout_dialog$" }, blur = true, animation = "fade" })
hl.layer_rule({ name = "slurp",       match = { namespace = "^selection$" },     no_anim = true })
