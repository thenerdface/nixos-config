{ ... }:

{
  # Docker Engine and the Compose CLI plugin are supplied by the NixOS module.
  virtualisation.docker = {
    enable = true;

    # Remove old, unused images and build cache once a week. Volumes are not
    # pruned automatically, so the project's PostgreSQL data is not touched.
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [ "--filter=until=168h" ];
    };
  };

  # Convenient for a dedicated development VM. Membership in the docker group
  # is effectively root-equivalent, so do not use this VM for untrusted users.
  users.users.muhammad.extraGroups = [ "docker" ];

  # Frontend and API are reachable from the macOS host by the VM's IP address.
  networking.firewall.allowedTCPPorts = [ 5173 8787 ];
}
