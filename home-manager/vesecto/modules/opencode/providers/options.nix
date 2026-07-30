#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: vesecky@proton.me
# GitHub: veseckytomas
# GitLab: vesecky.tomas
# Enable/disable opencode providers from one place; wired in ./default.nix.
{lib, ...}: {
  options.opencodeProviders = {
    litellm.enable = lib.mkEnableOption "LiteLLM provider (e-infra OpenAI-compatible gateway)";
    omniroute.enable = lib.mkEnableOption "OmniRoute provider (local OmniRoute gateway)";
    openai.enable = lib.mkEnableOption "OpenAI provider (direct OpenAI API; pulls opencode-openai-multi-auth plugin)";
    "google-agy".enable = lib.mkEnableOption "Google via Antigravity CLI (agy-auth plugin + projectId)";
    anthropic.enable = lib.mkEnableOption "Anthropic provider (claude-bridge plugin)";
  };
}
