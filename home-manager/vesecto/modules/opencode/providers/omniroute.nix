#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / / /_/ / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: vesecky@proton.me
# GitHub: veseckytomas
# GitLab: vesecky.tomas
# OmniRoute combo model entries generated from ../plugins/omniroute/chains.json.
# REQUIRE_API_KEY=false on the gateway; the SDK still needs a dummy key.
let
  chains = builtins.fromJSON (builtins.readFile ../plugins/omniroute/chains.json);
  comboModels = builtins.listToAttrs (map (c: {
      inherit (c) name;
      value = {
        inherit (c) name;
        reasoning = true;
        tool_call = true;
        attachment = true;
        modalities = {
          input = ["text" "image"];
          output = ["text"];
        };
        limit = {
          context = 1000000;
          output = 128000;
        };
        cost = {
          input = 0;
          output = 0;
        };
      };
    })
    chains.combos);
in {
  npm = "@ai-sdk/openai-compatible";
  name = "OmniRoute";
  options = {
    baseURL = "http://localhost:20128/v1";
    apiKey = "omniroute";
  };
  models = comboModels;
}
