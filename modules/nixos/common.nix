{ pkgs, ... }:

{
  # Fish is the login shell declared by the user module.
  programs.fish.enable = true;

  # Enable the modern Nix CLI and flakes on every managed NixOS host.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Console development tools shared by the VM and WSL.
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
}
