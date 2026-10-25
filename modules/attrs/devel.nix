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

      programs.fish.interactiveShellInit = ''
        # Explicit fish bypasses devenv 2.3.1's broken shell session layer.
        devenv hook fish -- fish | source
      '';

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
