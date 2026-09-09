{ currentSystemUser, ... }:

{
  imports = [
    ../modules/nixos/common.nix
  ];

  # Platform belongs to the host configuration rather than flake wiring.
  nixpkgs.hostPlatform = "x86_64-linux";

  wsl = {
    enable = true;
    defaultUser = currentSystemUser;

    # Windows drives appear as /mnt/c, /mnt/d, etc.
    wslConf.automount.root = "/mnt";

    # Adds Linux app shortcuts to the Windows start menu when supported.
    startMenuLaunchers = true;
  };

  # NixOS-WSL owns resolv.conf.
  networking.resolvconf.enable = false;

  # Do not bump during normal upgrades; it preserves stateful defaults.
  system.stateVersion = "26.05";
}
