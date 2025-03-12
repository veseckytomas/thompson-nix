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
      };
      openai = {
        model = "gpt-4.5-preview";
        max_tokens = 32768;
      };
      vendors = {
        groq = {
          __inherited_from = "openai";
          api_key_name = "GROQ_API_KEY";
          endpoint = "https://api.groq.com/openai/v1/";
          model = "llama-3.3-70b-versatile";
          max_tokens = 32768;
        };
      };
      auto_suggestions_frequency = "copilot";
      provider = "claude";
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
    ./api_keys
  ];
}
