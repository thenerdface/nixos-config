{ pkgs, ... }:

{
  imports = [
    ./hardware/vm-aarch64.nix
    ../users/muhammad.nix
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

  # X11/i3 — адаптация специализации i3 из конфигурации Хашимото.
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    dpi = 220;

    # У Хашимото xterm также отключён.
    desktopManager.xterm.enable = false;

    displayManager.lightdm.enable = true;
    windowManager.i3.enable = true;
  };

  services.displayManager.defaultSession = "none+i3";

  # Нужен для управления VM с терминала macOS.
  services.openssh.enable = true;

  # Fish зарегистрирован как системная оболочка.
  programs.fish.enable = true;

  # Разрешаем команды nix и работу с flakes.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Минимальные инструменты для Git и Kickstart.nvim.
  environment.systemPackages = with pkgs; [
    git
    neovim
    gcc
    gnumake
    ripgrep
    fd
    tree-sitter
    unzip
    curl

    kitty
    i3status
    rofi
    xclip
    gtkmm3
  ];

  system.stateVersion = "26.05";
}
