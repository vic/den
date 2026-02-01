# Den without flake-parts

This template provides an example Den setup with stable Nix (no-flakes), no flake-parts and nix-maid instead of home-manager.

It configures a NixOS host with one user.

Try it with:

```shell
nixos-rebuild build --file . -A nixosConfigurations.igloo
```

or

```shell
nix-build -A nixosConfigurations.igloo.config.system.build.toplevel
```
