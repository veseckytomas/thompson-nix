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
  description = "Thompson NixOS config flake";

  inputs = {
    catppuccin.url = "github:catppuccin/nix";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "nixpkgs/nixos-26.05";
    # Last channel rev with opencode 1.x (1.19.0): oh-my-openagent does not support V2 yet.
    nixpkgs-opencode.url = "github:NixOS/nixpkgs/09063bd1f2b36fd9fd793c36dfade7bd40a93dfc";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-stable.url = "github:nix-community/home-manager/release-26.05";
    nixvim-stable.url = "github:nix-community/nixvim/nixos-26.05";
    nix-flatpak.url = "github:gmodena/nix-flatpak/";
    polymc.url = "github:PolyMC/PolyMC";
    yazi.url = "github:sxyazi/yazi";
    asus-numberpad-driver = {
      url = "github:asus-linux-drivers/asus-numberpad-driver";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      type = "git";
      url = "https://github.com/hyprwm/Hyprland";
      submodules = true;
    };
    # Not "2048": nix rejects an all-digit input name as a flake input attribute path element.
    game-2048 = {
      type = "github";
      owner = "mevdschee";
      repo = "2048.c";
      flake = false;
    };
    sddm-theme = {
      type = "github";
      # owner = "MarianArlt";
      # repo = "sddm-sugar-dark";
      owner = "TiagoDamascena";
      repo = "sddm-sugar-catppuccin";
      flake = false;
    };
    kulala-nvim = {
      type = "github";
      owner = "mistweaverco";
      repo = "kulala.nvim";
      flake = false;
    };
    render-markdown-nvim = {
      type = "github";
      owner = "MeanderingProgrammer";
      repo = "render-markdown.nvim";
      flake = false;
    };
    zsh-syntax-highlighting = {
      type = "github";
      owner = "zsh-users";
      repo = "zsh-syntax-highlighting";
      flake = false;
    };
    zsh-completions = {
      type = "github";
      owner = "zsh-users";
      repo = "zsh-completions";
      flake = false;
    };
    zsh-autosuggestions = {
      type = "github";
      owner = "zsh-users";
      repo = "zsh-autosuggestions";
      flake = false;
    };
    zsh-autopair = {
      type = "github";
      owner = "hlissner";
      repo = "zsh-autopair";
      flake = false;
    };
    zsh-fzf-tab = {
      type = "github";
      owner = "Aloxaf";
      repo = "fzf-tab";
      flake = false;
    };
    zsh-atuin = {
      type = "github";
      owner = "atuinsh";
      repo = "atuin";
      flake = false;
    };
    tmux-sensible = {
      type = "github";
      owner = "tmux-plugins";
      repo = "tmux-sensible";
      flake = false;
    };
    tmux-navigator = {
      type = "github";
      owner = "christoomey";
      repo = "vim-tmux-navigator";
      flake = false;
    };
    tmux-yank = {
      type = "github";
      owner = "tmux-plugins";
      repo = "tmux-yank";
      flake = false;
    };
    # avante-nvim = {
    #   type = "github";
    #   owner = "yetone";
    #   repo = "avante.nvim";
    #   flake = false;
    # };
    dracula-gtk = {
      type = "github";
      owner = "dracula";
      repo = "gtk";
      flake = false;
    };
    ratbagd = {
      type = "github";
      owner = "libratbag";
      repo = "libratbag";
      flake = false;
    };
    piper = {
      type = "github";
      owner = "libratbag";
      repo = "piper";
      flake = false;
    };
    get-shit-done-redux = {
      url = "github:open-gsd/get-shit-done-redux";
      flake = false;
    };
    oh-my-openagent = {
      type = "git";
      url = "https://github.com/code-yeongyu/oh-my-openagent";
      # flake.lock pins the source; updates resolve the `dev` tip behind a build gate.
      ref = "dev";
      # Shallow fetch: this repo pulls the ~1.7 GB `open-design` submodule, and
      # full history is never needed for a flake=false source tree. shallow does
      # not change the exported tree, so the narHash (and the build) is unchanged.
      shallow = true;
      submodules = true;
      flake = false;
    };
    caveman = {
      url = "github:JuliusBrussee/caveman";
      flake = false;
    };
    superpowers = {
      url = "github:obra/superpowers";
      flake = false;
    };
    mattpocock-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
    taskwarrior-tui = {
      url = "github:kdheepak/taskwarrior-tui";
      flake = false;
    };
    tock = {
      url = "github:kriuchkov/tock";
      flake = false;
    };
    bun2nix = {
      url = "github:nix-community/bun2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs = {
        pyproject-nix.follows = "pyproject-nix";
        nixpkgs.follows = "nixpkgs";
      };
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs = {
        pyproject-nix.follows = "pyproject-nix";
        uv2nix.follows = "uv2nix";
        nixpkgs.follows = "nixpkgs";
      };
    };
    graphify-src = {
      type = "github";
      owner = "Graphify-Labs";
      repo = "graphify";
      flake = false;
    };
  };

  outputs = inputs: let
    system = "x86_64-linux";
    username = "vesecto";
    lib = inputs.nixpkgs.lib;
    # Limit lint inputs so the check ignores result/, graphify-out/ and the docs tree.
    lintSrc = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions [
        ./flake.nix
        ./home-manager/vesecto/modules/statix/statix.toml
        ./home-manager/vesecto/modules/opencode/plugins/graphify/plugin.js
        ./home-manager/vesecto/modules/opencode/plugins/graphify/plugin.test.js
        (lib.fileset.fileFilter (f: f.hasExt "nix") ./home-manager)
        (lib.fileset.fileFilter (f: f.hasExt "nix") ./hosts)
        (lib.fileset.fileFilter (f: f.hasExt "nix") ./modules)
        # nixos-run interpolates these as data, so nothing else ever parses them.
        (lib.fileset.fileFilter (f: f.hasExt "sh" || f.hasExt "py") ./modules/common/packages/nixos-run)
        (lib.fileset.fileFilter (f: f.hasExt "sh") ./home-manager/vesecto/modules/opencode/plugins/omniroute)
      ];
    };
    pkgs = import inputs.nixpkgs {
      inherit system;
      config = {allowUnfree = true;};
    };
    pkgs-stable = import inputs.nixpkgs-stable {
      inherit system;
      config = {allowUnfree = true;};
    };
  in {
    nixosConfigurations = {
      TomasVesa-PC-NixOS = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          hostname = "TomasVesa-PC-NixOS";
          inherit inputs username system pkgs-stable;
        };
        modules = [
          ./hosts/desktop/TomasVesa-PC-NixOS
          ./modules/common/gaming-mouse.nix
          ./modules
        ];
      };

      TomasVesa-NTB-NixOS = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          hostname = "TomasVesa-NTB-NixOS";
          inherit inputs username system pkgs-stable;
        };
        modules = [
          inputs.asus-numberpad-driver.nixosModules.default
          # The module resolves its package via mkPackageOption, so its overlay must be applied too.
          {nixpkgs.overlays = [inputs.asus-numberpad-driver.overlays.default];}
          ./hosts/desktop/TomasVesa-NTB-NixOS
          ./modules/common/notebook.nix
          ./modules/common/gaming.nix
          ./modules/common/gaming-mouse.nix
          ./modules
        ];
      };

      TomasVesa-Portable-NixOS = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs username system pkgs-stable;
          hostname = "TomasVesa-Portable-NixOS";
        };
        modules = [
          ./hosts/desktop/TomasVesa-Portable-NixOS
          ./modules/common/notebook.nix
          ./modules
        ];
      };

      Karthik = inputs.nixpkgs-stable.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {
          inherit inputs username;
        };
        pkgs = import inputs.nixpkgs-stable {
          inherit system;
        };
        modules = [
          ./hosts/server/Karthik
          ./modules/server.nix
        ];
      };

      NixOSServerTemplate = inputs.nixpkgs-stable.lib.nixosSystem {
        specialArgs = {
          inherit inputs username system;
        };
        pkgs = import inputs.nixpkgs-stable {
          inherit system;
        };
        modules = [
          ./hosts/server/NixOSServerTemplate
          ./modules/server.nix
        ];
      };

      Reyhan = inputs.nixpkgs-stable.lib.nixosSystem {
        specialArgs = {
          inherit inputs username system;
        };
        pkgs = import inputs.nixpkgs-stable {
          inherit system;
        };
        modules = [
          ./hosts/server/Reyhan
          ./modules/server.nix
        ];
      };

      Merete = inputs.nixpkgs-stable.lib.nixosSystem {
        specialArgs = {
          inherit inputs username system;
        };
        pkgs = import inputs.nixpkgs-stable {
          inherit system;
        };
        inherit system;
        modules = [
          ./hosts/server/Merete
          ./modules/server.nix
        ];
      };

      rescueIso = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs username system;};
        modules = [
          ./hosts/iso/rescueIso
        ];
      };

      installIso = inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs username system;};
        modules = [
          ./hosts/iso/installIso
        ];
      };
    };

    homeConfigurations = {
      vesecto = inputs.home-manager.lib.homeManagerConfiguration {
        extraSpecialArgs = {inherit inputs system username pkgs-stable;};
        inherit pkgs;
        modules = [
          ./home-manager/vesecto
        ];
      };
    };

    # `nix flake check` would evaluate every host; build this attr directly to lint alone.
    checks.${system}.lint =
      pkgs.runCommand "lint" {
        nativeBuildInputs = [pkgs.alejandra pkgs.jq pkgs.nodejs pkgs.python3 pkgs.shellcheck pkgs.sqlite pkgs.statix];
      } ''
        cd ${lintSrc}
        # bun2nix generates this one; alejandra would reformat it on every regeneration.
        alejandra --quiet --check --exclude ./home-manager/vesecto/modules/opencode/plugins/oh-my-openagent/oh-my-openagent-bun.nix .
        statix check -c home-manager/vesecto/modules/statix .
        node --check home-manager/vesecto/modules/opencode/plugins/graphify/plugin.js
        node --test home-manager/vesecto/modules/opencode/plugins/graphify/plugin.test.js
        PYTHONPYCACHEPREFIX="$TMPDIR/pycache" python3 -m compileall -q modules/common/packages/nixos-run
        # writeShellApplication already shellchecks its own fragments, which lack a shebang here.
        grep -lx '#!.*' modules/common/packages/nixos-run/*.sh home-manager/vesecto/modules/opencode/plugins/omniroute/*.sh | xargs shellcheck
        # A stub a harness generates must not use /usr/bin/env, absent from the build sandbox; a harness's own line-1 shebang is inert.
        if awk 'FNR>1 && /#!\/usr\/bin\/env/ {print FILENAME": "FNR; f=1} END {exit !f}' modules/common/packages/nixos-run/*.sh home-manager/vesecto/modules/opencode/plugins/omniroute/*.sh; then
          echo "above: generated stub uses /usr/bin/env, absent from the build sandbox; emit printf '#!%s\\n' \"\$(command -v bash)\" instead" >&2
          exit 1
        fi
        # These harnesses are hermetic; the gates they cover otherwise only fail mid-update.
        bash modules/common/packages/nixos-run/choose-performance-test.sh
        bash modules/common/packages/nixos-run/verify-omniroute-resilience-readers-test.sh
        bash home-manager/vesecto/modules/opencode/plugins/omniroute/diagnostics-cli-test.sh
        bash home-manager/vesecto/modules/opencode/plugins/omniroute/resilience-defaults-test.sh
        touch $out
      '';

    # bun runs the opencode plugins, so testing one by hand needs it without a store-path hunt.
    devShells.${system}.default = pkgs.mkShell {
      packages = [pkgs.bun pkgs.nodejs pkgs.sqlite pkgs.jq pkgs.alejandra pkgs.statix];
    };

    packages.${system} = {
      nixos-run = pkgs.callPackage ./modules/common/packages/nixos-run {
        flakePath = "/home/${username}/Git/Personal/thompson-nix";
      };
      ykman-run = pkgs.callPackage ./modules/common/packages/ykman-run {};
      graphify = import ./home-manager/vesecto/modules/opencode/graphify {
        inherit inputs pkgs;
      };
    };
  };
}
