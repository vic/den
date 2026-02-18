---
title: Entity Schema Reference
description: Host, user, and home configuration options.
---

import { Aside } from '@astrojs/starlight/components';

<Aside type="tip">Source: [`modules/_types.nix`](https://github.com/vic/den/blob/main/modules/_types.nix) · [`modules/options.nix`](https://github.com/vic/den/blob/main/modules/options.nix)</Aside>

## den.hosts

```nix
den.hosts.<system>.<name> = { ... };
```

### Host Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | str | attr name | Host configuration name |
| `hostName` | str | `name` | Network hostname |
| `system` | str | parent key | Platform (e.g., `x86_64-linux`) |
| `class` | str | guessed | `nixos`, `darwin`, or `systemManager` |
| `aspect` | str | `name` | Main aspect name |
| `description` | str | auto | Human-readable description |
| `users` | attrset | `{}` | User definitions |
| `instantiate` | function | auto | Builder function |
| `intoAttr` | str | auto | Flake output attribute |
| `mainModule` | module | auto | Resolved NixOS/Darwin module |
| *freeform* | anything | — | Custom attributes |

### Class Detection

| System suffix | Default class | Default intoAttr |
|--------------|---------------|------------------|
| `*-linux` | `nixos` | `nixosConfigurations` |
| `*-darwin` | `darwin` | `darwinConfigurations` |

### Instantiation

| Class | Default function |
|-------|-----------------|
| `nixos` | `inputs.nixpkgs.lib.nixosSystem` |
| `darwin` | `inputs.darwin.lib.darwinSystem` |
| `systemManager` | `inputs.system-manager.lib.makeSystemConfig` |

## User Options

```nix
den.hosts.<system>.<host>.users.<name> = { ... };
```

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | str | attr name | User configuration name |
| `userName` | str | `name` | OS account name |
| `class` | str | `homeManager` | Home management class |
| `aspect` | str | `name` | Main aspect name |
| *freeform* | anything | — | Custom attributes |

## den.homes

```nix
den.homes.<system>.<name> = { ... };
```

### Home Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `name` | str | attr name | Home configuration name |
| `userName` | str | `name` | User account name |
| `system` | str | parent key | Platform system |
| `class` | str | `homeManager` | Home management class |
| `aspect` | str | `name` | Main aspect name |
| `description` | str | auto | Human-readable description |
| `pkgs` | attrset | auto | Nixpkgs instance |
| `instantiate` | function | auto | Builder function |
| `intoAttr` | str | `homeConfigurations` | Flake output attribute |
| `mainModule` | module | auto | Resolved HM module |
| *freeform* | anything | — | Custom attributes |

## den.base

Base modules applied to all entities of a type:

```nix
den.base.conf = { ... }: { };  # hosts + users + homes
den.base.host = { host, ... }: { };
den.base.user = { user, ... }: { };
den.base.home = { home, ... }: { };
```

`den.base.conf` is automatically imported by host, user, and home.

## den.ful

Namespace storage for aspect libraries:

```nix
den.ful.<namespace>.<name> = aspect;
```

Populated via [`inputs.den.namespace`](/guides/namespaces/).

## flake.denful

Flake output for sharing namespaces:

```nix
flake.denful.<namespace> = den.ful.<namespace>;
```
