# Repository with NixOS config used by Thompson

This repository contains these configurations:

- NixOS configuration for 3 machines I use
- Home Manager configuration for my user
- ISO configuration for NixOS installation
- ISO configuration for disk rescue

## Configurations present

- Desktop
- Laptop
- Test laptop
- Install ISO
- Disk rescue ISO
- Home-manager config

## Custom packages

These packages require manual update by changing rev and hash

- ./modules/loginManagers/sddm-theme/sddm-theme.nix

## Initial setup

1. Run rebuild on system with flakes enabled

```bash
sudo nixos-rebuild switch --flake .#$HOSTNAME
```

2. Run home-manager rebuild

```bash
home-manager switch --flake .#$USERNAME
```

3. Add Yubikeys

```bash
nix shell nixpkgs#pam_u2f
mkdir -p ~/.config/Yubico
# Insert Yubikey
pamu2fcfg > ~/.config/Yubico/u2f_keys
# Insert second Yubikey
pamu2fcfg -n >> ~/.config/Yubico/u2f_keys
```

1. Add ssh, gpg keys, certificates.
2. Set thunderbird email accounts and add certificates.
3. Any change line 14 in scripts/home.sh to $USERNAME
4. Configure VPN
   - Faculty
   - University
   - Home
5. Clone repositories

```bash
mkdir -p "$HOME/Git"
mkdir -p "$HOME/DataGripProjects"
git clone git@gitlab.com:vesecky.tomas/obsidian.git ~/Git/obsidian
git clone git@gitlab.com:homelab1960731/thompson-dwh.git ~/DataGripProjects/Homelab
git clone git@gitlab.fit.cvut.cz:vesecto1/dwh-project.git ~/DataGripProjects/DWH
```

7. Any subsequent rebuild for both nixos and home-manager can be rebuilt with helper script `nixos-run`.

## TMUX initial setup

1. clone TMP git repository

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

2. Install plugins with `<leader>I`
3. Plugins can be update with `<leader>U`

## Neovim initial setup

- Authenticate to plugins by running these commands in neovim

```vimscript
Codeium Auth
Copilot auth
WakaTimeApiKey
```

## ZSH initial setup

- Plugins can be updated by running `zinit update`
