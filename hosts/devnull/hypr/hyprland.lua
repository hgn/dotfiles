-- Hyprland 0.57 - desktop "devnull" (Tokyo Night)
-- Host-specific: the laptop config lives in ~/.dotfiles/hosts/ic1101/hypr and is not used here.
-- Habits carried over from the GNOME session on this machine:
--   ALT+Return kitty · SUPER (tap) launcher in the island · SUPER+Return drop-down terminal
--   SUPER+E nautilus · ALT+1..4 workspaces · ALT+Tab · click to focus
-- Reference: /usr/share/hypr/hyprland.lua, https://wiki.hypr.land/configuring/

local home      = os.getenv("HOME")
local wm        = home .. "/.local/share/wm/bin/"
local terminal  = "kitty"
local launcher  = "qs ipc call shell launcher"   -- launcher inside the island
local wallpaper = home .. "/.local/share/backgrounds/2021-10-24-20-22-37-685208.jpg"

------------------
---- MONITORS ----
------------------
hl.monitor({ output = "HDMI-A-2", mode = "3840x2160@60", position = "0x0", scale = 1 })
hl.monitor({ output = "", mode = "preferred", position = "auto-right", scale = 1 })

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
-- GTK theme, icons and fonts come from the same dconf as GNOME (Materia-dark, Tela)
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
-- waybar, mako, hypridle and the polkit agent are disabled as global systemd
-- user units so they never start inside GNOME; this session starts them itself.
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        .. " HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("swaybg -m fill -i " .. wallpaper)
    -- Quickshell (~/.config/quickshell) is bar, island and notification
    -- server in one; to go back: "waybar" and "mako" instead of "qs"
    hl.exec_cmd("qs")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("/usr/libexec/hyprpolkitagent")
    -- drop-down terminal lives in the special workspace "term"
    hl.exec_cmd(terminal .. " --class dropterm -o font_size=15 -o background_opacity=0.7", { workspace = "special:term silent" })
end)

-----------------------
---- LOOK AND FEEL ----
-----------------------
hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgba(7aa2f7ff)", "rgba(bb9af7ff)", "rgba(7dcfffff)" }, angle = 45 },
            inactive_border = "rgba(41486866)",
        },
        resize_on_border = true,
        -- scrolling columns, 80 % of the 4K screen wide; the next one peeks in
        layout = "scrolling",
    },

    scrolling = {
        column_width = 0.8,
        explicit_column_widths = "0.5, 0.8, 1.0",
    },

    master = {
        mfact       = 0.55,
        new_status  = "slave",
        orientation = "left",
    },

    dwindle = { preserve_split = true, force_split = 2 },

    decoration = {
        rounding       = 12,
        rounding_power = 2.6,
        active_opacity   = 1.0,
        inactive_opacity = 0.92,

        shadow = {
            enabled        = true,
            range          = 24,
            render_power   = 3,
            offset         = { 0, 6 },
            color          = "rgba(0b0b12bb)",
            color_inactive = "rgba(0b0b1266)",
        },

        glow = {
            enabled        = true,
            range          = 12,
            render_power   = 3,
            color          = "rgba(bb9af740)",
            color_inactive = "rgba(00000000)",
        },

        blur = {
            enabled   = true,
            size      = 8,
            passes    = 3,
            noise     = 0.02,
            vibrancy  = 0.25,
            popups    = true,
        },

        -- the GNOME session ran Burn My Windows; this is the Hyprland flavour
        wobble = {
            enabled   = true,
            stiffness = 260,
            damping   = 18,
        },
    },

    animations = { enabled = true },

    misc = {
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        background_color         = "rgb(1a1b26)",
        focus_on_activate        = true,
        animate_manual_resizes   = true,
        animate_mouse_windowdragging = true,
        mouse_move_enables_dpms  = true,
        key_press_enables_dpms   = true,
        close_special_on_empty   = false,
    },
    layers = { allow_new_top_layers_over_existing_fullscreen = true },
})

hl.curve("overshot", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.08} } })
hl.curve("fluent",   { type = "bezier", points = { {0.25, 1}, {0.5, 1} } })
hl.curve("bouncy",   { type = "spring", mass = 1, stiffness = 210, damping = 19 })

