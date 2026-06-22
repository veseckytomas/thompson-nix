#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: vesecky@proton.me
# GitHub: veseckytomas
# GitLab: vesecky.tomas

# Copyright (c) 2010 Aldo Cortesi
# Copyright (c) 2010, 2014 dequis
# Copyright (c) 2012 Randall Ma
# Copyright (c) 2012-2014 Tycho Andersen
# Copyright (c) 2012 Craig Barnes
# Copyright (c) 2013 horsik
# Copyright (c) 2013 Tao Sauvage
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import os
import platform
import re
import subprocess

import colors
from libqtile import bar, extension, hook, layout, qtile, widget
from libqtile.config import Click, Drag, Group, Key, KeyChord, Match, Screen
from libqtile.lazy import lazy
from qtile_extras import widget
from qtile_extras.widget.decorations import BorderDecoration

# Set variables
mod = "mod4"
home = os.path.expanduser("~")
terminal = "kitty"
launcher = home + "/.config/rofi/bin/launcher"
screenshot = home + "/.config/rofi/bin/screenshot"
powermenu = home + "/.config/rofi/bin/powermenu"
window = home + "/.config/rofi/bin/window"
file_manager = "thunar"
run_terminal = terminal + " -e tmux"
browser = "librewolf"
editor = terminal + " -e nvim"
music_player = "spotify"
bluetooth = "blueman-manager"
sound = "pavucontrol"
calculator = "qalculate-gtk"

# Get the backlight name
backlightdir = os.listdir("/sys/class/backlight")
if backlightdir == []:
    backlight = "intel_backlight"
else:
    backlight = backlightdir[0]

# Set widget image
distro = platform.freedesktop_os_release()["NAME"].split(" ")[0]
if distro == "Arch":
    widget_image = "~/.config/backgrounds/arch.png"
elif distro == "NixOS":
    widget_image = "~/.config/backgrounds/nixos.png"
else:
    widget_image = "~/.config/backgrounds/linux.png"

# Set machine chassis
chassis = subprocess.run(["hostnamectl", "chassis"], capture_output=True, text=True)


# A function to change keyboard layout
@lazy.function
def change_keyboard_layout(qtile):
    try:
        klayout = subprocess.check_output(
            "setxkbmap -query | awk '/^layout:/ {print $2}'", shell=True, text=True
        ).strip()
    except Exception:
        klayout = "us"

    if klayout == "cz":
        qtile.spawn("setxkbmap us")
    else:
        qtile.spawn("setxkbmap cz")


# A function for hide/show all the windows in a group
@lazy.function
def minimize_all(qtile):
    for win in qtile.current_group.windows:
        if hasattr(win, "toggle_minimize"):
            win.toggle_minimize()


# A function for toggling between MAX and MONADTALL layouts
@lazy.function
def maximize_by_switching_layout(qtile):
    current_layout_name = qtile.current_group.layout.name
    if current_layout_name == "monadtall":
        qtile.current_group.layout = "max"
    elif current_layout_name == "max":
        qtile.current_group.layout = "monadtall"


# Focus the next/previous monitor ordered by physical position.
# Qtile's built-in next_screen/prev_screen step through screens in the order the
# outputs were detected (xrandr/RandR order), which is not stable and often does
# not match how the monitors are physically arranged. Sorting by (x, y) makes
# super+. always move right and super+, always move left across the real layout.
@lazy.function
def focus_screen_in_direction(qtile, direction):
    ordered = sorted(qtile.screens, key=lambda s: (s.x, s.y))
    current = ordered.index(qtile.current_screen)
    target = ordered[(current + direction) % len(ordered)]
    qtile.focus_screen(target.index)


