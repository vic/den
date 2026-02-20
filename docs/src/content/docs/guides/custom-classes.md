---
title: Custom Nix Classes
description: Create new Nix configuration classes with den._.forward.
---

import { Aside } from '@astrojs/starlight/components';

<Aside type="tip">Source: [`modules/aspects/provides/forward.nix`](https://github.com/vic/den/blob/main/modules/aspects/provides/forward.nix) · [CI tests](https://github.com/vic/den/blob/main/templates/ci/modules/forward.nix)</Aside>

## What Are Custom Classes?

Den natively supports `nixos`, `darwin`, and `homeManager` classes. But you
can create your own classes that forward their settings into any target
submodule. This is exactly how Home-Manager integration works internally.

## The forward Battery

`den._.forward` creates an aspect that takes configs from a source class
and inserts them into a target class at a specified path.

## Example: Custom Class to NixOS

Forward a `custom` class into NixOS top-level:

```nix
{ den, lib, ... }:
let
  forwarded = { class, aspect-chain }:
    den._.forward {
      each = lib.singleton class;
      fromClass = _: "custom";
      intoClass = _: "nixos";
      intoPath = _: [ ];
      fromAspect = _: lib.head aspect-chain;
    };
in {
  den.aspects.igloo = {
    includes = [ forwarded ];
    custom.networking.hostName = "from-custom-class";
  };
}
```

## Example: Forward into a Subpath

Insert configs into a nested submodule:

```nix
den.aspects.igloo = {
  includes = [ forwarded ];
  nixos.imports = [
    { options.fwd-box = lib.mkOption {
        type = lib.types.submoduleWith { modules = [ myModule ]; };
    }; }
  ];
  src.items = [ "from-src-class" ];
};
```

With `intoPath = _: [ "fwd-box" ]`, the `src` class configs merge into
`nixos.fwd-box`.

## How Home-Manager Uses Forward

Den's Home-Manager integration is built on `forward`:

```nix
den._.forward {
  each = lib.singleton true;
  fromClass = _: "homeManager";
  intoClass = _: host.class;
  intoPath = _: [ "home-manager" "users" user.userName ];
  fromAspect = _: userAspect;
}
```

This takes all `homeManager` class configs from user aspects and inserts them
into `home-manager.users.<name>` on the host's OS configuration.

## Use Cases

- **User environments**: Forward a `user` class into `users.users.<name>`
- **Containerization**: Forward a `container` class into systemd-nspawn configs
- **VM configs**: Forward a `vm` class into microvm or QEMU settings
- **Custom tools**: Forward into any Nix-configurable system (NixVim, etc.)

## Creating Your Own

The `forward` function parameters:

| Parameter | Description |
|-----------|-------------|
| `each` | List of items to iterate over |
| `fromClass` | Source class name (string) |
| `intoClass` | Target class name (string) |
| `intoPath` | Attribute path in target (list of strings) |
| `fromAspect` | Source aspect to read from |
