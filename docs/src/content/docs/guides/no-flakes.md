---
title: Use Without Flakes
description: Den works with stable Nix, npins, and without flake-parts.
---

## Den is Flake-Agnostic

Den does **not** require Nix flakes. It works with:

- Nix flakes + flake-parts (most common)
- Nix flakes without flake-parts
- No flakes at all (stable Nix + npins or fetchTarball)

## Without Flakes

Use `flake-compat` to evaluate Den from a non-flake setup:

```nix
# default.nix
let
  flake = import (fetchTarball {
    url = "https://github.com/edolstra/flake-compat/archive/...tar.gz";
  }) { src = ./.; };
in
  flake.outputs
```

See the [`noflake` template](https://github.com/vic/den/tree/main/templates/noflake)
for a complete working example with npins.

## Without Flake-Parts

Den provides its own minimal `flake` option when flake-parts is not present.
Simply import `inputs.den.flakeModule`:

```nix
let
  denCfg = (lib.evalModules {
    modules = [
      (import-tree ./modules)
      inputs.den.flakeModule
    ];
    specialArgs = { inherit inputs; };
  }).config;
in {
  nixosConfigurations.igloo =
    denCfg.flake.nixosConfigurations.igloo;
}
```

## With Flake-Parts

The standard setup — Den integrates seamlessly:

```nix
{
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; }
      (inputs.import-tree ./modules);

  inputs = {
    den.url = "github:vic/den";
    flake-aspects.url = "github:vic/flake-aspects";
    import-tree.url = "github:vic/import-tree";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
}
```

## The Dendritic Module

For flake-parts users who want automatic Den + flake-aspects setup:

```nix
imports = [ inputs.den.flakeModules.dendritic ];
```

This auto-configures `flake-file` inputs for `den` and `flake-aspects`.

## Minimal Dependencies

Den's only hard dependency is `flake-aspects`. Everything else is optional:

| Dependency | Required? | Purpose |
|-----------|-----------|---------|
| `flake-aspects` | **Yes** | [Aspect composition](https://github.com/vic/flake-aspects) |
| `import-tree` | Optional | [Auto-import module directories](https://github.com/vic/import-tree) |
| `flake-parts` | Optional | Flake structuring |
| `nixpkgs` | Optional | Only if building NixOS/HM configs |
| `home-manager` | Optional | Only if using HM integration |
