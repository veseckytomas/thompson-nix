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
{...}: let
  config_dir = ".config/api_keys";
in {
  home.file = {
    "${config_dir}/openai_api_key.gpg".source = ./openai_api_key.gpg;
    "${config_dir}/anthropic_api_key.gpg".source = ./anthropic_api_key.gpg;
    "${config_dir}/groq_api_key.gpg".source = ./groq_api_key.gpg;
    "${config_dir}/perplexity_api_key.gpg".source = ./perplexity_api_key.gpg;
    "${config_dir}/context7_api_key.gpg".source = ./context7_api_key.gpg;
  };
}
