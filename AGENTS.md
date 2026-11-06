# Repository guidance

- Keep this personal NixOS config simple. Prefer direct, literal configuration over options or shared modules with only one consumer. Generalize when a third use makes it worthwhile.
- Put machine-specific settings, hardware workarounds, and `system.stateVersion` in the relevant host. Keep comments brief and focused on why something is needed.
- Use `jj` for version control; do not use `git add` or `git commit`. Commit messages follow `scope: lowercase summary`.
- `flake.nix` loads every `.nix` file under `modules/` through `import-tree`; files do not need explicit registration. Host configs live under `modules/hosts/`, reusable programs under `modules/features/`, bundles under `modules/attrs/`, and shared system config under `modules/system/`.
- Prefer `wrapper-modules` for program configuration. Edit the feature module's settings instead of generated config. Each feature needs both a package and a NixOS module that installs it; ensure a host or bundle imports that module.
- Run `nix fmt` after Nix edits and review its changes. Use `nix flake check` as the correctness gate. Only run `nixos-rebuild switch` when explicitly asked.
