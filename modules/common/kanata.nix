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
{...}: {
  services.kanata = {
    enable = true;
    keyboards.keyboard = {
      extraDefCfg = "process-unmapped-keys yes";
      config = ''
        (defsrc
          caps a s d f j k l ;
        )

        (defvar
          tap-time 200
          hold-time 200
        )

        (defalias
          mod-caps (tap-hold $tap-time $hold-time esc caps)
          mod-a (tap-hold $tap-time $hold-time a lalt)
          mod-s (tap-hold $tap-time $hold-time s lsft)
          mod-d (tap-hold $tap-time $hold-time d lctl)
          mod-f (tap-hold $tap-time $hold-time f lmet)
          mod-j (tap-hold $tap-time $hold-time j rmet)
          mod-k (tap-hold $tap-time $hold-time k rctl)
          mod-l (tap-hold $tap-time $hold-time l rsft)
          mod-; (tap-hold $tap-time $hold-time ; ralt)
        )

        (deflayer base
          @mod-caps @mod-a @mod-s @mod-d @mod-f @mod-j @mod-k @mod-l @mod-;
        )
      '';
    };
  };
}
