{
  description = "My NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Match NixOS-WSL to the same stable NixOS release as nixpkgs.
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Та же версия bobthefish, которую закрепил Хашимото.
    theme-bobthefish = {
      url = "github:oh-my-fish/theme-bobthefish/e3b4d4eafc23516e35f162686f08a42edf844e40";
      flake = false;
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      nixos-wsl,
      ...
    }:
    {
      # NixOS VM на MacBook.
      nixosConfigurations.vm-aarch64 = nixpkgs.lib.nixosSystem {
        modules = [
          ./machines/vm-aarch64.nix
          ./users/muhammad/nixos.nix

          home-manager.nixosModules.home-manager

          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";

            home-manager.extraSpecialArgs = {
              inherit inputs;
              isWSL = false;
            };

            home-manager.users.muhammad = import ./users/muhammad/home-manager.nix;
          }
        ];
      };

      # NixOS внутри Windows WSL.
      nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
        modules = [
          nixos-wsl.nixosModules.wsl
          ./machines/wsl.nix
          ./users/muhammad/nixos.nix

          home-manager.nixosModules.home-manager

          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";

            home-manager.extraSpecialArgs = {
              inherit inputs;
              isWSL = true;
            };

            home-manager.users.muhammad = import ./users/muhammad/home-manager.nix;
          }
        ];
      };

      # `nix fmt` works on every platform used to maintain or build this flake.
      formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
      formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixfmt-tree;
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-tree;
    };
}
