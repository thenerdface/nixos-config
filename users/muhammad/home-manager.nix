{ isWSL, inputs, ... }:

{
  config,
  lib,
  pkgs,
  ...
}:

let
  isLinux = pkgs.stdenv.isLinux;

  shellAliases = {
    ga = "git add";
    gc = "git commit";
    gco = "git checkout";
    gcp = "git cherry-pick";
    gdiff = "git diff";
    gl = "git log --oneline --graph --decorate -n 20";
    gp = "git push";
    gs = "git status";
    gt = "git tag";
  }
  // lib.optionalAttrs (isLinux && !isWSL) {
    # Muscle memory from macOS hosts (needs xclip from the VM system profile).
    pbcopy = "xclip -selection clipboard";
    pbpaste = "xclip -selection clipboard -o";
  };
in
{
  home.username = "muhammad";
  home.homeDirectory = "/home/muhammad";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  programs.gh.enable = true;
  fonts.fontconfig.enable = true;
  xdg.enable = true;

  home.packages = [
    pkgs.fira-code
    pkgs.xxd
    pkgs.neovim
    pkgs.zig
    pkgs.zls
  ]
  ++ lib.optionals (isLinux && !isWSL) [
    pkgs.rofi
  ];

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_CTYPE = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    PAGER = "less -FirSwX";
  };

  # Baseline Xft settings for X11 sessions. The i3 specialisation forces Retina DPI.
  xresources.properties = lib.mkIf (!isWSL) {
    "Xft.dpi" = 96;
    "Xft.autohint" = true;
    "Xft.antialias" = true;
    "Xft.hinting" = true;
    "Xft.hintstyle" = "hintslight";
    "Xft.rgba" = "rgb";
    "Xft.lcdfilter" = "lcddefault";
  };

  home.pointerCursor = lib.mkIf (isLinux && !isWSL) {
    name = "Vanilla-DMZ";
    package = pkgs.vanilla-dmz;
    size = 128;
    x11.enable = true;
  };

  programs.fish = {
    enable = true;
    shellAliases = shellAliases;

    plugins = [
      {
        name = "theme-bobthefish";
        src = inputs.theme-bobthefish;
      }
      {
        name = "fish-fzf";
        src = inputs.fish-fzf;
      }
      {
        name = "fish-foreign-env";
        src = inputs.fish-foreign-env;
      }
    ];

    interactiveShellInit = lib.concatStringsSep "\n" [
      "source ${inputs.theme-bobthefish}/functions/fish_prompt.fish"
      "source ${inputs.theme-bobthefish}/functions/fish_right_prompt.fish"
      "source ${inputs.theme-bobthefish}/functions/fish_title.fish"
      "set -g SHELL ${pkgs.fish}/bin/fish"
      (builtins.readFile ./config.fish)
    ];
  };

  # Kitty stays the graphical terminal for i3 (and is available under GNOME).
  programs.kitty = lib.mkIf (!isWSL) {
    enable = true;
    font = {
      name = "Fira Code";
      size = 12.0;
    };
    settings = {
      foreground = "#dcdfe4";
      background = "#282c34";
      selection_foreground = "#000000";
      selection_background = "#FFFACD";
      url_color = "#0087BD";
      color0 = "#282c34";
      color8 = "#5d677a";
      color1 = "#e06c75";
      color9 = "#e06c75";
      color2 = "#98c379";
      color10 = "#98c379";
      color3 = "#e5c07b";
      color11 = "#e5c07b";
      color4 = "#61afef";
      color12 = "#61afef";
      color5 = "#c678dd";
      color13 = "#c678dd";
      color6 = "#56b6c2";
      color14 = "#56b6c2";
      color7 = "#dcdfe4";
      color15 = "#dcdfe4";
    };
    keybindings = {
      "super+v" = "paste_from_clipboard";
      "super+c" = "copy_or_interrupt";
      "ctrl+shift+equal" = "increase_font_size";
      "ctrl+shift+minus" = "decrease_font_size";
      "ctrl+shift+0" = "restore_font_size";
      "super+equal" = "increase_font_size";
      "super+minus" = "decrease_font_size";
      "super+0" = "restore_font_size";
    };
  };

  programs.i3status = lib.mkIf (!isWSL) {
    enable = true;
    general = {
      colors = true;
      color_good = "#8C9440";
      color_bad = "#A54242";
      color_degraded = "#DE935F";
    };
    modules = {
      "ipv6".enable = false;
      "wireless _first_".enable = false;
      "battery all".enable = false;
    };
  };

  # i3 Home Manager session — used when booting the `i3` specialisation.
  xsession.windowManager.i3 = lib.mkIf (!isWSL) {
    enable = true;
    config = {
      modifier = "Mod4";
      terminal = "kitty";
      menu = "rofi -show drun";
      fonts = {
        names = [ "Fira Code" ];
        size = 8.0;
      };
      focus.followMouse = false;
      window = {
        titlebar = false;
        border = 2;
      };
      floating = {
        titlebar = false;
        border = 2;
      };
      bars = [
        {
          position = "bottom";
          statusCommand = "${pkgs.i3status}/bin/i3status";
          fonts = {
            names = [ "Fira Code" ];
            size = 8.0;
          };
          colors.background = "#1D1F21";
        }
      ];
      keybindings = lib.mkOptionDefault {
        "Mod4+v" = null;
      };
    };
  };

  # Live Neovim tree: edit Lua without a Nix rebuild. Clone the repo to ~/nixos-config.
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-config/users/muhammad/nvim";
}
