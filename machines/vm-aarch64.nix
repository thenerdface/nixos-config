{ ... }:

{
  # Platform belongs to the host configuration rather than flake wiring.
  nixpkgs.hostPlatform = "aarch64-linux";

  # Lets the ARM guest run x86_64 binaries when needed.
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  imports = [
    ./hardware/vm-aarch64.nix
    ./vm-shared.nix
  ];

  networking.hostName = "vm-aarch64";

  # On this VMware guest the interface is enp2s0.
  networking.interfaces.enp2s0.useDHCP = true;

  # DHCP for address/route only — VMware NAT DNS is unreliable, so pin resolvers.
  networking.dhcpcd.extraConfig = ''
    nohook resolv.conf
  '';
  networking.resolvconf.enable = false;
  environment.etc."resolv.conf".text = ''
    nameserver 1.1.1.1
    nameserver 8.8.8.8
  '';

  virtualisation.vmware.guest.enable = true;

  # macOS shared folders via VMware Fusion, same pattern as mitchellh.
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
}
