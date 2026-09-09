# Shared settings for graphical NixOS VMs (not WSL).
# Host-specific hypervisor/network/disk facts stay in machines/vm-*.nix.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../modules/nixos/common.nix
    ../modules/virtualisation/docker.nix
    ../modules/specialization/i3.nix
    ../modules/specialization/plasma.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Some VM firmware only supports console mode 0.
  boot.loader.systemd-boot.consoleMode = "0";

  time.timeZone = "Europe/Moscow";

  i18n.defaultLocale = "en_US.UTF-8";

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      fira-code
      jetbrains-mono
    ];
  };

  services.openssh.enable = true;

  # Default desktop. Specialisations (i3, plasma) appear in the boot menu.
  # Inside a specialisation build, `specialisation` is empty so this block
  # does not fight the specialised display stack.
  services.xserver = lib.mkIf (config.specialisation != { }) {
    enable = true;
    xkb.layout = "us";
  };
  services.desktopManager = lib.mkIf (config.specialisation != { }) {
    gnome.enable = true;
  };
  services.displayManager = lib.mkIf (config.specialisation != { }) {
    gdm.enable = true;
  };

  environment.systemPackages = with pkgs; [
    gnumake
    killall
    xclip
    # VMware clipboard integration needs this on aarch64 guests.
    gtkmm3
    # Always available; i3 specialisation also pulls Kitty as the WM terminal.
    kitty
  ];

  # Do not bump during normal upgrades; it preserves stateful defaults.
  system.stateVersion = "26.05";
}
