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
  programs.nixvim.plugins.avante = {
    enable = true;
    settings = {
      claude = {
        model = "claude-3-7-sonnet-20250219";
        api_key_name = "cmd:gpg --decrypt -q /home/vesecto/.config/api_keys/anthropic_api_key.gpg";
      };
      openai = {
        model = "gpt-4.5-preview";
        api_key_name = "cmd:gpg --decrypt -q /home/vesecto/.config/api_keys/openai_api_key.gpg";
      };
      ollama = {
        endpoint = "http://127.0.0.1:11434";
        model = "qwq:32b";
      };
      vendors = {
        llama = {
          __inherited_from = "openai";
          api_key_name = "cmd:gpg --decrypt -q /home/vesecto/.config/api_keys/groq_api_key.gpg";
          endpoint = "https://api.groq.com/openai/v1/";
          model = "llama-3.3-70b-versatile";
        };
        mistral = {
          __inherited_from = "openai";
          api_key_name = "cmd:gpg --decrypt -q /home/vesecto/.config/api_keys/groq_api_key.gpg";
          endpoint = "https://api.groq.com/openai/v1/";
          model = "mistral-8x-7b-32768";
        };
        openai-45 = {
          __inherited_from = "openai";
          model = "gpt-4.5-preview";
        };
        openai-4o = {
          __inherited_from = "openai";
          model = "gpt-4o";
        };
        openai-o1 = {
          __inherited_from = "openai";
          model = "o1";
        };
        openai-o3-mini = {
          __inherited_from = "openai";
          model = "o3-mini";
        };
        perplexity = {
          __inherited_from = "openai";
          api_key_name = "cmd:gpg --decrypt -q /home/vesecto/.config/api_keys/perplexity_api_key.gpg";
          endpoint = "https://api.perplexity.ai";
          model = "sonar-deep-research";
        };
      };
      auto_suggestions_frequency = "copilot";
      provider = "copilot";
      cursor_applying_provider = "copilot";
      behaviour = {
        auto_suggestions = false;
        enable_cursor_planning_mode = true;
      };
    };
    lazyLoad = {
      enable = true;
      settings = {
        keys = ["<leader>aa"];
        cmd = [
          "AvanteAsk"
          "AvanteBuild"
          "AvanteChat"
          "AvanteEdit"
          "AvanteFocus"
          "AvanteRefresh"
          "AvanteSwitchProvider"
          "AvanteShowRepoMap"
          "AvanteToggle"
        ];
      };
    };
  };
  imports = [
    ./api_keys/default.nix
  ];
}
