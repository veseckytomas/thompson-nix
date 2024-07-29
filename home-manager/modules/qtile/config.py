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
file_manager = "thunar"
run_terminal = terminal + " -e tmux"
browser = "librewolf"
editor = terminal + " -e nvim"
music_player = "spotify"
bluetooth = "blueman-manager"
keyboard_layout = "us"

# Set widget image
distro = platform.freedesktop_os_release()["NAME"].split(" ")[0]
if distro == "Arch":
    widget_image = "~/.config/qtile/images/arch.png"
elif distro == "NixOS":
    widget_image = "~/.config/qtile/images/nixos.png"
else:
    widget_image = "~/.config/qtile/images/linux.png"

# Set machine chassis
chassis = subprocess.run(["hostnamectl", "chassis"], capture_output=True, text=True)


# A function to change keyboard layout
@lazy.function
def change_keyboard_layout(qtile):
    global keyboard_layout
    if keyboard_layout == "us":
        keyboard_layout = "cz"
        qtile.cmd_spawn("setxkbmap -layout cz")
    else:
        keyboard_layout = "us"
        qtile.cmd_spawn("setxkbmap -layout us")


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


keys = [
    # General Keybindings
    Key([mod], "Return", lazy.spawn(run_terminal), desc="Launch terminal"),
    Key([mod], "b", lazy.spawn(browser), desc="Launch browser"),
    Key([mod], "e", lazy.spawn(editor), desc="Launch editor"),
    Key([mod], "f", lazy.spawn(file_manager), desc="Launch file manager"),
    Key([mod], "m", lazy.spawn(music_player), desc="Launch music player"),
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    # Key(
    #     [mod, "shift"],
    #     "r",
    #     lazy.spawncmd(),
    #     desc="Spawn a command using a prompt widget",
    # ),
    Key([mod, "shift"], "Return", lazy.spawn(launcher), desc="Run Launcher"),
    Key([mod, "shift"], "b", lazy.spawn(bluetooth), desc="Launch bluetooth manager"),
    Key([mod, "shift"], "r", lazy.reload_config(), desc="Restart Qtile"),
    Key([mod, "shift"], "q", lazy.spawn(powermenu), desc="Shutdown Qtile"),
    Key([mod, "shift"], "s", lazy.spawn(screenshot), desc="Take a screenshot"),
    Key([mod, "shift"], "Tab", change_keyboard_layout(), desc="Toggle between layouts"),
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
        [mod, "shift"],
        "m",
        minimize_all(),
        desc="Toggle hide/show all windows on current group",
    ),
    # Switch focus of monitors
    Key([mod], "period", lazy.next_screen(), desc="Move focus to next monitor"),
    Key([mod], "comma", lazy.prev_screen(), desc="Move focus to prev monitor"),
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
        desc="Decrase volume",
    ),
    Key(
        [],
        "XF86AudioMute",
        lazy.spawn("amixer sset -q Master,0 toggle"),
        desc="Decrase volume",
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

colors = colors.Dracula

layout_theme = {
    "border_width": 2,
    "margin": 8,
    "border_focus": colors[8],
    "border_normal": colors[0],
}
layouts = [
    layout.MonadTall(**layout_theme),
    layout.Tile(
        shift_windows=True,
        border_width=0,
        margin=0,
        ratio=0.335,
    ),
    layout.Max(
        border_width=0,
        margin=0,
    ),
]

widget_defaults = {
    "font": "Hack Nerd Font Mono",
    "fontsize": 12,
    "padding": 0,
    "background": colors[0],
}

extension_defaults = widget_defaults.copy()


def init_widgets_list():
    widgets_list = [
        widget.Image(
            filename=widget_image,
            # filename="~/.config/qtile/images/arch.png",
            scale="False",
            mouse_callbacks={"Button1": lambda: qtile.cmd_spawn(terminal)},
        ),
        widget.Prompt(font="Hack Nerd Font Mono", fontsize=14, foreground=colors[1]),
        widget.GroupBox(
            fontsize=11,
            margin_y=5,
            margin_x=5,
            padding_y=0,
            padding_x=1,
            borderwidth=3,
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
            padding=2,
            fontsize=14,
        ),
        widget.CurrentLayoutIcon(
            # custom_icon_paths = [os.path.expanduser("~/.config/qtile/icons")],
            foreground=colors[1],
            padding=4,
            scale=0.6,
        ),
        widget.CurrentLayout(foreground=colors[1], padding=5),
        widget.TextBox(
            text="|",
            font="Hack Nerd Font Mono",
            foreground=colors[1],
            padding=2,
            fontsize=14,
        ),
        widget.WindowName(foreground=colors[6], max_chars=40),
        widget.CPU(
            format=" Cpu: {load_percent}%",
            foreground=colors[4],
            decorations=[
                BorderDecoration(
                    colour=colors[4],
                    border_width=[0, 0, 2, 0],
                )
            ],
        ),
        widget.Spacer(length=8),
        widget.Memory(
            foreground=colors[8],
            mouse_callbacks={"Button1": lambda: qtile.cmd_spawn(terminal + " -e htop")},
            format="{MemUsed: .0f}{mm}",
            fmt=" Mem:{} used",
            decorations=[
                BorderDecoration(
                    colour=colors[8],
                    border_width=[0, 0, 2, 0],
                )
            ],
        ),
        widget.Spacer(length=8),
        widget.DF(
            update_interval=60,
            foreground=colors[5],
            mouse_callbacks={"Button1": lambda: qtile.cmd_spawn(terminal + " -e df")},
            partition="/root",
            format="{uf}{m} free",
            fmt="󱊞 Disk: {}",
            visible_on_warn=False,
            decorations=[
                BorderDecoration(
                    colour=colors[5],
                    border_width=[0, 0, 2, 0],
                )
            ],
        ),
        widget.Spacer(length=8),
        widget.Volume(
            foreground=colors[7],
            fmt="󰕾 Vol: {}",
            decorations=[
                BorderDecoration(
                    colour=colors[7],
                    border_width=[0, 0, 2, 0],
                )
            ],
        ),
        widget.Spacer(length=8),
        widget.KeyboardLayout(
            foreground=colors[4],
            fmt="⌨ Kbd: {}",
            decorations=[
                BorderDecoration(
                    colour=colors[4],
                    border_width=[0, 0, 2, 0],
                )
            ],
        ),
        widget.Spacer(length=8),
        widget.Battery(
            foreground=colors[3],
            charge_char="󰁾󰉁",
            discharge_char="󰁿",
            full_char="󰁹",
            empty_char="󱟩",
            not_charging_char="󰁿",
            format="{char} Bat: {percent:2.0%}",
            decorations=[
                BorderDecoration(
                    colour=colors[3],
                    border_width=[0, 0, 2, 0],
                )
            ],
        ),
        widget.Spacer(length=8),
        widget.Backlight(
            foreground=colors[6],
            backlight_name="intel_backlight",
            format="󰃠 Brightness: {percent:2.0%}",
            decorations=[
                BorderDecoration(
                    colour=colors[6],
                    border_width=[0, 0, 2, 0],
                ),
            ],
        ),
        widget.Spacer(length=8),
        widget.Clock(
            foreground=colors[8],
            format="󰥔 %a, %b %d - %H:%M",
            decorations=[
                BorderDecoration(
                    colour=colors[8],
                    border_width=[0, 0, 2, 0],
                )
            ],
        ),
        widget.Spacer(length=8),
        widget.Systray(padding=3),
        widget.Spacer(length=8),
    ]
    return widgets_list


def init_widgets_screen1():
    ws1 = init_widgets_list()
    if "desktop" in str(chassis.stdout):
        del ws1[18:22]
    return ws1


# All other monitors' bars will display everything but widgets 24 (systray) and 25 (spacer).
def init_widgets_screen2():
    ws2 = init_widgets_list()
    del ws2[24:26]
    if "desktop" in str(chassis.stdout):
        del ws2[18:22]
    return ws2


def init_screens():
    return [
        Screen(top=bar.Bar(widgets=init_widgets_screen1(), size=26)),
        Screen(top=bar.Bar(widgets=init_widgets_screen2(), size=26)),
        Screen(top=bar.Bar(widgets=init_widgets_screen2(), size=26)),
    ]


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
cursor_warp = False
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
        Match(wm_class="ssh-askpass"),  # ssh-askpass
        Match(wm_class="toolbar"),  # toolbars
        # Match(wm_class="Yad"),  # yad boxes
        Match(title="branchdialog"),  # gitk
        Match(title="Confirmation"),  # tastyworks exit box
        # Match(title="Qalculate!"),  # qalculate-gtk
        Match(title="pinentry"),  # GPG key password entry
        # Match(title="tastycharts"),  # tastytrade pop-out charts
        # Match(title="tastytrade"),  # tastytrade pop-out side gutter
        # Match(title="tastytrade - Portfolio Report"),  # tastytrade pop-out allocation
        # Match(wm_class="tasty.javafx.launcher.LauncherFxApp"),  # tastytrade settings
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


@hook.subscribe.startup_once
def start_once():
    home = os.path.expanduser("~")
    subprocess.call([home + "/.config/qtile/autostart.sh"])


# XXX: Gasp! We're lying here. In fact, nobody really uses or cares about this
# string besides java UI toolkits; you can see several discussions on the
# mailing lists, GitHub issues, and other WM documentation that suggest setting
# this string if your java app doesn't work correctly. We may as well just lie
# and say that we're a working one by default.
#
# We choose LG3D to maximize irony: it is a 3D non-reparenting WM written in
# java that happens to be on java's whitelist.
# wmname = "LG3D"