hl.animation({ leaf = "windows",     enabled = true, speed = 5,   spring = "bouncy" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 5,   spring = "bouncy", style = "popin 80%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 3,   bezier = "fluent", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5,   spring = "bouncy" })
hl.animation({ leaf = "border",      enabled = true, speed = 8,   bezier = "fluent" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30,  bezier = "fluent" })
hl.animation({ leaf = "fade",        enabled = true, speed = 4,   bezier = "fluent" })
hl.animation({ leaf = "layersIn",    enabled = true, speed = 4,   bezier = "overshot", style = "popin 90%" })
hl.animation({ leaf = "layersOut",   enabled = true, speed = 2.5, bezier = "fluent",  style = "fade" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5,   bezier = "overshot", style = "slidefade 15%" })
-- drop-down terminal: drops in from the top, slides fully back up when hidden
hl.curve("easeInOut", { type = "bezier", points = { {0.65, 0}, {0.35, 1} } })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 5, bezier = "overshot",  style = "slidefadevert -40%" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 7, bezier = "easeInOut", style = "slidefadevert -100%" })

-----------------------------------
---- PER-WORKSPACE LAYOUTS --------
-----------------------------------
-- workspace 4: monocle, every window fills the screen and they are stacked;
-- ALT+Tab / ALT+SHIFT+Tab flips through them. All others stay "scrolling".
hl.workspace_rule({ workspace = "4", layout = "monocle" })

-----------------------------------
---- PER-WORKSPACE OUTLINES -------
-----------------------------------
-- One monitor, so only one workspace is ever visible: the global look is
-- swapped on every workspace change. Every theme starts from BASE, so no
-- setting leaks from one room into the next.
--   1 Fokus     distraction free: opaque, near-black terminal, unfocused windows
--               dimmed, thin static frame, no wobble, no spring, no glow
--   2 Aurora    northern lights: green-teal-violet frame and glow
--   3 Neon      synthwave: hot pink to cyan, big glow, bouncy
--   4 Glut      monocle, completely still: orange-red frame, no animations,
--               no wobble, no fade, no glow or shadow
--   5 Frost     ice glass: hairline frame, heavy blur, motion blur while moving
--   6 Phosphor  green CRT: square, hard green frame, hard offset shadow
-- Everything is static on purpose: no "loop" animations, they redraw every
-- frame and kept Hyprland at ~19 % CPU while idle. Effects only cost while
-- something actually moves.
local function grad(colors, angle) return { colors = colors, angle = angle or 45 } end
local NONE = "rgba(00000000)"

local BASE = {
    general = { gaps_in = 5, gaps_out = 10, border_size = 2,
                col = { active_border = "rgba(7aa2f7ff)", inactive_border = "rgba(41486866)" } },
    decoration = {
        rounding = 12, active_opacity = 1.0, inactive_opacity = 0.92, dim_inactive = false,
        shadow = { enabled = true, range = 24, render_power = 3, sharp = false, offset = { 0, 6 },
                   color = "rgba(0b0b12bb)", color_inactive = "rgba(0b0b1266)" },
        glow   = { enabled = false, range = 12, render_power = 3, color = NONE, color_inactive = NONE },
        -- special = true blurs the whole screen behind the drop-down terminal
        blur   = { enabled = true, variant = 0, size = 8, passes = 3, vibrancy = 0.25, special = true },
        dim_special = 0.0,
        wobble = { enabled = true, stiffness = 260, damping = 18 },
        motion_blur = { enabled = false },
    },
}

