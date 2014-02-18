
local config_home = os.getenv("HOME")

theme = {}
theme.wallpaper_cmd = { "xsetroot -solid \"#101010\"" }

theme.font      = "terminus 11"

theme.fg_normal = "#BBBBBB"
theme.fg_focus  = "#FFFFFF"
theme.fg_urgent = "#FF0000"
theme.bg_normal = "#111111"
theme.bg_focus  = "#111111"
theme.bg_urgent = "#3F3F3F"

theme.border_width  = "1"
theme.border_normal = "#333333"
theme.border_focus  = "#111111"
theme.border_marked = "#ff3333"

theme.titlebar_bg_focus  = "#3F3F3F"
theme.titlebar_bg_normal = "#3F3F3F"

theme.menu_height = "22"
theme.menu_width  = "190"

theme.tasklist_disable_icon = true

theme.taglist_squares_sel   = "/usr/share/awesome/themes/zenburn/taglist/squarefz.png"
theme.taglist_squares_unsel = "/usr/share/awesome/themes/zenburn/taglist/squarez.png"

theme.taglist_bg_focus = "#CF6171"
theme.taglist_bg_urgent = "#466EB4"

theme.awesome_icon           = "/home/pfeifer/.config/awesome/themes/hgn/one-black-pixel.png"
theme.menu_submenu_icon      = "/usr/share/awesome/themes/default/submenu.png"
theme.tasklist_floating_icon = "/usr/share/awesome/themes/default/tasklist/floatingw.png"

theme.layout_fairh      = "/usr/share/awesome/themes/default/layouts/fairh.png"
theme.layout_fairv      = "/usr/share/awesome/themes/default/layouts/fairv.png"
theme.layout_floating   = "/usr/share/awesome/themes/default/layouts/floating.png"
theme.layout_magnifier  = "/usr/share/awesome/themes/default/layouts/magnifier.png"
theme.layout_max        = "/usr/share/awesome/themes/default/layouts/max.png"
theme.layout_fullscreen = "/usr/share/awesome/themes/default/layouts/fullscreen.png"
theme.layout_tilebottom = "/usr/share/awesome/themes/default/layouts/tilebottom.png"
theme.layout_tileleft   = "/usr/share/awesome/themes/default/layouts/tileleft.png"
theme.layout_tile       = "/usr/share/awesome/themes/default/layouts/tile.png"
theme.layout_tiletop    = "/usr/share/awesome/themes/default/layouts/tiletop.png"
theme.layout_spiral     = "/usr/share/awesome/themes/default/layouts/spiral.png"
theme.layout_dwindle    = "/usr/share/awesome/themes/default/layouts/dwindle.png"

theme.titlebar_close_button_focus  = "/usr/share/awesome/themes/zenburn/titlebar/close_focus.png"
theme.titlebar_close_button_normal = "/usr/share/awesome/themes/zenburn/titlebar/close_normal.png"

theme.titlebar_ontop_button_focus_active  = "/usr/share/awesome/themes/zenburn/titlebar/ontop_focus_active.png"
theme.titlebar_ontop_button_normal_active = "/usr/share/awesome/themes/zenburn/titlebar/ontop_normal_active.png"
theme.titlebar_ontop_button_focus_inactive  = "/usr/share/awesome/themes/zenburn/titlebar/ontop_focus_inactive.png"
theme.titlebar_ontop_button_normal_inactive = "/usr/share/awesome/themes/zenburn/titlebar/ontop_normal_inactive.png"

theme.titlebar_sticky_button_focus_active  = "/usr/share/awesome/themes/zenburn/titlebar/sticky_focus_active.png"
theme.titlebar_sticky_button_normal_active = "/usr/share/awesome/themes/zenburn/titlebar/sticky_normal_active.png"
theme.titlebar_sticky_button_focus_inactive  = "/usr/share/awesome/themes/zenburn/titlebar/sticky_focus_inactive.png"
theme.titlebar_sticky_button_normal_inactive = "/usr/share/awesome/themes/zenburn/titlebar/sticky_normal_inactive.png"

theme.titlebar_floating_button_focus_active  = "/usr/share/awesome/themes/zenburn/titlebar/floating_focus_active.png"
theme.titlebar_floating_button_normal_active = "/usr/share/awesome/themes/zenburn/titlebar/floating_normal_active.png"
theme.titlebar_floating_button_focus_inactive  = "/usr/share/awesome/themes/zenburn/titlebar/floating_focus_inactive.png"
theme.titlebar_floating_button_normal_inactive = "/usr/share/awesome/themes/zenburn/titlebar/floating_normal_inactive.png"

theme.titlebar_maximized_button_focus_active  = "/usr/share/awesome/themes/zenburn/titlebar/maximized_focus_active.png"
theme.titlebar_maximized_button_normal_active = "/usr/share/awesome/themes/zenburn/titlebar/maximized_normal_active.png"
theme.titlebar_maximized_button_focus_inactive  = "/usr/share/awesome/themes/zenburn/titlebar/maximized_focus_inactive.png"
theme.titlebar_maximized_button_normal_inactive = "/usr/share/awesome/themes/zenburn/titlebar/maximized_normal_inactive.png"

return theme
