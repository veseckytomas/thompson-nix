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
  bash,
  coreutils,
  gnupg,
  procps,
  writeShellApplication,
  writeTextFile,
  ...
}: let
  keyboxLockLib = writeTextFile {
    name = "keybox-lock.sh";
    text = builtins.readFile ./keybox-lock.sh;
  };

  # The lock library is substituted in, so a moved store path fails the build, never silently.
  mkTool = name: src: extraInputs:
    writeShellApplication {
      inherit name;
      runtimeInputs = [bash coreutils gnupg procps] ++ extraInputs;
      text = builtins.replaceStrings ["@keyboxLockLib@"] ["${keyboxLockLib}"] (builtins.readFile src);
    };
in {
  gpg-decrypt-hardened = mkTool "gpg-decrypt-hardened" ./gpg-decrypt.sh [];
  keybox-sweep = mkTool "keybox-sweep" ./keybox-sweep.sh [];
  keybox-lock-harness = mkTool "keybox-lock-harness" ./keybox-lock-harness.sh [];
}
