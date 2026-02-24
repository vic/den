---
title: "Template: No-Flake"
description: Using Den with stable Nix — no flakes needed.
---

The noflake template shows that Den works perfectly without Nix flakes. It uses [npins](https://github.com/andir/npins) for dependency management and works with stable Nix.

## Initialize

Since this template doesn't use flakes, clone it manually:

```console
mkdir my-nix && cd my-nix
cp -r $(nix eval --raw 'github:vic/den#templates.noflake.path')/* .
npins update den
```

Or use `nix flake init` if you have flakes enabled:

```console
nix flake init -t github:vic/den#noflake
```

## Project Structure

```
default.nix        # entry point (replaces flake.nix)
with-inputs.nix    # input resolver (replaces flake.lock)
npins/
  default.nix      # npins fetcher
  sources.json     # pinned dependencies
modules/
  den.nix          # host/user declarations + aspects
```

## File by File

### default.nix — Entry Point

```nix
let
  outputs = inputs:
    (inputs.nixpkgs.lib.evalModules {
      modules = [ (inputs.import-tree ./modules) ];
      specialArgs = {
        inherit inputs;
        inherit (inputs) self;
      };
    }).config;
in
import ./with-inputs.nix outputs
```

This is the noflake equivalent of `flake.nix`. It uses `lib.evalModules` directly — the same mechanism Den uses internally.

### with-inputs.nix — Input Resolution

This file resolves npins sources into a flake-compatible `inputs` attrset. It reads `flake.nix` from each dependency to discover transitive inputs and wires them together.

### modules/den.nix — Configuration

```nix
{ inputs, ... }:
{
  imports = [ inputs.den.flakeModule ];

  den.default.nixos = {
    fileSystems."/".device = "/dev/fake";
    boot.loader.grub.enable = false;
  };

  den.hosts.x86_64-linux.igloo.users.tux = { };

  den.aspects.igloo = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.vim ];
    };
  };

  den.aspects.tux = {
    nixos = {
      imports = [ inputs.nix-maid.nixosModules.default ];
      users.users.tux = {
        isNormalUser = true;
        maid.file.home.".gitconfig".text = ''
          [user]
            name=Tux
        '';
      };
    };
  };
}
```

Notable differences from the flake templates:
- Uses [nix-maid](https://github.com/viperML/nix-maid) instead of Home-Manager (lighter alternative)
- User config is done directly in `nixos` class (no HM class needed)

## Build

```console
npins update den
nixos-rebuild build --file . -A flake.nixosConfigurations.igloo
```

Or with `nix-build`:

```console
nix-build -A flake.nixosConfigurations.igloo.config.system.build.toplevel
```

:::note
Den places configurations under the `flake` attribute following the flake outputs schema, even without flakes. This is the default top-level attribute for Den output.
:::

## What It Provides

| Feature | Provided |
|---------|:--------:|
| NixOS host configuration | ✓ |
| No flakes required | ✓ |
| npins dependency pinning | ✓ |
| nix-maid (HM alternative) | ✓ |
| Home-Manager | ✗ (use nix-maid) |
| flake-parts | ✗ |

## Next Steps

- Read [Use Without Flakes](/guides/no-flakes/) for more details on flake-free usage
- Consider the [Minimal template](/tutorials/minimal/) if you want flakes but not flake-parts
