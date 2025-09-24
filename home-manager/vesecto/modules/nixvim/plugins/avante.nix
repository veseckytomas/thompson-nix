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
  inputs,
  pkgs,
  ...
}: {
  programs.nixvim.plugins.avante = {
    enable = true;
    # package = pkgs.vimPlugins.avante-nvim.overrideAttrs (old: {
    #   src = inputs.avante-nvim;
    # });
    settings = {
      providers = {
        claude = {
          api_key_name = "cmd:gpg --decrypt -q /home/vesecto/.config/api_keys/anthropic_api_key.gpg";
          extra_request_body = {
            max_tokens = 64000;
          };
        };
        openai = {
          model = "o3-2025-04-16"; # "gpt-4.1"
          api_key_name = "cmd:gpg --decrypt -q /home/vesecto/.config/api_keys/openai_api_key.gpg";
          extra_request_body = {
            max_tokens = 64000;
          };
        };
        ollama = {
          endpoint = "http://127.0.0.1:11434";
          model = "Deepseek-r1";
          extra_request_body = {
            max_tokens = 64000;
          };
        };
        copilot = {
          extra_request_body = {
            max_tokens = 64000;
            reasoning_effort = "high";
          };
        };
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
        # Hide providers
        vertex_claude.hide_in_model_selector = true;
        vertex.hide_in_model_selector = true;
        azure.hide_in_model_selector = true;
        openai-gpt-4o-mini.hide_in_model_selector = true;
        claude-opus.hide_in_model_selector = true;
        claude-haiku.hide_in_model_selector = true;
      };
      provider = "copilot";
      auto_suggestions_provider = "copilot";
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
          "<leader>ah"
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
