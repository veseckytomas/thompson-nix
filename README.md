# Repository with NixOS config used by Thompson

This repository contains these configurations:

- NixOS configuration for machines I use
- Home Manager configuration for my user
- ISO configuration for NixOS installation
- ISO configuration for disk rescue

## Configurations present

- Desktop
- Laptop
- Servers
- Install ISO
- Disk rescue ISO
- Home-manager config as Standalone
- Server Home-manager config as NixOS module

## Initial setup

1. Run setup script on system with flakes enabled

```bash
./scripts/setup.sh
```

1. Add ssh, gpg keys, certificates.
2. Set thunderbird email accounts and add certificates.
3. Any subsequent rebuild for both nixos and home-manager can be rebuilt with helper script `nixos-run`.

## Neovim initial setup

- Authenticate to plugins by running these commands in neovim

```vimscript
Codeium Auth
Copilot auth
WakaTimeApiKey
```

## TODO

### TomasVesa-NTB-NixOS

- High resolution scaling
- Touchscreen

## Acknowledgments

I would like to thank to all that projects that I used in my configuration.

| Repository                                                | License     | Functionality                           |
| --------------------------------------------------------- | ----------- | --------------------------------------- |
| [ZaneyOS](https://gitlab.com/Zaney/zaneyos)               | MIT License | Hyprland config and other small changes |
| [DT dotfiles](https://gitlab.com/dwt1/dotfiles)           | No License  | Qtile config                            |
| [Loqusion dotfiles](https://github.com/loqusion/dotfiles) | No License  | Rofi theme                              |
