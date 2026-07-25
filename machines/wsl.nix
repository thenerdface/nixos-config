{ pkgs, ... }:

{
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

  programs.fish.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Только консольные инструменты. Kitty, i3 и прочую графику сюда не добавляем.
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
  ];

  system.stateVersion = "26.05";
}
