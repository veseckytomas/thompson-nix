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
{pkgs, ...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    defaultKeymap = "emacs";
    autosuggestions = {
      enable = true;
      strategy = [
        "history"
        "completion"
      ];
    };
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [
        "zsh-users/zsh-completions"
        "zsh-users/zsh-syntax-highlighting"
        "zsh-users/zsh-completions"
        "zsh-users/zsh-autosuggestions"
        "hlissner/zsh-autopair"
        "Aloxaf/fzf-tab"
        "atuinsh/atuin"
      ];
    };
    history = {
      append = true;
      ignoreSpace = true;
      path = "./.zsh_history";
      save = 10000;
      size = 10000;
      ignoreDups = true;
      ignoreAllDups = true;
      findNoDups = true;
      expireDuplicatesFirst = true;
      saveNoDups = true;
      share = true;
    };
    initExtra = ''
      # Keybinds
      bindkey -e
      bindkey '^n' history-search-forward
      bindkey '^p' history-search-backward

      bindkey '^o' clear-screen

      # Enable starship
      eval "$(starship init zsh)"

      # Variables
      export EDITOR=nvim
      export DIRENV_WARN_TIMEOUT=0
      export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
      export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

      # Enable SSH Agent
      { eval $(gnome-keyring-daemon -s) } &>/dev/null
    '';
    shellAliases = {

    }
  };
  catppuccin.zsh-syntax-highlighting = {
    enable = true;
    flavor = "mocha";
  };
  home = {
    packages = with pkgs; [
      zsh
      bat
      eza
      fd
      zoxide
      yazi
      trash-cli
      dig
      entr
      direnv
      traceroute
      unzip
      zip
      starship
      gotop
      htop
      atuin
    ];
  };
}
