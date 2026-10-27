_: {
  flake.nixosModules.nixSettings = {
    nixpkgs.config = {
      allowUnfree = true;
      # Zotero 10 still embeds Firefox ESR 140 after its upstream end of life.
      permittedInsecurePackages = [ "firefox-esr-140-bin-unwrapped-140.17.0esr" ];
    };
    nix = {
      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
      settings.auto-optimise-store = true;
      # The jj working copy is always a real commit, so the dirty-tree warning
      # every nix command would print means nothing here.
      settings.warn-dirty = false;
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };
    };
  };
}
