{
  description = "Muhammad's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Та же версия bobthefish, которую закрепил Хашимото.
    theme-bobthefish = {
      url = "github:oh-my-fish/theme-bobthefish/e3b4d4eafc23516e35f162686f08a42edf844e40";
      flake = false;
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }: {
    nixosConfigurations.vm-aarch64 = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";

      modules = [
        ./machines/vm-aarch64.nix

        home-manager.nixosModules.home-manager

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-backup";
          home-manager.extraSpecialArgs = { inherit inputs; };

          home-manager.users.muhammad =
            import ./users/muhammad/home.nix;
        }
      ];
    };
  };
}
