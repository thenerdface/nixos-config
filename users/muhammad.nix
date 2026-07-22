{ pkgs, ... }:

{
  users.mutableUsers = false;


  users.users.muhammad = {
    isNormalUser = true;
    home = "/home/muhammad";
    extraGroups = [ "wheel" ];
    shell = pkgs.bashInteractive;

    hashedPassword = "$6$42pkKA9Gi7LONNJr$jPxO/fnkKv4nQPJVqtIhe5IFRAnKkBUG7qwFY1O.kweF4FinfRRWZqHyJE0tzFMRLo9ro9Wq58GujeZ4BMILM1";

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK4PiqguA69CqKLAsUUisiffwAYFVZIyT5wRzaa1+y1j muhammad@nixos-vm"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
