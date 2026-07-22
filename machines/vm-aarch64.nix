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

  # VMware DNS-прокси 172.16.45.2 в нашей NAT-сети не отвечает.
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

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
