# KDE Plasma 6 (Wayland) — selectable from the systemd-boot menu.
{ ... }:
{
  specialisation.plasma.configuration = {
    services.xserver.enable = true;
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
    services.desktopManager.plasma6.enable = true;
  };
}
