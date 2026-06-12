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
{...}: let
  config_dir = ".config/api_keys";
in {
  home.file =
    {
      "${config_dir}/openai_api_key.gpg".source = ./openai_api_key.gpg;
      "${config_dir}/anthropic_api_key.gpg".source = ./anthropic_api_key.gpg;
      "${config_dir}/groq_api_key.gpg".source = ./groq_api_key.gpg;
      "${config_dir}/perplexity_api_key.gpg".source = ./perplexity_api_key.gpg;
    }
    # Long-lived Claude Code OAuth token (from `claude setup-token`), consumed by
    # the export in modules/zsh.nix so the opencode quota plugin stays authed.
    # Guarded so the config still evaluates before the encrypted file is created.
    // (
      if builtins.pathExists ./claude_oauth_token.gpg
      then {"${config_dir}/claude_oauth_token.gpg".source = ./claude_oauth_token.gpg;}
      else {}
    );
}
