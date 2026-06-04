local hl = require("hyprland")

-- ============================================================
-- CORE SETUP
-- ============================================================

local mainMod = "SUPER"

-- Autostart
hl.exec_once("hyprpaper")
hl.exec_once("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
hl.exec_once("waybar")
hl.exec_once("dunst")
hl.exec_once("hypridle")
hl.exec_once("nm-applet --indicator")

-- ============================================================
-- MONITOR
-- ============================================================

-- Auto-detect your monitor. If you know your monitor name, replace "," with
-- "eDP-1," or "HDMI-A-1," etc. Run `hyprctl monitors` to find the name.
hl.monitor({ name = "", resolution = "preferred", position = "auto", scale = 1 })

-- ============================================================
-- ENVIRONMENT VARIABLES
-- ============================================================

hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("GDK_BACKEND", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- ============================================================
-- LOOK AND FEEL — CATPPUCCIN MOCHA
-- ============================================================

-- Colors
local mocha = {
  base    = "0xff1e1e2e",
  mantle  = "0xff181825",
  crust   = "0xff11111b",
  surface0 = "0xff313244",
  surface1 = "0xff45475a",
  overlay0 = "0xff6c7086",
  text    = "0xffcdd6f4",
  lavender = "0xffb4befe",
  blue    = "0xff89b4fa",
  mauve   = "0xffcba6f7",
  pink    = "0xfff38ba8",
  sapphire = "0xff74c7ec",
}

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,
    border_size = 2,
    ["col.active_border"] = mocha.lavender .. " " .. mocha.mauve .. " 45deg",
    ["col.inactive_border"] = mocha.surface0,
    layout = "scrolling",   -- default layout on startup
    resize_on_border = true,
    allow_tearing = false,
  },

  decoration = {
    rounding = 10,
    active_opacity = 1.0,
    inactive_opacity = 0.95,
    blur = {
      enabled = true,
      size = 4,
      passes = 2,
      vibrancy = 0.1696,
    },
    shadow = {
      enabled = true,
      range = 12,
      render_power = 3,
      color = "0xee000000",
    },
  },

  animations = {
    enabled = true,
    bezier = {
      { name = "easeOut",    x1 = 0.05, y1 = 0.9,  x2 = 0.1,  y2 = 1.05 },
      { name = "easeIn",     x1 = 0.4,  y1 = 0,    x2 = 0.6,  y2 = 1    },
      { name = "linear",     x1 = 0,    y1 = 0,    x2 = 1,    y2 = 1    },
    },
    animation = {
      { name = "windows",    enable = true, speed = 4,  curve = "easeOut", style = "slide" },
      { name = "windowsOut", enable = true, speed = 4,  curve = "easeIn",  style = "slide" },
      { name = "border",     enable = true, speed = 5,  curve = "linear"   },
      { name = "workspaces", enable = true, speed = 5,  curve = "easeOut", style = "slide" },
    },
  },

  input = {
    kb_layout = "us",
    follow_mouse = 1,
    sensitivity = 0,
    touchpad = {
      natural_scroll = true,
      disable_while_typing = true,
      tap_to_click = true,
    },
  },

  gestures = {
    workspace_swipe = true,
    workspace_swipe_fingers = 3,
  },

  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    mouse_move_enables_dpms = true,
    key_press_enables_dpms = true,
    focus_on_activate = true,
  },

  master = {
    new_status = "slave",
    mfact = 0.55,
  },

  scrolling = {
    -- default column width as fraction of screen
    default_column_width = 0.5,
  },
})

-- ============================================================
-- LAYOUT TOGGLE — MONOCLE ↔ SCROLLING
-- ============================================================

-- Track current layout per workspace
local workspace_layouts = {}

local function toggle_layout()
  local ws = hl.get_active_workspace()
  local current = workspace_layouts[ws.id] or "scrolling"
  local next_layout

  if current == "scrolling" then
    next_layout = "monocle"
  else
    next_layout = "scrolling"
  end

  workspace_layouts[ws.id] = next_layout
  hl.dispatch(hl.dsp.workspace({ layout = next_layout }))
end

-- ============================================================
-- WORKSPACES
-- ============================================================

-- 9 workspaces, all start with scrolling layout
for i = 1, 9 do
  hl.workspace_rule({ workspace = tostring(i), layout = "scrolling" })
end

-- ============================================================
-- WINDOW RULES
-- ============================================================

-- Float these apps
hl.window_rule({ match = { class = "pavucontrol" },       float = true })
hl.window_rule({ match = { class = "nm-connection-editor" }, float = true })
hl.window_rule({ match = { class = "blueman-manager" },   float = true })
hl.window_rule({ match = { title = "Picture-in-Picture" }, float = true, pin = true })

