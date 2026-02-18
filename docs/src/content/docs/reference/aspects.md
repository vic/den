---
title: den.aspects Reference
description: Aspect structure, resolution, and configuration.
---

import { Aside } from '@astrojs/starlight/components';

<Aside type="tip">Source: [`modules/aspects.nix`](https://github.com/vic/den/blob/main/modules/aspects.nix) · [`modules/aspects/definition.nix`](https://github.com/vic/den/blob/main/modules/aspects/definition.nix) · [`modules/aspects/provides.nix`](https://github.com/vic/den/blob/main/modules/aspects/provides.nix)</Aside>

## Aspect Attributes

Every aspect is an attribute set with these recognized keys:

| Attribute | Type | Description |
|-----------|------|-------------|
| `nixos` | module | NixOS configuration module |
| `darwin` | module | nix-darwin configuration module |
| `homeManager` | module | Home-Manager configuration module |
| `<class>` | module | Any custom Nix class |
| `includes` | list | Dependencies on other aspects or functions |
| `provides` | attrset | Nested sub-aspects |
| `_` | alias | Shorthand for `provides` |
| `description` | str | Human-readable description |
| `__functor` | function | Context-aware behavior |

## Automatic Aspect Creation

Den creates an aspect for each host, user, and home you declare:

```nix
den.hosts.x86_64-linux.igloo.users.tux = { };
# Creates: den.aspects.igloo and den.aspects.tux
```

Aspects are created with `parametric { <class> = {}; }` functor
matching the entity's class.

## Aspect Resolution

To extract a class module from an aspect:

```nix
module = aspect.resolve { class = "nixos"; aspect-chain = []; };
```

Resolution collects the specified class from the aspect and all
transitive includes into a single merged Nix module.

## den.aspects (option)

```nix
options.den.aspects = lib.mkOption {
  type = aspectsType;
  default = { };
};
```

Contributions from any module are merged:

```nix
# file1.nix
den.aspects.igloo.nixos.networking.hostName = "igloo";

# file2.nix
den.aspects.igloo.homeManager.programs.vim.enable = true;
```

## den.provides (batteries)

```nix
options.den.provides = lib.mkOption {
  type = lib.types.submodule {
    freeformType = lib.types.attrsOf providerType;
  };
};
```

Access via `den._.name` or `den.provides.name`.
See [Batteries Reference](/reference/batteries/) for all built-in aspects.

## den.default

The global dispatcher aspect:

```nix
den.default = den.lib.parametric.atLeast { };
```

All hosts, users, and homes include `den.default`. Set global
configs and shared [parametric](/explanation/parametric/) includes here.

Aliased from `den.ctx.default`.

## Including Aspects

```nix
den.aspects.igloo.includes = [
  # another aspect
  den.aspects.gaming

  # nested provides
  den.aspects.tools._.editors

  # static config
  { homeManager.programs.direnv.enable = true; }

  # context function
  ({ host, ... }: { nixos.time.timeZone = "UTC"; })

  # battery
  den._.define-user

  # battery with args
  (den._.user-shell "fish")
  (den._.unfree [ "discord" ])
];
```

## Aspect as Module Argument

`den` is available as a module argument in all Den modules:

```nix
{ den, ... }: {
  den.aspects.foo = den.lib.parametric { ... };
}
```
