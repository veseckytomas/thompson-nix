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
        model = "claude-3-7-sonnet";
        api_key_name = "cmd:gpg --decrypt -q /home/vesecto/.config/api_keys/anthropic_api_key.gpg";
        hide_in_model_selector = true;
      };
      openai = {
        model = "gpt-4.1";
        api_key_name = "cmd:gpg --decrypt -q /home/vesecto/.config/api_keys/openai_api_key.gpg";
      };
      ollama = {
        endpoint = "http://127.0.0.1:11434";
        model = "Deepseek-r1";
      };
      cohere.hide_in_model_selector = true;
      vendors = {
        llama = {
          __inherited_from = "openai";
          api_key_name = "cmd:gpg --decrypt -q /home/vesecto/.config/api_keys/groq_api_key.gpg";
          endpoint = "https://api.groq.com/openai/v1/";
          model = "llama-3.3-70b-versatile";
        };
        sonar-deep-research = {
          __inherited_from = "openai";
          api_key_name = "cmd:gpg --decrypt -q /home/vesecto/.config/api_keys/perplexity_api_key.gpg";
          endpoint = "https://api.perplexity.ai";
          model = "sonar-deep-research";
        };
        sonar-pro = {
          __inherited_from = "openai";
          api_key_name = "cmd:gpg --decrypt -q /home/vesecto/.config/api_keys/perplexity_api_key.gpg";
          endpoint = "https://api.perplexity.ai";
          model = "sonar-pro";
        };
        copilot_claude = {
          __inherited_from = "copilot";
          model = "claude-3-7-sonnet";
        };
        copilot_openai = {
          __inherited_from = "copilot";
          model = "gpt-4.1";
        };
      };
      auto_suggestions_frequency = "copilot";
      provider = "copilot";
      cursor_applying_provider = "copilot";
      behaviour = {
        auto_suggestions = false;
        enable_cursor_planning_mode = true;
      };
      config = ''
        vim.opt.laststatus = 3
      '';
    };
    lazyLoad = {
      enable = true;
      settings = {
        keys = [
          "<leader>aa"
          "<leader>a?"
        ];
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
