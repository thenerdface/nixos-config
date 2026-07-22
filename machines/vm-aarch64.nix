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

  # Интеграция NixOS с VMware Fusion.
  virtualisation.vmware.guest.enable = true;

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
  ];

  system.stateVersion = "26.05";
}
