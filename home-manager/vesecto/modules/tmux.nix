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
  inputs,
  ...
}: let
  tmux-navigator = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-navigator";
    version = "unstable";
    src = inputs.tmux-navigator;
  };
  tmux-yank = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-yank";
    version = "unstable";
    src = inputs.tmux-yank;
  };
in {
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    keyMode = "vi";
    mouse = true;
    disableConfirmationPrompt = true;
    prefix = "C-space";
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "screen-256color";
    plugins = [
      tmux-yank
      tmux-navigator
    ];
    extraConfig = ''
      # Refresh 'status-left' and 'status-right' more often, from every 15s to 5s
      set -g status-interval 5

      # Set window numbering
      set-option -g renumber-windows on

      # Set colors
      set -ga terminal-overrides ",xterm-256color*:Tc"
      set -gq allow-passthrough on

      # Keybinds
      bind -n M-H previous-window
      bind -n M-L next-window
      bind -r h resize-pane -L 5
      bind -r j resize-pane -D 5
      bind -r k resize-pane -U 5
      bind -r l resize-pane -R 5

      # Open windows and panes in current directory
      bind b split-window -v -c "#{pane_current_path}"
      bind v split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"
    '';
  };
  catppuccin.tmux = {
    enable = true;
    flavor = "mocha";
    extraConfig = ''
      set -g @catppuccin_window_status_style 'basic'
      set -g @catppuccin_window_number_position 'left'
      set -g @catppuccin_window_status 'no'
      set -g @catppuccin_window_default_text '#W'
      set -g @catppuccin_window_current_fill 'number'
      set -ag @catppuccin_window_current_text '#W'
      set -g @catppuccin_window_current_number_color "#{@thm_flamingo}"
      set -g allow-rename off
      set -g status-right-length 100
      set -g status-left-length 100
      set -g status-left ""
      set -g status-right "#{E:@catppuccin_status_application}"
      set -ag status-right "#{E:@catppuccin_status_session}"
      set -g @catppuccin_window_text " #[bold]#{pane_current_command}#[nobold]: #{s|$HOME|~|;=|-24|…:pane_current_path}"
      set -g @catppuccin_window_current_text " #H"
    '';
  };
}
