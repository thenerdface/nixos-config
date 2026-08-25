{ ... }:

{
  imports = [
    ../modules/nixos/common.nix
  ];

  # Platform belongs to the host configuration rather than flake wiring.
  nixpkgs.hostPlatform = "x86_64-linux";

  # Запускаем NixOS внутри Windows WSL.
  wsl = {
    enable = true;
    defaultUser = "muhammad";

    # Диски Windows будут доступны как /mnt/c, /mnt/d и так далее.
    wslConf.automount.root = "/mnt";

    # Добавляет ярлыки Linux-программ в меню Windows, когда это поддерживается.
    startMenuLaunchers = true;
  };

  # NixOS-WSL сам управляет сетевыми настройками.
  networking.resolvconf.enable = false;

  # Do not bump this during normal upgrades; it preserves stateful defaults.
  system.stateVersion = "26.05";
}
