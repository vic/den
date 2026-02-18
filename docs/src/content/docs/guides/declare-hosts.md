---
title: Declare Hosts & Users
description: Define your infrastructure entities with Den's freeform schema.
---

import { Aside } from '@astrojs/starlight/components';

<Aside type="tip">Source: [`modules/_types.nix`](https://github.com/vic/den/blob/main/modules/_types.nix) · Reference: [Entity Schema](/reference/schema/)</Aside>

## Hosts and Users

Declare hosts with a single line per machine:

```nix
den.hosts.x86_64-linux.my-laptop.users.vic = { };
den.hosts.aarch64-darwin.macbook.users.vic = { };
```

This creates NixOS/Darwin configurations with users, ready for:

```console
nixos-rebuild switch --flake .#my-laptop
darwin-rebuild switch --flake .#macbook
```

## Customize Host Attributes

Expand the attribute set for full control:

```nix
den.hosts.x86_64-linux.my-laptop = {
  hostName = "yavanna";        # default: my-laptop
  class = "nixos";             # default: guessed from platform
  aspect = "workstation";      # default: my-laptop
  users.vic = {
    userName = "vborja";       # default: vic
    aspect = "oeiuwq";         # default: vic
    class = "homeManager";     # default: homeManager
  };
};
```

## Standalone Home-Manager

For Home-Manager without a host OS:

```nix
den.homes.aarch64-darwin.vic = { };
```

Build with:

```console
home-manager switch --flake .#vic
```

## Multiple Hosts, Shared Users

The same user aspect applies to every host it appears on:

```nix
den.hosts.x86_64-linux.desktop.users.vic = { };
den.hosts.x86_64-linux.server.users.vic = { };
den.hosts.aarch64-darwin.mac.users.vic = { };
```

All three machines share `den.aspects.vic` configurations.

## Freeform Attributes

Hosts and users accept arbitrary attributes. Use them for metadata
that aspects can inspect:

```nix
den.hosts.x86_64-linux.my-laptop = {
  isWarm = true;          # custom attribute
  location = "home";      # custom attribute
  users.vic = { };
};
```

Then in an aspect: `{ host, ... }: if host.isWarm then ...`

## Base Modules

Add type-checked options to all hosts, users, or homes:

```nix
den.base.host = { host, lib, ... }: {
  options.vpn-alias = lib.mkOption { default = host.name; };
};

den.base.user = { user, lib, ... }: {
  options.main-group = lib.mkOption { default = user.name; };
};

den.base.conf = { lib, ... }: {
  options.org = lib.mkOption { default = "acme"; };
};
```

`den.base.conf` applies to hosts, users, **and** homes.

## Custom Instantiation

Override how configurations are built:

```nix
den.hosts.x86_64-linux.wsl-box = {
  class = "nixos";
  instantiate = inputs.nixos-wsl.lib.nixosSystem;
  intoAttr = "wslConfigurations";
  users.vic = { };
};
```

Different `nixpkgs` channels per host:

```nix
den.hosts.x86_64-linux.stable-server = {
  instantiate = inputs.nixpkgs-stable.lib.nixosSystem;
  users.admin = { };
};
```
