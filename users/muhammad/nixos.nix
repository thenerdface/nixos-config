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

    hashedPassword = "$6$UGtJ0WQnQQyAhQS7$sr40Wz3zFEM2hI73TeJhLjEUn2g.kySH1Vf9JVgs/wbVp4/VetWuymEGlbrr..m4QoFZCqP6kMOieWEKPCXuL.";

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKZWzcVdxituxDNnlxkAsrjXZ4uVOgoyT9EhloUPHcBP muhammad@nixos-vm"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