-- Slight transparency for terminals
hl.window_rule({ match = { class = "kitty" }, opacity = { active = 0.97, inactive = 0.90 } })

-- ============================================================
-- KEYBINDINGS
-- ============================================================

-- Apps
hl.bind(mainMod .. " + Return", hl.dsp.exec("kitty"))
hl.bind(mainMod .. " + Space",  hl.dsp.exec("wofi --show drun"))
hl.bind(mainMod .. " + E",      hl.dsp.exec("thunar"))
hl.bind(mainMod .. " + B",      hl.dsp.exec("firefox"))

-- Layout toggle — Super + M = toggle monocle/scrolling on current workspace
hl.bind(mainMod .. " + M", toggle_layout)

-- Window management
hl.bind(mainMod .. " + Q",            hl.dsp.window.close())
hl.bind(mainMod .. " + F",            hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + V",            hl.dsp.window.toggle_float())
hl.bind(mainMod .. " + P",            hl.dsp.window.pin())

-- Alt+Tab — cycle windows exactly like Windows
hl.bind("ALT + Tab",       hl.dsp.window.cycle_next({ next = true,  tiled = true }))
hl.bind("ALT SHIFT + Tab", hl.dsp.window.cycle_next({ next = false, tiled = true }))

-- Focus with arrow keys or vim keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down"  }))
hl.bind(mainMod .. " + h",     hl.dsp.focus({ direction = "left"  }))
hl.bind(mainMod .. " + l",     hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + k",     hl.dsp.focus({ direction = "up"    }))
hl.bind(mainMod .. " + j",     hl.dsp.focus({ direction = "down"  }))

-- Move windows
hl.bind(mainMod .. " SHIFT + left",  hl.dsp.window.move({ direction = "left"  }))
hl.bind(mainMod .. " SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " SHIFT + up",    hl.dsp.window.move({ direction = "up"    }))
hl.bind(mainMod .. " SHIFT + down",  hl.dsp.window.move({ direction = "down"  }))

-- Resize windows with Super + Right Click drag or arrow keys in resize mode
hl.bind(mainMod .. " CTRL + left",  hl.dsp.window.resize({ x = -40, y = 0   }))
hl.bind(mainMod .. " CTRL + right", hl.dsp.window.resize({ x =  40, y = 0   }))
hl.bind(mainMod .. " CTRL + up",    hl.dsp.window.resize({ x = 0,   y = -40 }))
hl.bind(mainMod .. " CTRL + down",  hl.dsp.window.resize({ x = 0,   y =  40 }))

-- Scrolling layout navigation (move between columns)
hl.bind(mainMod .. " + period", hl.dsp.layout("move +col"))
hl.bind(mainMod .. " + comma",  hl.dsp.layout("swapcol l"))

-- Workspaces 1–9
for i = 1, 9 do
  hl.bind(mainMod ..          " + " .. i, hl.dsp.workspace({ id = i              }))
  hl.bind(mainMod .. " SHIFT + " .. i,    hl.dsp.window.move_to_workspace({ id = i }))
end

-- Scroll through workspaces with mouse wheel on bar
hl.bind(mainMod .. " + mouse_down", hl.dsp.workspace({ relative = 1  }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.workspace({ relative = -1 }))

-- Move/resize windows with mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.begin_move())
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.begin_resize())

-- Screenshot
hl.bind("NONE + Print",       hl.dsp.exec("grim ~/Pictures/screenshot-$(date +%F_%T).png"))
hl.bind(mainMod .. " + Print", hl.dsp.exec("grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%F_%T).png"))

-- Lock screen
hl.bind(mainMod .. " + L", hl.dsp.exec("hyprlock"))

-- Reload config
hl.bind(mainMod .. " SHIFT + R", hl.dsp.reload())

-- Exit Hyprland
hl.bind(mainMod .. " SHIFT + E", hl.dsp.exit())

-- Media keys
hl.bind("NONE + XF86AudioRaiseVolume",  hl.dsp.exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bind("NONE + XF86AudioLowerVolume",  hl.dsp.exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bind("NONE + XF86AudioMute",         hl.dsp.exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("NONE + XF86AudioPlay",         hl.dsp.exec("playerctl play-pause"))
hl.bind("NONE + XF86AudioNext",         hl.dsp.exec("playerctl next"))
hl.bind("NONE + XF86AudioPrev",         hl.dsp.exec("playerctl previous"))
hl.bind("NONE + XF86MonBrightnessUp",   hl.dsp.exec("brightnessctl set 5%+"))
hl.bind("NONE + XF86MonBrightnessDown", hl.dsp.exec("brightnessctl set 5%-"))