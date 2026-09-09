{ pkgs, ... }:

{
  # Fish is the login shell declared by the user module.
  programs.fish.enable = true;

  # Enable the modern Nix CLI and flakes on every managed NixOS host.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.keep-outputs = true;
  nix.settings.keep-derivations = true;

  # Console development tools shared by the VM and WSL.
  # User-facing applications live in Home Manager.
  environment.systemPackages = with pkgs; [
    go
    git
    gcc
    gnumake
    cmake
    ninja
    gettext
    ripgrep
    fd
    fzf
    tree-sitter
    unzip
    curl
  ];
}
