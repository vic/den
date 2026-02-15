# Den without flake-parts

This template provides an example Den setup with stable Nix (no-flakes), no flake-parts and nix-maid instead of home-manager.

It configures a NixOS host with one user.

Try it with:

```shell
npins update den # make sure you use latest Den
```

```shell
nixos-rebuild build --file . -A flake.nixosConfigurations.igloo
```

or

```shell
nix-build -A flake.nixosConfigurations.igloo.config.system.build.toplevel
```

> NOTE: Den needs a top-level attribute where to place configurations.
> For convenience, it is the `flake` top-level attribute, following the
> flake outputs schema, even if Den does not needs flakes / flake-parts.
