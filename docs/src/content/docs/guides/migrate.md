---
title: Migrate to Den
description: Incrementally adopt Den in existing Nix configurations.
---

## Start Small

Den can be adopted incrementally. You don't need to rewrite your entire
configuration — start by adding one Den-managed host alongside your
existing setup.

## From Flake-Parts Dendritic

If you're already using `flake.modules`, migration is direct:

```nix
# Before (flake-parts dendritic)
flake.modules.nixos.desktop = { ... };
flake.modules.homeManager.games = { ... };

# After (Den)
den.aspects.desktop.nixos = { ... };
den.aspects.games.homeManager = { ... };
```

## Import Existing Modules

You don't need to convert all modules. Import them directly:

```nix
{ inputs, ... }: {
  den.aspects.desktop.nixos.imports = [
    inputs.disko.nixosModules.disko
    inputs.self.modules.nixos.desktop  # existing module
  ];
}
```

## Mix Den with Existing nixosSystem

Use `mainModule` to integrate Den into existing configurations:

```nix
let
  denCfg = (lib.evalModules {
    modules = [ (import-tree ./modules) ];
    specialArgs = { inherit inputs; };
  }).config;
in
  lib.nixosSystem {
    modules = [
      ./hardware-configuration.nix  # your existing modules
      ./networking.nix
      denCfg.den.hosts.x86_64-linux.igloo.mainModule  # Den modules
    ];
  }
```

## Use import-tree for Gradual Migration

The [`import-tree`](/reference/batteries/#import-tree) battery auto-imports files by class directory:

```
non-dendritic/
  hosts/
    my-laptop/
      _nixos/
        hardware.nix
        networking.nix
      _homeManager/
        shell.nix
```

```nix
den.ctx.host.includes = [
  (den._.import-tree._.host ./non-dendritic/hosts)
];
```

Files in `_nixos/` import as NixOS modules, `_homeManager/` as HM modules.

## Access Den Configurations Directly

Den's outputs are standard Nix configurations:

```nix
# These are normal nixosSystem / homeManagerConfiguration results
config.flake.nixosConfigurations.igloo
config.flake.homeConfigurations.tux
```

Expose them directly in your flake outputs alongside existing ones.

## Recommended Migration Path

1. Add Den inputs to your flake
2. Create a `modules/` directory with `hosts.nix`
3. Add one host with `den.hosts`
4. Move one aspect at a time from existing modules
5. Use `import-tree` for files you haven't converted yet
6. Gradually expand Den-managed aspects
