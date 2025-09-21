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
  pkgs,
  config,
  inputs,
  ...
}: let
  HIST_SIZE = 10000;
in {
  programs.zsh = {
    enable = true;
    dotDir = config.xdg.configHome + "/zsh";
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
      {
        name = "zsh-autopair";
        src = inputs.zsh-autopair;
      }
      {
        name = "fzf-tab";
        src = inputs.zsh-fzf-tab;
      }
      {
        name = "zsh-atuin";
        src = inputs.zsh-atuin;
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

      # Enable starship
      eval "$(starship init zsh)"

      # Variables
      export DIRENV_WARN_TIMEOUT=0

      # Enable SSH Agent
      { eval $(gnome-keyring-daemon -s) } &>/dev/null

      # Functions
      function nvimf() {
        FILE=$(fzf)
        if [[ $FILE  != "" ]]; then
          nvim "$FILE"
        fi
      }
      function gbr {
      	git brd $1
      	git push -d origin $1
      }
      function take {
      	mkdir $1
      	cd $1
      }
      function save_obsidian {
      	pushd ~/Git/Personal/thompson-obsidian > /dev/null
        git pull
      	git add --all
      	current=$(date -Iseconds)
      	git commit -m "Update: $current"
      	git push
      	popd > /dev/null
      }
      function save_xournal {
      	pushd ~/Git/Personal/thompson-notes > /dev/null
        git pull
      	git add --all
      	current=$(date -Iseconds)
      	git commit -m "Update: $current"
      	git push
      	popd > /dev/null
      }
      function nixos-run {
      	pushd ~/Git/Personal/thompson-nix > /dev/null
      	./scripts/main.sh
      	popd > /dev/null
      }
      function ga {
        git add $(git status --porcelain | command fzf | awk '{print $2}' | tr '\n' ' ');
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
    '';
    shellAliases = {
      "pentaho" = "export ORACLE_SID=DS.CVUT.CZ && export TNS_ADMIN=~/oracle-instantclient/network/admin/ && export ORACLE_HOME=~/oracle-instantclient/ && steam-run ~/pentaho/spoon.sh";
      "root@ebie" = "ssh -A -L 5431:dv1:5432 -L 2221:dv1:22 -L 2222:dv2:22 -L 2223:dv3:22 -L 2224:dv4:22  -L 8088:dv2:8080 -L 8008:dv2:8008 -L 5430:dv5:5433 root@ebie.is.cvut.cz";
      "cp" = "cp -r";
      "ls" = "eza --icons -F -H --group-directories-first --git";
      "la" = "ls -a -1";
      "ll" = "ls -lahg";
      "cal" = "cal -m";
      "rm" = "trash";
      "fzf" = "fzf --preview \"bat --color=always --style=header,grid --line-range :500 {}\"";
      "latexmk" = "latexmk -lualatex";
      "lg" = "lazygit";
      "sp" = "spotify_player";
      "rsync" = "rsync -r --info=progress2";
    };
  };
  catppuccin.zsh-syntax-highlighting = {
    enable = true;
    flavor = "mocha";
  };
  home = {
    packages = with pkgs; [
      eza
      fd
      tldr
      trash-cli
      dig
      entr
      traceroute
      unzip
      zip
      tokei
    ];
  };
}
