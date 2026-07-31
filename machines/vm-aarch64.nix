{ pkgs, ... }:

{
  # Позволяет ARM-виртуалке запускать x86_64-программы.
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

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

  # X11/i3 — адаптация специализации i3 из конфигурации Хашимото.
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    dpi = 220;

    # У Хашимото xterm также отключён.
    desktopManager.xterm.enable = false;

    displayManager = {
      lightdm.enable = true;

      # VMware иногда оставляет X11 в старом разрешении после полноэкранных
      # приложений или изменения размера окна. Применяем preferred-режим
      # перед LightDM и ещё раз при запуске пользовательской сессии.
      setupCommands = ''
        ${pkgs.xrandr}/bin/xrandr --output Virtual-1 --auto
      '';
      sessionCommands = ''
        ${pkgs.xrandr}/bin/xrandr --output Virtual-1 --auto
        ${pkgs.xset}/bin/xset r rate 200 40
      '';
    };

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
    go
    git
    neovim
    gcc
    gnumake
    cmake
    ninja
    gettext
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

    # Та же ручная команда восстановления разрешения, что у Хашимото.
    (pkgs.writeShellScriptBin "xrandr-auto" ''
      ${pkgs.xrandr}/bin/xrandr --output Virtual-1 --auto
    '')
  ];

  system.stateVersion = "26.05";
}
