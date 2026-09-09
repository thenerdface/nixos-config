# i3 on X11 — selectable from the systemd-boot menu as a NixOS specialisation.
{
  pkgs,
  lib,
  currentSystemUser,
  ...
}:
{
  specialisation.i3.configuration = {
    # Portal support helps Flatpak and other desktop apps behave under i3.
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = "*";
    };

    services.xserver = {
      enable = true;
      xkb.layout = "us";
      # Retina guest: VMware exposes the native panel resolution; draw at 2x.
      dpi = 192;

      desktopManager = {
        xterm.enable = false;
        wallpaper.mode = "fill";
      };

      displayManager = {
        lightdm.enable = true;
        sessionCommands = ''
          ${pkgs.xset}/bin/xset r rate 200 40
        '';
      };

      windowManager.i3.enable = true;
    };

    services.displayManager.defaultSession = "none+i3";

    # Grayscale AA avoids colored fringes on Retina under X11.
    home-manager.users.${currentSystemUser}.xresources.properties = {
      "Xft.dpi" = lib.mkForce 192;
      "Xft.rgba" = lib.mkForce "none";
    };

    environment.systemPackages = with pkgs; [
      kitty
      i3status
      rofi
      xclip
    ];
  };
}
