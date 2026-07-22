{ pkgs, ... }:

{
  users.users.muhammad = {
    isNormalUser = true;
    home = "/home/muhammad";
    extraGroups = [ "wheel" ];
    shell = pkgs.bashInteractive;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK4PiqguA69CqKLAsUUisiffwAYFVZIyT5wRzaa1+y1j muhammad@nixos-vm"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
}
