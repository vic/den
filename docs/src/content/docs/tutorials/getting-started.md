---
title: Getting Started
description: Set up your first Den project from scratch.
---

## Prerequisites

- [Nix](https://nixos.org/download) with flakes enabled (or use [without flakes](/guides/no-flakes/))
- Basic familiarity with Nix modules

## Quick Start — Launch the Demo VM

Try Den instantly without installing anything:

```console
nix run github:vic/den
```

## Initialize a New Project

Create a fresh Den-based flake:

```console
mkdir my-infra && cd my-infra
nix flake init -t github:vic/den
nix flake update den
```

This creates a project with:

```
flake.nix          # inputs and entry point
modules/           # your Den modules go here
  hosts.nix        # host and user declarations
  aspects/         # aspect definitions
```

## Your flake.nix

The generated `flake.nix` imports Den and uses `import-tree` to load all modules:

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

## Declare a Host

In `modules/hosts.nix`, declare your first host:

```nix
{
  den.hosts.x86_64-linux.my-laptop.users.vic = { };
}
```

This single line creates:
- A NixOS host named `my-laptop` on `x86_64-linux`
- A user `vic` with Home-Manager support
- Aspects `den.aspects.my-laptop` and `den.aspects.vic`

## Build It

```console
nixos-rebuild switch --flake .#my-laptop
```

## Available Templates

| Template | Description |
|----------|-------------|
| `default` | Batteries-included layout |
| `minimal` | Minimalistic Den flake |
| `noflake` | No flakes, no flake-parts |
| `example` | Examples and patterns |
| `ci` | Feature test suite |
| `bogus` | Bug reproduction |

```console
nix flake init -t github:vic/den#minimal
```

## Next Steps

- [Your First Aspect](/tutorials/first-aspect/) — write cross-class configs
- [Context-Aware Configs](/tutorials/context-aware/) — make aspects react to context
