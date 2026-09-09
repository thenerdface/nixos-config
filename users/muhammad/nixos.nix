{ pkgs, ... }:

{
  # home-manager fish completions and related paths.
  environment.pathsToLink = [ "/share/fish" ];
  environment.localBinInPath = true;

  programs.fish.enable = true;

  # Helps Neovim plugin native binaries (and similar) find dynamic libraries.
  programs.nix-ld.enable = true;

  users.mutableUsers = false;

  users.users.muhammad = {
    isNormalUser = true;
    home = "/home/muhammad";
    extraGroups = [ "wheel" ];
    shell = pkgs.fish;

    hashedPassword = "$6$bPqbcWEIPswf8UvX$lyRlTCvUcGBTUQk/aqIJu0malOsbE6opZN5.IwuL996pX0FwgvIcvD2jKO7xl5cD2a07iwI4jNENdSrMxCHQ3/";

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKZWzcVdxituxDNnlxkAsrjXZ4uVOgoyT9EhloUPHcBP muhammad@nixos-vm"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
