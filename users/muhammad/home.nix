{ pkgs, ... }:

{
  home.username = "muhammad";
  home.homeDirectory = "/home/muhammad";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;

  home.packages = [
    pkgs.jetbrains-mono
  ];

  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrains Mono";
      size = 14;
    };

    settings = {
      confirm_os_window_close = 0;
      enable_audio_bell = false;
      scrollback_lines = 10000;
    };

    keybindings = {
      "super+c" = "copy_or_interrupt";
      "super+v" = "paste_from_clipboard";
      "super+equal" = "increase_font_size";
      "super+minus" = "decrease_font_size";
      "super+0" = "restore_font_size";
    };
  };

  xsession.windowManager.i3 = {
    enable = true;

    config = {
      modifier = "Mod4";
      terminal = "kitty";
      menu = "rofi -show drun";

      fonts = {
        names = [ "JetBrains Mono" ];
        size = 12.0;
      };
    };
  };
}
