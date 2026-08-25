{ pkgs, lib, ... }:

{
  # Platform belongs to the host configuration rather than flake wiring.
  nixpkgs.hostPlatform = "aarch64-linux";

  # Позволяет ARM-виртуалке запускать x86_64-программы.
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  imports = [
    ./hardware/vm-aarch64.nix
    ../modules/nixos/common.nix
    ../modules/virtualisation/docker.nix
  ];

  # VMware запускает VM через UEFI.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "vm-aarch64";

  # В этой VM сетевой интерфейс называется enp2s0.
  networking.interfaces.enp2s0.useDHCP = true;

  # DHCP нужен для адреса и маршрута, но не должен переписывать DNS.
  networking.dhcpcd.extraConfig = ''
    nohook resolv.conf
  '';
  networking.resolvconf.enable = false;
  environment.etc."resolv.conf".text = ''
    nameserver 1.1.1.1
    nameserver 8.8.8.8
  '';

  # Интеграция NixOS с VMware Fusion.
  virtualisation.vmware.guest.enable = true;

  # Общая папка macOS через VMware Fusion — как у Хашимото.
  fileSystems."/host" = {
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    device = ".host:/";
    options = [
      "umask=22"
      "uid=1000"
      "gid=1000"
      "allow_other"
      "auto_unmount"
      "defaults"
    ];
  };

  # Retina: VMware отдаёт гостю нативное разрешение экрана, поэтому интерфейс
  # должен отрисовываться с честным масштабом 2x, а не растягиваться из 96 DPI.
  # Так текст остаётся нормального размера и резким после reboot/rebuild.
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    dpi = 192;

    # У Хашимото xterm также отключён.
    desktopManager.xterm.enable = false;

    displayManager.lightdm.enable = true;
    windowManager.i3.enable = true;
  };

  # Переопределение только для Retina-VM. Общий Home Manager модуль не меняется.
  # Grayscale antialiasing лучше подходит для Retina и не даёт цветных краёв.
  home-manager.users.muhammad.xresources.properties = {
    "Xft.dpi" = lib.mkForce 192;
    "Xft.rgba" = lib.mkForce "none";
  };

  services.displayManager.defaultSession = "none+i3";

  # Нужен для управления VM с терминала macOS.
  services.openssh.enable = true;

  # Графические инструменты нужны только в VM; консольный набор общий с WSL.
  environment.systemPackages = with pkgs; [
    kitty
    i3status
    rofi
    xclip
    gtkmm3
  ];

  # Do not bump this during normal upgrades; it preserves stateful defaults.
  system.stateVersion = "26.05";
}
