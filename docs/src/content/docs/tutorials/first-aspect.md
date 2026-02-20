---
title: Your First Aspect
description: Create a cross-class, reusable Nix configuration aspect.
---

## What is an Aspect?

An aspect is a composable bundle of Nix configurations that can span multiple
classes (NixOS, Darwin, Home-Manager). Each host, user, and home you declare
automatically gets an aspect.

## Step 1: Declare Your Infrastructure

Start with a host and user:

```nix
# modules/hosts.nix
{
  den.hosts.x86_64-linux.igloo.users.tux = { };
}
```

Den creates `den.aspects.igloo` (host) and `den.aspects.tux` (user) automatically.

## Step 2: Configure the Host Aspect

Any module file can contribute to any aspect. Create a file for your host:

```nix
# modules/igloo.nix
{ den, ... }: {
  den.aspects.igloo = {
    nixos.networking.hostName = "igloo";
    nixos.time.timeZone = "UTC";
    homeManager.programs.direnv.enable = true;
  };
}
```

The `nixos` settings apply to NixOS. The `homeManager` settings apply
to **every user** on this host.

## Step 3: Configure the User Aspect

```nix
# modules/vic.nix
{ den, ... }: {
  den.aspects.tux = {
    homeManager.programs.fish.enable = true;
    nixos.users.users.tux.description = "Tux the Penguin";
  };
}
```

User aspects contribute to **every host** that has this user.
If `tux` exists on both `igloo` and another host, both get the fish config.

## Step 4: Use Includes for Composition

Aspects can include other aspects:

```nix
# modules/gaming.nix
{ den, ... }: {
  den.aspects.gaming = {
    nixos.programs.steam.enable = true;
    homeManager.programs.mangohud.enable = true;
  };

  den.aspects.igloo.includes = [ den.aspects.gaming ];
}
```

## Step 5: Use Provides for Nesting

Organize related aspects in a tree:

```nix
{ den, ... }: {
  den.aspects.tools.provides.editors = {
    homeManager.programs.vim.enable = true;
  };

  den.aspects.tux.includes = [ den.aspects.tools._.editors ];
}
```

The `._. ` syntax is shorthand for `.provides.`.

## Step 6: Set Global Defaults

Use `den.default` for settings shared across all hosts and users:

```nix
# modules/defaults.nix
{
  den.default.homeManager.home.stateVersion = "25.11";
  den.default.nixos.system.stateVersion = "25.11";
}
```

## What You've Learned

- [Aspects](/explanation/aspects/) bundle cross-class configs (nixos, darwin, homeManager)
- Host aspects apply to all users on that host
- User aspects apply to all hosts with that user
- `includes` compose aspects together
- `provides` creates nested aspect trees
- [`den.default`](/explanation/context-pipeline/#dendefault-is-an-alias) sets global shared values

## Next

[Context-Aware Configs](/tutorials/context-aware/) — make your aspects
respond dynamically to their host and user context.
