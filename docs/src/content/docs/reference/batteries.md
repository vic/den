---
title: Batteries Reference
description: All built-in opt-in aspects shipped with Den.
---

import { Aside } from '@astrojs/starlight/components';

<Aside type="tip">Source: [`modules/aspects/provides/`](https://github.com/vic/den/tree/main/modules/aspects/provides)</Aside>

## Overview

Batteries are pre-built aspects at `den.provides` (accessed via `den._.<name>`).
All are opt-in — include them explicitly where needed.

## define-user

Defines a user at OS and Home-Manager levels.
([source](https://github.com/vic/den/blob/main/modules/aspects/provides/define-user.nix))

```nix
den.default.includes = [ den._.define-user ];
```

**Sets:**
- `users.users.<name>.{name, home, isNormalUser}` (NixOS)
- `users.users.<name>.{name, home}` (Darwin)
- `home.{username, homeDirectory}` (Home-Manager)

**Contexts:** `{ host, user }`, `{ home }`

## primary-user

Makes a user an administrator.
([source](https://github.com/vic/den/blob/main/modules/aspects/provides/primary-user.nix))

```nix
den.aspects.vic.includes = [ den._.primary-user ];
```

**Sets:**
- NixOS: `users.users.<name>.extraGroups = [ "wheel" "networkmanager" ]`
- Darwin: `system.primaryUser = <name>`
- WSL: `wsl.defaultUser = <name>` (if host has `wsl` attribute)

**Context:** `{ host, user }`

## user-shell

Sets default shell at OS and HM levels.
([source](https://github.com/vic/den/blob/main/modules/aspects/provides/user-shell.nix))

```nix
den.aspects.vic.includes = [ (den._.user-shell "fish") ];
```

**Sets:**
- `programs.<shell>.enable = true` (NixOS/Darwin)
- `users.users.<name>.shell = pkgs.<shell>` (NixOS/Darwin)
- `programs.<shell>.enable = true` (Home-Manager)

**Contexts:** `{ host, user }`, `{ home }`

## unfree

Enables unfree packages by name.
([source](https://github.com/vic/den/blob/main/modules/aspects/provides/unfree/unfree-predicate-builder.nix) · [predicate](https://github.com/vic/den/blob/main/modules/aspects/provides/unfree/unfree.nix))

```nix
den.aspects.laptop.includes = [ (den._.unfree [ "discord" ]) ];
```

**Sets:** `unfree.packages` option + `nixpkgs.config.allowUnfreePredicate`

**Contexts:** All (host, user, home) — works for any class.

:::note[useGlobalPkgs interaction]
When Home-Manager's `useGlobalPkgs` is `true`, the unfree module
skips setting `nixpkgs.config` on the HM class to avoid conflicts.
Set unfree packages on the **host** aspect instead.
:::

## tty-autologin

Automatic tty login.

```nix
den.aspects.laptop.includes = [ (den._.tty-autologin "root") ];
```

**Sets:** `systemd.services."getty@tty1"` with autologin.

**Class:** NixOS only.

## import-tree

Auto-imports non-dendritic Nix files by class directory.
([source](https://github.com/vic/den/blob/main/modules/aspects/provides/import-tree.nix))

```nix
den.aspects.laptop.includes = [ (den._.import-tree ./path) ];
```

Looks for `./path/_nixos/`, `./path/_darwin/`, `./path/_homeManager/`.

**Helpers:**

```nix
den._.import-tree._.host ./hosts   # per host: ./hosts/<name>/_<class>
den._.import-tree._.user ./users   # per user: ./users/<name>/_<class>
den._.import-tree._.home ./homes   # per home: ./homes/<name>/_<class>
```

**Requires:** `inputs.import-tree`

## inputs' (flake-parts)

Provides per-system `inputs'` as a module argument.

```nix
den.default.includes = [ den._.inputs' ];
```

**Requires:** flake-parts with `withSystem`.

## self' (flake-parts)

Provides per-system `self'` as a module argument.

```nix
den.default.includes = [ den._.self' ];
```

**Requires:** flake-parts with `withSystem`.

## forward

Creates custom Nix classes by forwarding configs between classes.
([source](https://github.com/vic/den/blob/main/modules/aspects/provides/forward.nix) · [usage guide](/guides/custom-classes/))

```nix
den._.forward {
  each = lib.singleton class;
  fromClass = _: "source";
  intoClass = _: "nixos";
  intoPath = _: [ "target" "path" ];
  fromAspect = _: sourceAspect;
}
```

Returns an aspect. Used internally for Home-Manager integration.

## home-manager

Empty marker aspect. The actual HM integration is handled by
`den.ctx.hm-host` and `den.ctx.hm-user` context types, which are
activated automatically when hosts have HM users.