local THEMES = {
    fokus = { calm = true, cfg = {
        general = { border_size = 2,
                    col = { active_border = grad({ "rgba(7aa2f7cc)", "rgba(bb9af7cc)" }, 90),
                            inactive_border = "rgba(2a2e4299)" } },
        decoration = { rounding = 10, active_opacity = 1.0, inactive_opacity = 1.0,
                       dim_inactive = true, dim_strength = 0.45,
                       shadow = { range = 16, color = "rgba(000000cc)", color_inactive = "rgba(00000066)" },
                       wobble = { enabled = false } },
    } },
    aurora = { cfg = {
        general = { border_size = 3,
                    col = { active_border = grad({ "rgba(9ece6aff)", "rgba(73dacaff)", "rgba(7aa2f7ff)",
                                                   "rgba(bb9af7ff)", "rgba(9ece6aff)" }, 0),
                            inactive_border = "rgba(1f3a3a88)" } },
        decoration = { rounding = 16, inactive_opacity = 0.9,
                       glow = { enabled = true, range = 18,
                                color = grad({ "rgba(73daca55)", "rgba(bb9af755)", "rgba(9ece6a55)" }, 0) } },
    } },
    neon = { cfg = {
        general = { border_size = 3,
                    col = { active_border = grad({ "rgba(ff7edbff)", "rgba(bb9af7ff)", "rgba(36f9f6ff)" }, 45),
                            inactive_border = "rgba(41486866)" } },
        decoration = { rounding = 14, inactive_opacity = 0.85,
                       shadow = { range = 30, color = "rgba(ff7edb33)", color_inactive = "rgba(0b0b1266)" },
                       glow = { enabled = true, range = 22, color = "rgba(ff7edb66)" } },
    } },
    glut = { still = true, cfg = {
        -- workspace 4 (monocle): no effects at all, windows just appear and
        -- vanish: no animations, no wobble, no fading, no glow/shadow
        general = { border_size = 3,
                    col = { active_border = grad({ "rgba(ff9e64ff)", "rgba(f7768eff)", "rgba(e0af68ff)" }, 135),
                            inactive_border = "rgba(3b2a2488)" } },
        decoration = { rounding = 8, active_opacity = 1.0, inactive_opacity = 1.0,
                       shadow = { enabled = false },
                       glow = { enabled = false },
                       wobble = { enabled = false },
                       motion_blur = { enabled = false } },
    } },
    frost = { cfg = {
        general = { border_size = 1,
                    col = { active_border = grad({ "rgba(ffffffcc)", "rgba(7dcfff66)" }, 135),
                            inactive_border = "rgba(ffffff22)" } },
        decoration = { rounding = 22, active_opacity = 0.94, inactive_opacity = 0.78,
                       shadow = { range = 40, render_power = 2, offset = { 0, 12 }, color = "rgba(00000077)" },
                       glow = { enabled = true, range = 10, color = "rgba(7dcfff33)" },
                       blur = { size = 12, passes = 4, vibrancy = 0.5 },
                       motion_blur = { enabled = true, samples = 8 } },
    } },
    phosphor = { cfg = {
        general = { border_size = 2, col = { active_border = "rgba(33ff66ff)", inactive_border = "rgba(1a5c2aff)" } },
        decoration = { rounding = 0, inactive_opacity = 1.0,
                       shadow = { range = 1, render_power = 1, sharp = true, offset = { 8, 8 },
                                  color = "rgba(0f3d1cff)", color_inactive = "rgba(0a1f10aa)" },
                       glow = { enabled = true, range = 10, color = "rgba(33ff6650)" } },
    } },
}

local WS_THEME = { ["1"] = "fokus", ["2"] = "neon", ["3"] = "aurora",
                   ["4"] = "glut", ["5"] = "frost", ["6"] = "phosphor" }

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

local current_theme = nil
local function apply_theme()
    local ws = hl.get_active_workspace()
    local t = THEMES[(ws ~= nil and WS_THEME[ws.name]) or "fokus"] or THEMES.fokus
    if t == current_theme then return end
    current_theme = t
    hl.config(merge(BASE, t.cfg))

    -- motion: Glut (ws 4) is completely still, Fokus glides without
    -- overshoot, the others spring. Window animations are global, so every
    -- branch sets all of them.
    local still = t.still == true
    hl.animation({ leaf = "windowsOut",  enabled = not still, speed = 3, bezier = "fluent", style = "popin 80%" })
    hl.animation({ leaf = "fade",        enabled = not still, speed = 4, bezier = "fluent" })
    hl.animation({ leaf = "border",      enabled = not still, speed = 8, bezier = "fluent" })
    hl.animation({ leaf = "borderangle", enabled = not still, speed = 30, bezier = "fluent" })
    if still then
        hl.animation({ leaf = "windows",     enabled = false })
        hl.animation({ leaf = "windowsIn",   enabled = false })
        hl.animation({ leaf = "windowsMove", enabled = false })
    elseif t.calm then
        hl.animation({ leaf = "windows",     enabled = true, speed = 4, bezier = "fluent" })
        hl.animation({ leaf = "windowsIn",   enabled = true, speed = 4, bezier = "fluent", style = "popin 95%" })
        hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "fluent" })
    else
        hl.animation({ leaf = "windows",     enabled = true, speed = 5, spring = "bouncy" })
        hl.animation({ leaf = "windowsIn",   enabled = true, speed = 5, spring = "bouncy", style = "popin 80%" })
        hl.animation({ leaf = "windowsMove", enabled = true, speed = 5, spring = "bouncy" })
    end

