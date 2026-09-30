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
  modelLimits = (builtins.fromJSON (builtins.readFile ../plugins/omniroute/model-limits.json)).models;
  # A priority chain can land on ANY member, so its honest window is the weakest one.
  fallback = {
    context = 128000;
    output = 32768;
  };
  # Capped below every member's real window: attention degrades long before 1M.
  contextCeiling = 250000;
  # Fail loudly: a silent fallback would advertise a wrong window for a typo'd id.
  limitsOf = m:
    modelLimits.${m}
    or (throw "omniroute: '${m}' is in chains.json but missing from model-limits.json");
  floorOf = c: field: let
    vals = map (m: (limitsOf m).${field}) c.models;
  in
    if vals == []
    then fallback.${field}
    else
      builtins.foldl' (a: b:
        if a < b
        then a
        else b) (builtins.head vals)
      vals;
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
          context = let
            f = floorOf c "context";
          in
            if f < contextCeiling
            then f
            else contextCeiling;
          output = floorOf c "output";
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
