{
  moduleWithSystem,
  self,
  ...
}:
{
  flake.nixosModules.devel = moduleWithSystem (
    _:
    { pkgs, ... }:
    {
      imports = with self.nixosModules; [
        jujutsu
        neovim
        tmux
      ];

      # Codex 0.157's socket isolation rejects Btrfs device IDs that differ
      # from mountinfo. Keep its /tmp rendezvous directory on tmpfs instead.
      boot.tmp.useTmpfs = true;

      programs.fish.interactiveShellInit = ''
        # Explicit fish bypasses devenv 2.3.1's broken shell session layer.
        devenv hook fish -- fish | source
      '';

      virtualisation.docker.rootless = {
        enable = true;
        setSocketVariable = true;
      };

      environment.systemPackages = with pkgs; [
        ripgrep
        fd
        git
        claude-code
        codex
        devenv
        gh
      ];
    }
  );
}