keys = [
    # General Keybindings
    Key([mod], "Return", lazy.spawn(run_terminal), desc="Launch terminal"),
    Key([mod], "b", lazy.spawn(browser), desc="Launch browser"),
    Key([mod], "e", lazy.spawn(editor), desc="Launch editor"),
    Key([mod], "f", lazy.spawn(file_manager), desc="Launch file manager"),
    Key([mod], "m", lazy.spawn(music_player), desc="Launch music player"),
    Key([mod], "c", lazy.spawn(calculator), desc="Launch calculator"),
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    Key([mod], "Tab", change_keyboard_layout(), desc="Toggle between keyboard layouts"),
    Key([mod, "shift"], "Return", lazy.spawn(launcher), desc="Run Launcher"),
    Key([mod, "shift"], "b", lazy.spawn(bluetooth), desc="Launch bluetooth manager"),
    Key([mod, "shift"], "r", lazy.reload_config(), desc="Restart Qtile"),
    Key([mod, "shift"], "q", lazy.spawn(powermenu), desc="Shutdown Qtile"),
    Key([mod, "shift"], "s", lazy.spawn(screenshot), desc="Take a screenshot"),
    Key([mod, "shift"], "w", lazy.spawn(window), desc="Open window switcher"),
    Key([mod, "shift"], "v", lazy.spawn(sound), desc="Launch sound manager"),
    # Change master/slave ration
    Key(
        [mod, "shift"],
        "h",
        lazy.layout.shrink_main(),
        desc="Decrease master/slave ratio",
    ),
    Key(
        [mod, "shift"], "l", lazy.layout.grow_main(), desc="Increase master/slave ratio"
    ),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down()(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    # Switch between windows
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    # Maximize/Minimize windows
    Key(
        [mod, "shift"],
        "f",
        maximize_by_switching_layout(),
        lazy.window.toggle_fullscreen(),
        desc="toggle fullscreen",
    ),
    Key(
        [mod, "control", "shift"],
        "f",
        lazy.window.toggle_floating(),
        desc="Toggle floating mode",
    ),
    Key(
        [mod, "shift"],
        "m",
        minimize_all(),
        desc="Toggle hide/show all windows on current group",
    ),
    # Switch focus of monitors (ordered left-to-right by physical position)
    Key(
        [mod],
        "period",
        focus_screen_in_direction(1),
        desc="Move focus to next monitor (right)",
    ),
    Key(
        [mod],
        "comma",
        focus_screen_in_direction(-1),
        desc="Move focus to prev monitor (left)",
    ),
    # Change brightness
    Key(
        [],
        "XF86MonBrightnessUp",
        lazy.spawn("xbacklight -inc 5"),
        desc="Increase brightness",
    ),
    Key(
        [],
        "XF86MonBrightnessDown",
        lazy.spawn("xbacklight -dec 5"),
        desc="Decrease brightness",
    ),
    Key(
        [],
        "XF86AudioLowerVolume",
        lazy.spawn("amixer sset -q Master,0 5%-"),
        desc="Decrase volume",
    ),
    Key(
        [],
        "XF86AudioRaiseVolume",
        lazy.spawn("amixer sset -q Master,0 5%+"),
        desc="Increase volume",
    ),
    Key(
        [],
        "XF86AudioMute",
        lazy.spawn("amixer sset -q Master,0 toggle"),
        desc="Mute volume",
    ),
    Key(
        [],
        "XF86Calculator",
        lazy.spawn(calculator),
        desc="Launch calculator",
    ),
    Key(
        [mod, "shift"],
        "n",
        lazy.spawn("sudo systemctl restart asus-numberpad-driver"),
        desc="Restart Asus Numberpad Driver",
    ),
]


groups = []
group_names = [
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
]

group_labels = [
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
]
# group_labels = [
#     "",
#     "",
#     "",
#     "",
#     "",
#     "6",
#     "7",
#     "8",
#     "9",
# ]

group_layouts = [
    "monadtall",
    "monadtall",
    "monadtall",
    "monadtall",
    "monadtall",
    "monadtall",
    "monadtall",
    "monadtall",
    "monadtall",
]

for i in range(len(group_names)):
    groups.append(
        Group(
            name=group_names[i],
            layout=group_layouts[i].lower(),
            label=group_labels[i],
        )
    )

for i in groups:
    keys.extend(
        [
            # mod1 + letter of group = switch to group
            Key(
                [mod],
                i.name,
                lazy.group[i.name].toscreen(),
                desc="Switch to group {}".format(i.name),
            ),
            # mod1 + shift + letter of group = move focused window to group
            Key(
                [mod, "shift"],
                i.name,
                lazy.window.togroup(i.name, switch_group=False),
                desc="Move focused window to group {}".format(i.name),
            ),
        ]
    )

# colors = colors.Dracula
colors = colors.Catppuccin

layout_theme = {
    "border_width": 2,
    "margin": 8,
    "border_focus": colors[8],
    "border_normal": colors[0],
}
layouts = [
    layout.MonadTall(**layout_theme),
]

widget_defaults = {
    "font": "Hack Nerd Font Mono",
    "fontsize": 12,
    "padding": 0,
    "background": colors[0],
}

extension_defaults = widget_defaults.copy()


# --- HiDPI bar scaling -------------------------------------------------------
# The bar size and widget font/padding sizes below are tuned for a 1080p
# monitor. On higher-resolution screens they are scaled up automatically so the
# bar stays legible. Tweak REFERENCE_HEIGHT or BASE_BAR_SIZE to taste.
REFERENCE_HEIGHT = 1080  # baseline monitor height the sizes are tuned for
BASE_BAR_SIZE = 26  # bar thickness (px) on a reference monitor


def get_monitor_heights():
    """Return the pixel height of each active monitor, in xrandr order."""
    try:
        xr = subprocess.check_output("xrandr --query", shell=True, text=True)
    except Exception:
        return [REFERENCE_HEIGHT]

    heights = []
    for line in xr.splitlines():
        if " connected" in line:
            match = re.search(r"\d+x(\d+)\+\d+\+\d+", line)
            if match:
                heights.append(int(match.group(1)))
    return heights or [REFERENCE_HEIGHT]


def bar_scale(height):
    """Scale factor for a monitor of the given height (never below 1x)."""
    return max(1.0, height / REFERENCE_HEIGHT)


def init_widgets_list(scale=1.0):
    def s(value):
        return round(value * scale)

    widgets_list = [
        widget.Image(
            filename=widget_image,
            scale="False",
            mouse_callbacks={"Button1": lambda: qtile.spawn(terminal)},
        ),
        widget.Prompt(font="Hack Nerd Font Mono", fontsize=s(14), foreground=colors[1]),
        widget.GroupBox(
            fontsize=s(11),
            margin_y=s(5),
            margin_x=s(5),
            padding_y=0,
            padding_x=s(1),
            borderwidth=s(3),
            active=colors[8],
            inactive=colors[1],
            rounded=False,
            highlight_color=colors[2],
            highlight_method="line",
            this_current_screen_border=colors[7],
            this_screen_border=colors[4],
            other_current_screen_border=colors[7],
            other_screen_border=colors[4],
        ),
        widget.TextBox(
            text="|",
            font="Hack Nerd Font Mono",
            foreground=colors[1],
            padding=s(2),
            fontsize=s(14),
        ),
        widget.WindowName(
            fontsize=s(12),
            foreground=colors[6],
            format="{state}",
        ),
        widget.CPU(
            fontsize=s(12),
            format=" Cpu: {load_percent}%",
            foreground=colors[4],
            decorations=[
                BorderDecoration(
                    colour=colors[4],
                    border_width=[0, 0, s(2), 0],
                )
            ],
        ),
        widget.Spacer(length=s(8)),
        widget.Memory(
            fontsize=s(12),
            foreground=colors[9],
            mouse_callbacks={"Button1": lambda: qtile.spawn(terminal + " -e btop")},
            format="{MemUsed: .0f}{mm}",
            fmt=" Mem:{} used",
            decorations=[
                BorderDecoration(
                    colour=colors[9],
                    border_width=[0, 0, s(2), 0],
                )
            ],
        ),
        widget.Spacer(length=s(8)),
        widget.DF(
            fontsize=s(12),
            update_interval=60,
            foreground=colors[5],
            mouse_callbacks={"Button1": lambda: qtile.spawn(terminal + " -e df -h")},
            partition="/root",
            format="{uf}{m} free",
            fmt="󱊞 Disk: {}",
            visible_on_warn=False,
            decorations=[
                BorderDecoration(
                    colour=colors[5],
                    border_width=[0, 0, s(2), 0],
                )
            ],
        ),
        widget.Spacer(length=s(8)),
        widget.KeyboardLayout(
            fontsize=s(12),
            foreground=colors[7],
            fmt="⌨ Kbd: {}",
            decorations=[
                BorderDecoration(
                    colour=colors[7],
                    border_width=[0, 0, s(2), 0],
                )
            ],
        ),
        widget.Spacer(length=s(8)),
        widget.Volume(
            fontsize=s(12),
            foreground=colors[10],
            fmt="󰕾 Vol: {}",
            decorations=[
                BorderDecoration(
                    colour=colors[10],
                    border_width=[0, 0, s(2), 0],
                )
            ],
        ),
        widget.Spacer(length=s(8)),
        widget.Battery(
            fontsize=s(12),
            foreground=colors[3],
            charge_char="󰁾󰉁",
            discharge_char="󰁿",
            full_char="󰁹",
            empty_char="󱟩",
            not_charging_char="󰁿",
            show_short_text=False,
            format="{char} Bat: {percent:2.0%}",
            decorations=[
                BorderDecoration(
                    colour=colors[3],
                    border_width=[0, 0, s(2), 0],
                )
            ],
        ),
        widget.Spacer(length=s(8)),
        widget.Backlight(
            fontsize=s(12),
            foreground=colors[6],
            backlight_name=backlight,
            format="󰃠 Brightness: {percent:2.0%}",
            decorations=[
                BorderDecoration(
                    colour=colors[6],
                    border_width=[0, 0, s(2), 0],
                ),
            ],
        ),
        widget.Spacer(length=s(8)),
        widget.Clock(
            fontsize=s(12),
            foreground=colors[8],
            format="󰥔 %a, %b %d - %H:%M",
            decorations=[
                BorderDecoration(
                    colour=colors[8],
                    border_width=[0, 0, s(2), 0],
                )
            ],
        ),
        widget.Spacer(length=s(8)),
        widget.Systray(padding=s(3), icon_size=s(20)),
        widget.Spacer(length=s(8)),
    ]
    return widgets_list


def init_widgets_screen1(scale=1.0):
    ws1 = init_widgets_list(scale)
    if "desktop" in str(chassis.stdout):
        del ws1[15:19]
    return ws1


# All other monitors' bars will display everything but widgets 24 (systray) and 25 (spacer).
def init_widgets_screen2(scale=1.0):
    ws2 = init_widgets_list(scale)
    del ws2[21:23]
    if "desktop" in str(chassis.stdout):
        del ws2[15:19]
    return ws2


def init_screens():
    # One screen per active monitor; the bar height and its widgets are scaled
    # to each monitor's resolution so the bar stays legible on HiDPI displays.
    screens = []
    for index, height in enumerate(get_monitor_heights()):
        scale = bar_scale(height)
        size = round(BASE_BAR_SIZE * scale)
        if index == 0:
            widgets = init_widgets_screen1(scale)
        else:
            widgets = init_widgets_screen2(scale)
        screens.append(Screen(top=bar.Bar(widgets=widgets, size=size)))
    return screens


if __name__ in ["config", "__main__"]:
    screens = init_screens()
    widgets_list = init_widgets_list()
    widgets_screen1 = init_widgets_screen1()
    widgets_screen2 = init_widgets_screen2()


def window_to_prev_group(qtile):
    if qtile.currentWindow is not None:
        i = qtile.groups.index(qtile.currentGroup)
        qtile.currentWindow.togroup(qtile.groups[i - 1].name)


def window_to_next_group(qtile):
    if qtile.currentWindow is not None:
        i = qtile.groups.index(qtile.currentGroup)
        qtile.currentWindow.togroup(qtile.groups[i + 1].name)


def window_to_previous_screen(qtile):
    i = qtile.screens.index(qtile.current_screen)
    if i != 0:
        group = qtile.screens[i - 1].group.name
        qtile.current_window.togroup(group)


def window_to_next_screen(qtile):
    i = qtile.screens.index(qtile.current_screen)
    if i + 1 != len(qtile.screens):
        group = qtile.screens[i + 1].group.name
        qtile.current_window.togroup(group)


def switch_screens(qtile):
    i = qtile.screens.index(qtile.current_screen)
    group = qtile.screens[i - 1].group
    qtile.current_screen.set_group(group)


mouse = [
    Drag(
        [mod],
        "Button1",
        lazy.window.set_position_floating(),
        start=lazy.window.get_position(),
    ),
    Drag(
        [mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()
    ),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
cursor_warp = True
floating_layout = layout.Floating(
    border_focus=colors[8],
    border_width=2,
    float_rules=[
        # Run the utility of `xprop` to see the wm class and name of an X client.
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),  # gitk
        Match(wm_class="dialog"),  # dialog boxes
        Match(wm_class="download"),  # downloads
        Match(wm_class="error"),  # error msgs
        Match(wm_class="file_progress"),  # file progress boxes
        Match(wm_class="makebranch"),  # gitk
        Match(wm_class="maketag"),  # gitk
        Match(wm_class="notification"),  # notifications
        Match(wm_class="pinentry-gtk-2"),  # GPG key password entry
        Match(wm_class="pinentry"),
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(wm_class="toolbar"),  # toolbars
        Match(title="branchdialog"),  # gitk
        Match(title="Confirmation"),  # tastyworks exit box
        Match(title="Qalculate!"),  # qalculate-gtk
        Match(title="pinentry"),  # GPG key password entry
    ],
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True

# If things like steam games want to auto-minimize themselves when losing
# focus, should we respect this or not?
auto_minimize = True

# When using the Wayland backend, this can be used to configure input devices.
wl_input_rules = None

# Run startup scripts on every reload
subprocess.Popen([home + "/.config/qtile/setup.sh"])


@hook.subscribe.startup_once
def start_once():
    subprocess.Popen([os.path.expanduser("~") + "/.config/qtile/autostart.sh"])


# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
# wmname = "LG3D"
