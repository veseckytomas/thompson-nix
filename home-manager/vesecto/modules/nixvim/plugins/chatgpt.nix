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
  programs.nixvim = {
    plugins.chatgpt = {
      enable = true;
      settings = {
        api_key_cmd = "gpg --decrypt -q /home/vesecto/.config/api_keys/.openai_api_key.gpg";
        openai_params.model = "gpt-4.5-preview";
        predefined_chat_gpt_params = "https://raw.githubusercontent.com/veseckytomas/awesome-chatgpt-prompts/main/prompts.csv";
      };
      lazyLoad = {
        enable = true;
        settings = {
          cmd = [
            "ChatGPT"
            "ChatGPTActAs"
            "ChatGPTCompleteCode"
            "ChatGPTEditWithInstructions"
          ];
          keys = [
            "<leader>cho"
            "<leader>cha"
            "<leader>chc"
            "<leader>che"
          ];
        };
      };
    };
    keymaps = [
      {
        mode = ["n"];
        key = "<leader>cho";
        action = "<cmd>ChatGPT<CR>";
        options.desc = "[C][h]atGPT [O]pen";
      }
      {
        mode = ["n"];
        key = "<leader>cha";
        action = "<cmd>ChatGPTActAs<CR>";
        options.desc = "[C][h]atGPT [A]ct as";
      }
      {
        mode = ["n"];
        key = "<leader>chc";
        action = "<cmd>ChatGPTCompleteCode<CR>";
        options.desc = "[C][h]atGPT [C]omplete code";
      }
      {
        mode = ["n"];
        key = "<leader>che";
        action = "<cmd>ChatGPTEditWithInstructions<CR>";
        options.desc = "[C][h]atGPT [E]dit";
      }
    ];
  };
  imports = [
    ./api_keys
  ];
}