end
hl.on("workspace.active", apply_theme)
apply_theme()

---------------
---- INPUT ----
---------------
-- same as GNOME here: German only, AltGr level 3, 500 ms / 33 Hz repeat,
-- focus follows clicks, not the pointer
hl.config({
    input = {
        kb_layout    = "de",
        kb_options   = "lv3:ralt_switch",
        repeat_delay = 500,
        repeat_rate  = 33,
        follow_mouse = 2,
        sensitivity  = 0.5,
    },
})

---------------------
---- KEYBINDINGS ----
---------------------
-- workspace 1 (Fokus) gets a near-black terminal, everywhere else the normal one
hl.bind("ALT + Return", function()
    local ws = hl.get_active_workspace()
    if ws ~= nil and ws.name == "1" then
        hl.exec_cmd(terminal .. " -o background=#0a0a0e -o foreground=#a9b1d6"
            .. " -o selection_background=#283457 -o active_border_color=#3b4261")
    else
        hl.exec_cmd(terminal)
    end
end)
-- SUPER+Return: drop-down terminal (scratchpad), same idea as on the laptop.
-- If it was closed, start a fresh one (it opens visible), else toggle it.
hl.bind("SUPER + Return", function()
    local running = false
    for _, w in ipairs(hl.get_windows()) do
        if w.class == "dropterm" then running = true end
    end
    if not running then
        hl.exec_cmd(terminal .. " --class dropterm -o font_size=15 -o background_opacity=0.7", { workspace = "special:term" })
    else
        hl.dispatch(hl.dsp.workspace.toggle_special("term"))
    end
end)

-- Rain on the glass: while the drop-down terminal is shown, everything behind
-- it gets the animated "drops" blur (variant 3). Animated blur redraws every
-- frame, so it runs only while the terminal is visible; hidden, the blur of
-- the current workspace theme comes back.
local RAIN = 3
local function theme_blur()
    local t = current_theme or THEMES.fokus
    return merge(BASE.decoration.blur, (t.cfg.decoration or {}).blur or {})
end
local function set_rain(on)
    if on then
        hl.config({ decoration = { blur = { variant = RAIN, size = 3, passes = 1, special = true } } })
    else
        hl.config({ decoration = { blur = theme_blur() } })
    end
end
local function term_shown()
    local sp = hl.get_active_special_workspace()
    return sp ~= nil and (sp.name == "special:term" or sp.name == "term")
end
hl.on("workspace.special_active", function()
    hl.timer(function()
        local sp = hl.get_active_special_workspace()
        local shown = term_shown()
        -- shown but empty (terminal was closed): hide the bare overlay
        if shown and sp.windows == 0 then
            hl.dispatch(hl.dsp.workspace.toggle_special("term"))
            shown = false
        end
        set_rain(shown)
    end, { timeout = 100, type = "oneshot" })
end)
hl.on("window.close", function(w)
    if w ~= nil and w.class == "dropterm" then
        set_rain(false)
        if term_shown() then hl.dispatch(hl.dsp.workspace.toggle_special("term")) end
    end
end)
-- launcher like on the laptop: tap the Windows key (on release, so SUPER
-- combos keep working), or SUPER+D
hl.bind("SUPER + Super_L", hl.dsp.exec_cmd(launcher), { release = true })
hl.bind("SUPER + D",       hl.dsp.exec_cmd(launcher))
hl.bind("SUPER + E",      hl.dsp.exec_cmd("nautilus"))

