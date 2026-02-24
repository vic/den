---
title: Templates Overview
description: All available Den templates and when to use each one.
---

Den ships six templates that cover progressively complex setups. Use `nix flake init` to scaffold a new project:

```console
nix flake init -t github:vic/den#<template>
```

## Choosing a Template

| Template | Use case | Flakes | flake-parts | Home-Manager |
|----------|----------|:------:|:-----------:|:------------:|
| [**minimal**](/tutorials/minimal/) | Smallest possible Den setup | ✓ | ✗ | ✗ |
| [**default**](/tutorials/default/) | Recommended starting point | ✓ | ✓ | ✓ |
| [**example**](/tutorials/example/) | Feature showcase with namespaces | ✓ | ✓ | ✓ |
| [**noflake**](/tutorials/noflake/) | Stable Nix, no flakes | ✗ | ✗ | ✗ |
| [**bogus**](/tutorials/bogus/) | Bug reproduction | ✓ | ✓ | ✓ |
| [**ci**](/tutorials/ci/) | Den's own test suite | ✓ | ✓ | ✓ |

## Quick Start

```console
mkdir my-nix && cd my-nix
nix flake init -t github:vic/den
nix flake update den
```

This clones the **default** template. Edit `modules/hosts.nix` to declare your machines, then:

```console
nix run .#vm
```

## Project Structure

Every template follows the same pattern:

```
flake.nix          # or default.nix for noflake
modules/
  den.nix          # host/user declarations + den.flakeModule import
  *.nix            # aspect definitions, one concern per file
```

Den uses [import-tree](https://github.com/vic/import-tree) to recursively load all `.nix` files under `modules/`. You never need to manually list imports — just create files.

## What Each Template Demonstrates

- **minimal** — The absolute minimum: one host, one user, no extra dependencies
- **default** — Production-ready structure with Home-Manager, VM testing, dendritic flake-file
- **example** — Namespaces, angle brackets, cross-platform (NixOS + Darwin), providers
- **noflake** — Using Den with npins instead of flakes
- **bogus** — Creating minimal reproductions for bug reports with nix-unit
- **ci** — Comprehensive tests covering every Den feature (your best learning resource)

## Next Steps

Start with the [Minimal template](/tutorials/minimal/) to understand Den's core, then graduate to [Default](/tutorials/default/) for a real setup.
