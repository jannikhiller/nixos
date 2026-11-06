{
  inputs,
  moduleWithSystem,
  ...
}:
{
  flake.nixosModules.kitty = moduleWithSystem (
    { self', ... }: {
      environment.systemPackages = [ self'.packages.myKitty ];
    }
  );

  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages.myKitty = inputs.wrapper-modules.wrappers.kitty.wrap {
        inherit pkgs;
        settings = {
          font_family = "JetBrainsMono Nerd Font";
          font_size = 11;
          bold_font = "auto";
          italic_font = "auto";

          window_padding_width = 8;
          confirm_os_window_close = 0;
          enable_audio_bell = false;
          cursor_shape = "beam";
          cursor_blink_interval = 0;

          scrollback_lines = 10000;
          shell_integration = "enabled";

          tab_bar_style = "hidden";
          hide_window_decorations = "yes";
          background_opacity = "0.92";
        };

        extraConfig = ''
          include ''${HOME}/.config/kitty/themes/noctalia.conf
        '';

      };

    };

}
