{ self, ... }: {
  flake.nixosModules.desktop =
    {
      pkgs,
      lib,
      ...
    }:
    {
      imports = with self.nixosModules; [
        niri
        noctalia
        homeManager
        core
        user
      ];
      services = {
        displayManager.noctalia-greeter = {
          enable = true;
          passwordlessSyncUsers = [ "jannik" ];
          settings.keyboard.layout = "de";
        };
        xserver.xkb = {
          layout = "de";
          variant = "";
          options = "lv3:caps_switch";
        };
        printing.enable = true;
        upower.enable = true;
        gvfs.enable = true;
        udisks2.enable = true;
      };

      # Reuse the layout above for the TTYs instead of the us default.
      console.useXkbConfig = true;

      hardware.bluetooth.enable = true;

      programs.dconf.enable = true;

      fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        adwaita-fonts
        noto-fonts
        noto-fonts-color-emoji
      ];

      # sessionVariables, not variables: greetd launches niri-session without a
      # login shell, so /etc/set-environment is never sourced.
      environment.sessionVariables = {
        XCURSOR_THEME = "Adwaita";
        XCURSOR_SIZE = "24";
        # gamescope's own Xwayland doesn't pick up niri's xkb config.
        XKB_DEFAULT_LAYOUT = "de";
        XKB_DEFAULT_OPTIONS = "lv3:caps_switch";
        QT_QPA_PLATFORMTHEME = "qt6ct";
      };

      environment.systemPackages = with pkgs; [
        adwaita-icon-theme
        qt6Packages.qt6ct
        # glib runs Terminal=true entries (nvim's) via a fixed list of terminals
        # that kitty is not on; xdg-terminal-exec is on it and finds kitty.
        xdg-terminal-exec
      ];

      home-manager.sharedModules = [
        (
          { config, ... }:
          {
            services.udiskie = {
              enable = true;
              settings.program_options.file_manager = lib.getExe pkgs.nautilus;
            };
            gtk = {
              enable = true;
              colorScheme = "dark";
              theme = {
                package = pkgs.adw-gtk3;
                name = "adw-gtk3-dark";
              };
              gtk3.bookmarks = [
                "file:///home/jannik/syncthing"
                "file:///home/jannik/syncthing/uni/ma"
                "file:///home/jannik/Downloads"
              ];
            };

            xdg.configFile."qt6ct/qt6ct.conf".text = ''
              [Appearance]
              color_scheme_path=${config.xdg.configHome}/qt6ct/colors/noctalia.conf
              custom_palette=true
              style=Fusion
            '';

            # Unmanaged, xdg-user-dirs-update points every XDG dir at $HOME as
            # long as the directories are missing, leaving nautilus' sidebar empty.
            xdg.userDirs = {
              enable = true;
              createDirectories = true;
              desktop = null;
              projects = null;
              publicShare = null;
              templates = null;
            };
          }
        )
      ];
    };
}
