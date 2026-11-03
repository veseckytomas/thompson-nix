#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: tomas@vesecky.net
# GitHub: veseckytomas
# GitLab: vesecky.tomas
{
  pkgs,
  inputs,
  ...
}: let
  HIST_SIZE = 10000;
in {
  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";
    enableCompletion = true;
    defaultKeymap = "emacs";
    autosuggestion = {
      enable = true;
      strategy = [
        "history"
        "completion"
      ];
    };
    syntaxHighlighting.enable = true;
    plugins = [
      {
        name = "zsh-syntax-highlighting";
        src = inputs.zsh-syntax-highlighting;
      }
      {
        name = "zsh-completions";
        src = inputs.zsh-completions;
      }
      {
        name = "zsh-autosuggestions";
        src = inputs.zsh-autosuggestions;
      }
    ];
    history = {
      append = true;
      ignoreSpace = true;
      path = "$HOME/.zsh_history";
      save = HIST_SIZE;
      size = HIST_SIZE;
      ignoreDups = true;
      ignoreAllDups = true;
      findNoDups = true;
      expireDuplicatesFirst = true;
      saveNoDups = true;
      share = true;
    };
    initContent = ''
      # Keybinds
      bindkey -e
      bindkey '^n' history-search-forward
      bindkey '^p' history-search-backward

      bindkey '^o' clear-screen

      # Functions
      function nvimf() {
        FILE=$(fzf)
        if [[ $FILE  != "" ]]; then
          nvim "$FILE"
        fi
      }
      function take {
      	mkdir $1
      	cd $1
      }
      function fpkill {
        local selection
        selection=$(ps -e -o pid,comm | tail -n+2 | command fzf --no-multi)
        local pid=$(echo "$selection" | awk '{print $1}')
        local pname=$(echo "$selection" | awk '{print $2}')
        if [ "$pid" != "" ]; then
          kill -9 "$pid" > /dev/null 2>&1 && echo "Process $pname (PID $pid) has been successfully killed."
        fi
      }

      # Clear aliases
      unalias run-help which-command l
    '';
    shellAliases = {
      "ls" = "eza --icons -F -H --group-directories-first --git";
      "la" = "ls -a -1";
      "ll" = "ls -lahg";
      "rm" = "trash";
    };
  };
  catppuccin.zsh-syntax-highlighting = {
    enable = true;
    flavor = "mocha";
  };
  home = {
    packages = with pkgs; [
      eza
      trash-cli
    ];
  };
}
