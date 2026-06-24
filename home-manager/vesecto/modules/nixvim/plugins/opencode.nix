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
    plugins = {
      opencode = {
        enable = true;
      };

      # snacks.nvim is a direct dependency of opencode.nvim:
      #   - required for opencode.nvim's embedded terminal
      #   - input.enabled  -> recommended for better prompt input (ask)
      #   - picker.enabled -> enhances select()
      # Declared here so enabling opencode pulls snacks in automatically. If
      # plugins/snacks.nix is also enabled, the module system merges the
      # definitions (matching `enable = true` / settings are mergeable).
      snacks = {
        enable = true;
        settings = {
          input.enabled = true;
          picker.enabled = true;
        };
      };
    };

    # Required for opencode.nvim to auto-reload buffers after it edits files.
    opts.autoread = true;

    # Recommended keymaps (from the opencode.nvim README).
    keymaps = [
      {
        mode = ["n" "x"];
        key = "<leader>oa";
        action.__raw = ''
          function()
            require("opencode").ask("@this: ")
          end
        '';
        options.desc = "Ask OpenCode";
      }
      {
        mode = ["n" "x"];
        key = "<leader>os";
        action.__raw = ''
          function()
            require("opencode").select()
          end
        '';
        options.desc = "Select OpenCode";
      }
      {
        mode = ["n" "x"];
        key = "go";
        action.__raw = ''
          function()
            return require("opencode").operator("@this ")
          end
        '';
        options = {
          expr = true;
          desc = "Append range to OpenCode";
        };
      }
      {
        mode = ["n"];
        key = "goo";
        action.__raw = ''
          function()
            return require("opencode").operator("@this ") .. "_"
          end
        '';
        options = {
          expr = true;
          desc = "Append line to OpenCode";
        };
      }
      {
        mode = ["n"];
        key = "<S-C-u>";
        action.__raw = ''
          function()
            require("opencode").command("session.half.page.up")
          end
        '';
        options.desc = "Scroll OpenCode up";
      }
      {
        mode = ["n"];
        key = "<S-C-d>";
        action.__raw = ''
          function()
            require("opencode").command("session.half.page.down")
          end
        '';
        options.desc = "Scroll OpenCode down";
      }
    ];
  };
}
