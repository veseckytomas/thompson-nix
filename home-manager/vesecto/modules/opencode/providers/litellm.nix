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
{
  npm = "@ai-sdk/openai-compatible";
  name = "LiteLLM";
  options = {
    baseURL = "https://llm.ai.e-infra.cz/v1";
  };
  models = {
    # DeepSeek V4 Pro (1.6T MoE, MIT). Two endpoints share the model; plain = non-think, -thinking = think mode.
    deepseek-v4-pro = {
      name = "deepseek-v4-pro";
      release_date = "2026-04-24";
      open_weights = true;
      reasoning = false;
      tool_call = true;
      modalities = {
        input = ["text"];
        output = ["text"];
      };
      limit = {
        context = 1000000;
        output = 384000;
      };
      cost = {
        input = 0;
        output = 0;
      };
    };
    deepseek-v4-pro-thinking = {
      name = "deepseek-v4-pro-thinking";
      release_date = "2026-04-24";
      open_weights = true;
      reasoning = true;
      tool_call = true;
      modalities = {
        input = ["text"];
        output = ["text"];
      };
      limit = {
        context = 1000000;
        output = 384000;
      };
      cost = {
        input = 0;
        output = 0;
      };
    };
    # GLM-5 (Zhipu/Z.ai, 744B MoE, MIT).
    glm-5 = {
      name = "glm-5";
      release_date = "2026-02-12";
      open_weights = true;
      reasoning = true;
      tool_call = true;
      modalities = {
        input = ["text"];
        output = ["text"];
      };
      limit = {
        context = 200000;
        output = 128000;
      };
      cost = {
        input = 0;
        output = 0;
      };
    };
    # Kimi K2.7 (Moonshot, 1T MoE, modified MIT). Thinking always-on; native vision. Max output unpublished, so limit.output is left to the client default.
    "kimi-k2.7" = {
      name = "kimi-k2.7";
      release_date = "2026-06-12";
      open_weights = true;
      reasoning = true;
      tool_call = true;
      modalities = {
        input = ["text" "image"];
        output = ["text"];
      };
      limit = {
        context = 262144;
      };
      cost = {
        input = 0;
        output = 0;
      };
    };
    # Qwen3.5 397B-A17B (Alibaba, Apache-2.0). Native multimodal; 262K context (1M only on the hosted Plus endpoint).
    "qwen3.5" = {
      name = "qwen3.5";
      release_date = "2026-02-16";
      open_weights = true;
      reasoning = true;
      tool_call = true;
      modalities = {
        input = ["text" "image" "video"];
        output = ["text"];
      };
      limit = {
        context = 262144;
        output = 65536;
      };
      cost = {
        input = 0;
        output = 0;
      };
    };
  };
}
