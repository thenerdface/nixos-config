{ pkgs, lib, inputs, config, ... }:

{
  home.username = "muhammad";
  home.homeDirectory = "/home/muhammad";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
  fonts.fontconfig.enable = true;

  home.packages = [
    pkgs.fira-code
  ];

  # Те же Xft-параметры, что у Хашимото.
  xresources.properties = {
    "Xft.dpi" = 180;
    "Xft.autohint" = true;
    "Xft.antialias" = true;
    "Xft.hinting" = true;
    "Xft.hintstyle" = "hintslight";
    "Xft.rgba" = "rgb";
    "Xft.lcdfilter" = "lcddefault";
  };

  programs.fish = {
    enable = true;

    plugins = [
      {
        name = "theme-bobthefish";
        src = inputs.theme-bobthefish;
      }
    ];

    interactiveShellInit = ''
      source ${inputs.theme-bobthefish}/functions/fish_prompt.fish
      source ${inputs.theme-bobthefish}/functions/fish_right_prompt.fish
      source ${inputs.theme-bobthefish}/functions/fish_title.fish

      set -g SHELL ${pkgs.fish}/bin/fish
      set -g fish_greeting
      set -g theme_color_scheme dracula

      # SSH agent: адаптация актуальной логики Хашимото.
      function __ssh_agent_is_started
        if test -f $SSH_ENV; and test -z "$SSH_AGENT_PID"
          source $SSH_ENV > /dev/null
        end

        if test -z "$SSH_AGENT_PID"
          return 1
        end

        ssh-add -l > /dev/null 2>&1
        if test $status -eq 2
          return 1
        end
      end

      function __ssh_agent_start
        ssh-agent -c | sed 's/^echo/#echo/' > $SSH_ENV
        chmod 600 $SSH_ENV
        source $SSH_ENV > /dev/null
        ssh-add ~/.ssh/id_ed25519_github > /dev/null 2>&1
      end

      if not test -d $HOME/.ssh
        mkdir -p $HOME/.ssh
        chmod 0700 $HOME/.ssh
      end

      if test -z "$SSH_ENV"
        set -xg SSH_ENV $HOME/.ssh/environment
      end

      if not __ssh_agent_is_started
        __ssh_agent_start
      end

      set -U fish_color_normal normal
      set -U fish_color_command F8F8F2
      set -U fish_color_quote F1FA8C
      set -U fish_color_redirection 8BE9FD
      set -U fish_color_end 50FA7B
      set -U fish_color_error FF5555
      set -U fish_color_param 5FFFFF
      set -U fish_color_comment 6272A4
      set -U fish_color_match --background=brblue
      set -U fish_color_selection white --bold --background=brblack
      set -U fish_color_search_match bryellow --background=brblack
      set -U fish_color_history_current --bold
      set -U fish_color_operator 00a6b2
      set -U fish_color_escape 00a6b2
      set -U fish_color_cwd green
      set -U fish_color_cwd_root red
      set -U fish_color_valid_path --underline
      set -U fish_color_autosuggestion BD93F9
      set -U fish_color_user brgreen
      set -U fish_color_host normal
    '';
  };

  programs.kitty = {
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
      "super+equal" = "increase_font_size";
      "super+minus" = "decrease_font_size";
      "super+0" = "restore_font_size";
    };
  };

  programs.i3status = {
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

  xsession.windowManager.i3 = {
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

      # Command+V должен доходить до Kitty.
      keybindings = lib.mkOptionDefault {
        "Mod4+v" = null;
      };
    };
  };

  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nixos-config/users/muhammad/nvim";
}
