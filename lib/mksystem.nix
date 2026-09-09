# Build a NixOS system the same way mitchellh/nixos-config does:
# one factory, explicit machine + user modules, shared Home Manager wiring.
{ nixpkgs, inputs }:

name:
{
  system,
  user,
  wsl ? false,
}:

let
  isWSL = wsl;

  machineConfig = ../machines/${name}.nix;
  userOSConfig = ../users/${user}/nixos.nix;
  userHMConfig = ../users/${user}/home-manager.nix;

  inherit (nixpkgs.lib) optionals;
in
nixpkgs.lib.nixosSystem {
  inherit system;

  modules = [
    machineConfig
    userOSConfig
  ]
  ++ optionals isWSL [
    inputs.nixos-wsl.nixosModules.wsl
  ]
  ++ [
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "hm-backup";
      home-manager.users.${user} = import userHMConfig {
        inherit inputs isWSL;
      };
    }
    {
      config._module.args = {
        currentSystem = system;
        currentSystemName = name;
        currentSystemUser = user;
        inherit isWSL inputs;
      };
    }
  ];
}
