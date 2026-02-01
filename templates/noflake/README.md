# Den without flake-parts

This template provides an example Den setup with stable Nix (no-flakes), no flake-parts and nix-maid instead of home-manager.

It configures a NixOS host with one user.

Try it with:

```
nix-build -A flake.nixosConfigurations.igloo.config.system.build.toplevel
```

NOTE: Currently Den needs a top-level attribute where to place configurations,
by default it is the `flake` attribute, even if Den uses no flake-parts at all.
