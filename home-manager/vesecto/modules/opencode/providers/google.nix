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
# Gemini + Claude on the AI Pro subscription via opencode-antigravity-auth. Models route to Google's Antigravity backend (gemini-cli individual OAuth was removed 2026-06-18), not the AI Studio API.
{
  plugin = "opencode-antigravity-auth";
  provider = {
    models = {
      antigravity-gemini-3-pro = {
        name = "Gemini 3 Pro (Antigravity)";
        limit = {
          context = 1048576;
          output = 65535;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
        variants = {
          low = {thinkingLevel = "low";};
          high = {thinkingLevel = "high";};
        };
      };
      "antigravity-gemini-3.1-pro" = {
        name = "Gemini 3.1 Pro (Antigravity)";
        limit = {
          context = 1048576;
          output = 65535;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
        variants = {
          low = {thinkingLevel = "low";};
          high = {thinkingLevel = "high";};
        };
      };
      antigravity-gemini-3-flash = {
        name = "Gemini 3 Flash (Antigravity)";
        limit = {
          context = 1048576;
          output = 65536;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
        variants = {
          minimal = {thinkingLevel = "minimal";};
          low = {thinkingLevel = "low";};
          medium = {thinkingLevel = "medium";};
          high = {thinkingLevel = "high";};
        };
      };
      antigravity-claude-opus-4-6-thinking = {
        name = "Claude Opus 4.6 Thinking (Antigravity)";
        limit = {
          context = 200000;
          output = 64000;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
        variants = {
          low = {thinkingConfig = {thinkingBudget = 8192;};};
          max = {thinkingConfig = {thinkingBudget = 32768;};};
        };
      };
      antigravity-claude-sonnet-4-6 = {
        name = "Claude Sonnet 4.6 (Antigravity)";
        limit = {
          context = 200000;
          output = 64000;
        };
        modalities = {
          input = ["text" "image" "pdf"];
          output = ["text"];
        };
      };
    };
  };
}
