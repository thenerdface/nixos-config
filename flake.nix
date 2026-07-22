{
  description = "Muhammad's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }: {
    nixosConfigurations.vm-aarch64 = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";

      modules = [
        ./machines/vm-aarch64.nix

        home-manager.nixosModules.home-manager

        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          # Сохраняет старый автоматически созданный конфиг i3.
          home-manager.backupFileExtension = "hm-backup";

          home-manager.users.muhammad =
            import ./users/muhammad/home.nix;
        }
      ];
    };
  };
}
