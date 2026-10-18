{
  moduleWithSystem,
  self,
  inputs,
  ...
}:
{
  flake.nixosModules.base = moduleWithSystem (
    { inputs', ... }:
    { pkgs, ... }:
    {
      imports = with self.nixosModules; [
        kitty
        goproWebcam
        inputs.nix-index-database.nixosModules.default
      ];
      programs.nix-index-database.comma.enable = true;

      environment.systemPackages = with pkgs; [
        fishPlugins.tide
        thunderbird
        inputs'.zen-browser.packages.default
        zotero
        kdePackages.okular
        calibre
        wdisplays

        nautilus
        showtime
        decibels
        loupe

        teamviewer
      ];
      services.teamviewer.enable = true;

      # printing/scanning
      hardware.sane.enable = true;
      services.avahi.enable = true;
      services.avahi.nssmdns = true;
    }
  );
}
