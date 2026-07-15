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
# Direct OpenAI provider models; auth handled by the opencode-openai-multi-auth plugin, so no bundled auth plugin here.
rec {
  npm = "@ai-sdk/openai";
  whitelist = builtins.attrNames models;
  models = {
    "gpt-5.5" = {
      name = "GPT-5.5";
      release_date = "2026-04-23";
      reasoning = true;
      tool_call = true;
      attachment = true;
      modalities = {
        input = ["text" "image" "pdf"];
        output = ["text"];
      };
      limit = {
        context = 1050000;
        output = 128000;
      };
      variants = {
        none = {
          reasoningEffort = "none";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
        low = {
          reasoningEffort = "low";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
        medium = {
          reasoningEffort = "medium";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
        high = {
          reasoningEffort = "high";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
        xhigh = {
          reasoningEffort = "xhigh";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
      };
    };
    "gpt-5.4-mini" = {
      name = "GPT-5.4 mini";
      release_date = "2026-03-17";
      reasoning = true;
      tool_call = true;
      attachment = true;
      modalities = {
        input = ["text" "image"];
        output = ["text"];
      };
      limit = {
        context = 400000;
        output = 128000;
      };
      variants = {
        none = {
          reasoningEffort = "none";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
        low = {
          reasoningEffort = "low";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
        medium = {
          reasoningEffort = "medium";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
        high = {
          reasoningEffort = "high";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
        xhigh = {
          reasoningEffort = "xhigh";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
      };
    };
    "gpt-5.4-mini-fast" = {
      name = "GPT-5.4 mini (fast)";
      release_date = "2026-03-17";
      reasoning = true;
      tool_call = true;
      attachment = true;
      modalities = {
        input = ["text" "image"];
        output = ["text"];
      };
      limit = {
        context = 400000;
        output = 128000;
      };
      variants = {
        none = {
          reasoningEffort = "none";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
        low = {
          reasoningEffort = "low";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
        medium = {
          reasoningEffort = "medium";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
        high = {
          reasoningEffort = "high";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
        xhigh = {
          reasoningEffort = "xhigh";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
      };
    };
    gpt-5-nano = {
      name = "GPT-5 Nano";
      release_date = "2025-08-07";
      reasoning = true;
      tool_call = true;
      attachment = true;
      modalities = {
        input = ["text" "image"];
        output = ["text"];
      };
      limit = {
        context = 400000;
        output = 128000;
      };
      variants = {
        minimal = {
          reasoningEffort = "minimal";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
        low = {
          reasoningEffort = "low";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
        medium = {
          reasoningEffort = "medium";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
        high = {
          reasoningEffort = "high";
          reasoningSummary = "auto";
          include = ["reasoning.encrypted_content"];
        };
      };
    };
  };
}
