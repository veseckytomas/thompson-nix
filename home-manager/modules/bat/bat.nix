{ config, pkgs, lib, ... }:

{
  programs.bat.enable = true;
  programs.bat = {
    enable = true;
    themes = {
      catppuccin = {
        src = pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "bat";
          rev = "82e7ca555f805b53d2b377390e4ab38c20282e83";
          sha256 = "0jl639vqz37avx31adrfmlafg4vzdyqh9gz3mzfijpj6rfx4yq0g";
        };
        file = "Catppuccin Mocha.tmTheme";
      };
    };
    config = {
      theme = "Catppuccin Mocha";
    };
  };
}
