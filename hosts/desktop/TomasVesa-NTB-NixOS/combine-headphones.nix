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
  # Combined sink that fans audio out to both Bluetooth headphones at once.
  # Select "Both Headphones" as the output to use it.
  services.pipewire.extraConfig.pipewire."20-combine-headphones" = {
    "context.modules" = [
      {
        name = "libpipewire-module-combine-stream";
        args = {
          "combine.mode" = "sink";
          "node.name" = "combined_headphones";
          "node.description" = "Both Headphones";
          "combine.latency-compensate" = true;
          "combine.props" = {"audio.position" = ["FL" "FR"];};
          "stream.rules" = [
            {
              matches = [
                {"node.name" = "bluez_output.74_77_86_06_3E_13.1";}
                {"node.name" = "bluez_output.7C_F3_4D_86_6C_21.1";}
              ];
              actions.create-stream = {};
            }
          ];
        };
      }
    ];
  };
}
