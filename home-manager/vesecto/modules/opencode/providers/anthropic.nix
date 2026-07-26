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
# Direct Anthropic provider models; authenticated via opencode's native OAuth token in auth.json.
{
  provider = rec {
    whitelist = builtins.attrNames models;
    models = {
      claude-opus-4-8 = {
        name = "Claude Opus 4.8";
        release_date = "2026-05-28";
        reasoning = true;
        tool_call = true;
        attachment = true;
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
        limit = {
          context = 1000000;
          output = 128000;
        };
        variants = {
          low = {
            thinking = {
              type = "adaptive";
              display = "summarized";
            };
            effort = "low";
          };
          medium = {
            thinking = {
              type = "adaptive";
              display = "summarized";
            };
            effort = "medium";
          };
          high = {
            thinking = {
              type = "adaptive";
              display = "summarized";
            };
            effort = "high";
          };
          xhigh = {
            thinking = {
              type = "adaptive";
              display = "summarized";
            };
            effort = "xhigh";
          };
          max = {
            thinking = {
              type = "adaptive";
              display = "summarized";
            };
            effort = "max";
          };
        };
      };
      claude-opus-4-7 = {
        name = "Claude Opus 4.7";
        release_date = "2026-04-16";
        reasoning = true;
        tool_call = true;
        attachment = true;
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
        limit = {
          context = 1000000;
          output = 128000;
        };
        variants = {
          low = {
            thinking = {
              type = "adaptive";
              display = "summarized";
            };
            effort = "low";
          };
          medium = {
            thinking = {
              type = "adaptive";
              display = "summarized";
            };
            effort = "medium";
          };
          high = {
            thinking = {
              type = "adaptive";
              display = "summarized";
            };
            effort = "high";
          };
          xhigh = {
            thinking = {
              type = "adaptive";
              display = "summarized";
            };
            effort = "xhigh";
          };
          max = {
            thinking = {
              type = "adaptive";
              display = "summarized";
            };
            effort = "max";
          };
        };
      };
      claude-sonnet-5 = {
        name = "Claude Sonnet 5";
        release_date = "2026-07-25";
        reasoning = true;
        tool_call = true;
        attachment = true;
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
        limit = {
          context = 1000000;
          output = 128000;
        };
        variants = {
          low = {
            thinking = {
              type = "adaptive";
            };
            effort = "low";
          };
          medium = {
            thinking = {
              type = "adaptive";
            };
            effort = "medium";
          };
          high = {
            thinking = {
              type = "adaptive";
            };
            effort = "high";
          };
          max = {
            thinking = {
              type = "adaptive";
            };
            effort = "max";
          };
        };
      };
      claude-haiku-4-5 = {
        name = "Claude Haiku 4.5";
        release_date = "2025-10-01";
        reasoning = false;
        tool_call = true;
        attachment = true;
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
        limit = {
          context = 200000;
          output = 64000;
        };
      };
    };
  };
}
