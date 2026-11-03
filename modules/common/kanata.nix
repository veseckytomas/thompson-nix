#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{...}: {
  services.kanata = {
    enable = true;
    keyboards.keyboard = {
      extraDefCfg = "process-unmapped-keys yes";
      config = ''
        (defsrc
          caps
        )

        (defvar
          tap-time 400
          hold-time 400
        )

        (defalias
          mod-caps (tap-hold $tap-time $hold-time esc caps)
        )

        (deflayer base
          @mod-caps
        )
      '';
    };
  };
}
