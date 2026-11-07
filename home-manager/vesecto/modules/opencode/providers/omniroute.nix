#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / / /_/ / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
# OmniRoute combo model entries generated from ../plugins/omniroute/chains.json.
# REQUIRE_API_KEY=false on the gateway; the SDK still needs a dummy key.
{lib}: let
  # Ascending cost; opencode cycles the variants in this order.
  effortOrder = ["none" "low" "medium" "high" "xhigh" "max"];
  # A bare member id resolves to no combo, so the gateway pins it with no chain fallback.
  pinnedIds = [
    "cc/claude-fable-5-1"
    "cc/claude-opus-5-5"
    "cc/claude-sonnet-5-5"
    "cc/claude-haiku-5-5"
    "litellm/kimi-k3"
    "litellm/glm-5.3"
    "ctu/vic/GLM-5.3-Flash"
    "cx/gpt-6-astra"
    "cx/gpt-6-sol"
    "cx/gpt-6-luna"
  ];
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
    or (throw "omniroute: '${m}' is in chains.json or pinnedIds but missing from model-limits.json");
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
  pinnedModels = builtins.listToAttrs (map (m: let
      inherit (limitsOf m) context output;
    in {
      name = m;
      value = {
        name = "${m} (pinned)";
        # true makes opencode force low/medium/high to the front of the variant cycle.
        reasoning = false;
        tool_call = true;
        attachment = true;
        modalities = {
          input = ["text" "image"];
          output = ["text"];
        };
        limit = {
          context =
            if context < contextCeiling
            then context
            else contextCeiling;
          inherit output;
        };
        cost = {
          input = 0;
          output = 0;
        };
        # openai-compatible forwards variant keys into the body, where the gateway reads `effort`.
        # Nix sorts attrs alphabetically, so the cycle order survives only as a DAG chain.
        variants = builtins.listToAttrs (lib.imap0 (i: e: {
            name = e;
            value =
              if i == 0
              then {effort = e;}
              else lib.hm.dag.entryAfter [(builtins.elemAt effortOrder (i - 1))] {effort = e;};
          })
          effortOrder);
      };
    })
    pinnedIds);
in {
  npm = "@ai-sdk/openai-compatible";
  name = "OmniRoute";
  options = {
    baseURL = "http://localhost:20128/v1";
    apiKey = "omniroute";
    # Both default to 300 s, exactly the gateway's hold, so a park would race the client abort.
    chunkTimeout = 600000;
    headerTimeout = 600000;
  };
  models = comboModels // pinnedModels;
}
