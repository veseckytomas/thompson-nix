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
# Gemini + Claude via opencode-agy-auth (Antigravity CLI): the plugin injects the google-agy provider + models dynamically; projectId drives both inference and the opencode-quota panel.
{
  plugin = "@anthonyhaussman/opencode-agy-auth";
  provider = {
    options = {
      projectId = "rising-fact-p41fc";
    };
  };
}
