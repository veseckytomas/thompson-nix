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

      # Enable wt
      if command -v wt >/dev/null 2>&1; then
        eval "$(wt config shell init zsh)"
      fi

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

      function yk-touch {
        case "$1" in
          on|off)
            ykman openpgp keys set-touch -f sig "$1" \
              && echo "YubiKey signing touch policy set to: $1"
            ;;
          ""|status)
            local policy
            policy=$(ykman openpgp info 2>/dev/null \
              | awk '/^Signature key:/{f=1} f&&/Touch policy:/{print $3; exit}')
            if [ -z "$policy" ]; then
              echo "Could not read YubiKey OpenPGP status (is the key inserted?)" >&2
              return 1
            fi
            echo "YubiKey signing touch policy: $policy"
            ;;
          *)
            echo "Usage: yk-touch [on|off|status]" >&2
            echo "  on      require touch for signing (manual work)" >&2
            echo "  off     no touch required for signing (agent work)" >&2
            echo "  status  show current signing touch policy (default)" >&2
            return 1
            ;;
        esac
      }
    '';
    shellAliases = {
      "pentaho" = "export ORACLE_SID=DS.CVUT.CZ && export TNS_ADMIN=~/oracle-instantclient/network/admin/ && export ORACLE_HOME=~/oracle-instantclient/ && steam-run ~/pentaho/spoon.sh";
      "cp" = "cp -r";
      "ls" = "eza --icons -F -H --group-directories-first --git";
      "la" = "ls -a -1";
      "ll" = "ls -lahg";
      "cal" = "cal -m";
      "rm" = "trash";
      "fzf" = "fzf --preview \"bat --color=always --style=header,grid --line-range :500 {}\"";
      "latexmk" = "latexmk -lualatex";
      "rsync" = "rsync -r --info=progress2";
      "asus-num" = "systemctl restart asus-numberpad-driver.service";
      "oc" = "opencode";
      "wts" = "wt switch";
      "wtr" = "wt remove";
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