for i = 1, 9 do
    hl.bind("ALT + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind("ALT + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
-- monocle (workspace 4) only shows its top window, so the normal focus cycle
-- does not bring the next one up: there the layout itself has to flip
local function alt_tab(prev)
    return function()
        local ws = hl.get_active_workspace()
        if ws and ws.tiled_layout == "monocle" then
            hl.dispatch(hl.dsp.layout(prev and "cycleprev" or "cyclenext"))
        else
            hl.dispatch(hl.dsp.window.cycle_next(prev and { prev = true } or nil))
        end
    end
end
hl.bind("ALT + Tab",         alt_tab(false))
hl.bind("ALT + SHIFT + Tab", alt_tab(true))

hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + F", hl.dsp.window.fullscreen())
hl.bind("SUPER + M", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + P", hl.dsp.window.pin())
hl.bind("SUPER + R", hl.dsp.layout("colresize +conf"))   -- 80 % -> full -> 1/2

for _, d in ipairs({ "left", "right", "up", "down" }) do
    -- ALT+arrows like on the laptop (note: takes Alt+Left/Right "back/forward" from browsers)
    hl.bind("ALT + " .. d,           hl.dsp.focus({ direction = d }))
    hl.bind("SUPER + " .. d,         hl.dsp.focus({ direction = d }))
    hl.bind("SUPER + SHIFT + " .. d, hl.dsp.window.move({ direction = d }))
    hl.bind("SUPER + CTRL + " .. d,  hl.dsp.window.swap({ direction = d }))
end
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind("SUPER + mouse:272",  hl.dsp.window.drag(),   { mouse = true })
hl.bind("SUPER + mouse:273",  hl.dsp.window.resize(), { mouse = true })

hl.bind("SUPER + L",         hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind("SUPER + Escape",    hl.dsp.exec_cmd(wm .. "wm-power"))
hl.bind("SUPER + N",         hl.dsp.exec_cmd("qs ipc call shell dismiss"))
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("qs ipc call shell dnd"))
hl.bind("SUPER + A",         hl.dsp.exec_cmd("qs ipc call shell mixer"))
hl.bind("SUPER + SHIFT + R", hl.dsp.reload_config())
hl.bind("Print",             hl.dsp.exec_cmd(wm .. "wm-screenshot area"))
hl.bind("SHIFT + Print",     hl.dsp.exec_cmd(wm .. "wm-screenshot screen"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(wm .. "wm-osd vol-up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(wm .. "wm-osd vol-down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd(wm .. "wm-osd vol-mute"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd(wm .. "wm-osd mic-mute"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

--------------------------------
---- WINDOWS AND LAYERS --------
--------------------------------
hl.window_rule({ name = "suppress-maximize", match = { class = ".*" }, suppress_event = "maximize" })

hl.window_rule({
    name  = "dropterm",
    match = { class = "^dropterm$" },
    float = true,
    size  = "monitor_w*0.6 monitor_h*0.5",
    move  = "monitor_w*0.2 70",
})

hl.window_rule({
    name   = "float-tools",
    match  = { class = "^(org.pulseaudio.pavucontrol|blueman-manager|nm-connection-editor|org.gnome.Calculator)$" },
    float  = true,
    size   = "1100 760",
    center = true,
})

hl.window_rule({
    name   = "float-dialogs",
    match  = { title = "^(Open File|Open Folder|Save As|Datei öffnen|Speichern unter|Bild öffnen)(.*)$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name  = "pip",
    match = { title = "^(Picture-in-Picture|Picture in picture|Bild-im-Bild)$" },
    float = true,
    pin   = true,
    size  = "960 540",
    move  = "monitor_w-990 monitor_h-580",
})

hl.window_rule({
    name     = "fix-xwayland-drags",
    match    = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.layer_rule({ name = "waybar-blur", match = { namespace = "^waybar$" },        blur = true, ignore_alpha = 0.2 })
-- the shell surface is mostly transparent: blur only the glass islands
hl.layer_rule({ name = "qs-blur",     match = { namespace = "^quickshell$" },     blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ name = "fuzzel-blur", match = { namespace = "^launcher$" },      blur = true, ignore_alpha = 0.2, animation = "popin 85%" })
hl.layer_rule({ name = "mako-blur",   match = { namespace = "^notifications$" }, blur = true, ignore_alpha = 0.2, animation = "slide right" })
hl.layer_rule({ name = "wlogout",     match = { namespace = "^logout_dialog$" }, blur = true, animation = "fade" })
hl.layer_rule({ name = "qs-power",    match = { namespace = "^qs-power$" },      blur = true, animation = "fade" })
hl.layer_rule({ name = "slurp",       match = { namespace = "^selection$" },     no_anim = true })
