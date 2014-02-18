
local config_home = os.getenv("HOME")

-- {{{ Main
theme = {}
-- theme.wallpaper_cmd = { "awsetbg /home/pfeifer/media/photos/2012/08-urlaub-wallis-schweiz/jpg/IMG_9745.jpg" }
theme.wallpaper_cmd = { "xsetroot -solid \"#101010\"" }
-- }}}

-- {{{ Styles
theme.font      = "terminus 11"

-- {{{ Colors
theme.fg_normal = "#BBBBBB"
theme.fg_focus  = "#FFFFFF"
theme.fg_urgent = "#FF0000"
theme.bg_normal = "#111111"
theme.bg_focus  = "#111111"
theme.bg_urgent = "#3F3F3F"
-- }}}

-- {{{ Borders
theme.border_width  = "1"
theme.border_normal = "#333333"
theme.border_focus  = "#111111"
theme.border_marked = "#ff3333"
-- }}}

-- {{{ Titlebars
theme.titlebar_bg_focus  = "#3F3F3F"
theme.titlebar_bg_normal = "#3F3F3F"
-- }}}


-- {{{ Mouse finder
theme.mouse_finder_color = "#CC9393"
-- mouse_finder_[timeout|animate_timeout|radius|factor]
-- }}}

-- {{{ Menu
-- Variables set forffffffng the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_height = "22"
theme.menu_width  = "190"
-- }}}

-- {{{ Icons
-- {{{ Taglist
theme.taglist_squares_sel   = "/usr/share/awesome/themes/zenburn/taglist/squarefz.png"
theme.taglist_squares_unsel = "/usr/share/awesome/themes/zenburn/taglist/squarez.png"
--theme.taglist_squares_resize = "false"
-- }}}

-- {{{ Misc
theme.awesome_icon           = "/home/pfeifer/.config/awesome/themes/hgn/one-black-pixel.png"
theme.menu_submenu_icon      = "/usr/share/awesome/themes/default/submenu.png"
theme.tasklist_floating_icon = "/usr/share/awesome/themes/default/tasklist/floatingw.png"
-- }}}

-- {{{ Layout
theme.layout_fairh      = config_home .. '/.config/awesome/themes/hgn/layouts/fairh.png'
theme.layout_fairv      = config_home .. '/.config/awesome/themes/hgn/layouts/fairv.png'
theme.layout_floating   = config_home .. '/.config/awesome/themes/hgn/layouts/floating.png'
theme.layout_magnifier  = config_home .. '/.config/awesome/themes/hgn/layouts/magnifier.png'
theme.layout_max        = config_home .. '/.config/awesome/themes/hgn/layouts/max.png'
theme.layout_fullscreen = config_home .. '/.config/awesome/themes/hgn/layouts/fullscreen.png'
theme.layout_tilebottom = config_home .. '/.config/awesome/themes/hgn/layouts/tilebottom.png'
theme.layout_tileleft   = config_home .. '/.config/awesome/themes/hgn/layouts/tileleft.png'
theme.layout_tile       = config_home .. '/.config/awesome/themes/hgn/layouts/tile.png'
theme.layout_tiletop    = config_home .. '/.config/awesome/themes/hgn/layouts/tiletop.png'
theme.layout_spiral     = config_home .. '/.config/awesome/themes/hgn/layouts/spiral.png'
theme.layout_dwindle    = config_home .. '/.config/awesome/themes/hgn/layouts/dwindle.png'

-- {{{ Titlebar
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
-- }}}
-- }}}

return theme
