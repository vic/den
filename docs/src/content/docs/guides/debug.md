---
title: Debug Configurations
description: Tools and techniques for debugging Den configurations.
---

## builtins.trace

Print values during evaluation:

```nix
den.aspects.foo = { user, ... }@context:
  (builtins.trace context {
    nixos = { };
  });
```

## builtins.break

Drop into a REPL at any evaluation point:

```nix
den.aspects.foo = { user, ... }@context:
  (builtins.break context {
    nixos = { };
  });
```

## Trace Context Keys

See which contexts are being applied:

```nix
den.default.includes = [
  (context: builtins.trace (builtins.attrNames context) { })
];
```

## REPL Inspection

Load your flake and explore interactively:

```console
$ nix repl
nix-repl> :lf .
nix-repl> nixosConfigurations.igloo.config.networking.hostName
"igloo"
```

## Expose den for Inspection

Temporarily expose the `den` attrset as a flake output:

```nix
{ den, ... }: {
  flake.den = den;  # remove when done
}
```

Then in REPL:

```console
nix-repl> :lf .
nix-repl> den.aspects.igloo
nix-repl> den.hosts.x86_64-linux.igloo
```

## Manually Resolve an Aspect

Test how an aspect resolves for a specific class:

```console
nix-repl> module = den.aspects.foo.resolve { class = "nixos"; aspect-chain = []; }
nix-repl> config = (lib.evalModules { modules = [ module ]; }).config
```

For parametric aspects, apply context first:

```console
nix-repl> aspect = den.aspects.foo { host = den.hosts.x86_64-linux.igloo; }
nix-repl> module = aspect.resolve { class = "nixos"; aspect-chain = []; }
```

## Inspect a Host's Main Module

```console
nix-repl> module = den.hosts.x86_64-linux.igloo.mainModule
nix-repl> config = (lib.nixosSystem { modules = [ module ]; }).config
```

## Common Issues

**Duplicate values in lists**: Your function matches too many contexts.
Use `den.lib.take.exactly` to restrict matching:

```nix
den.lib.take.exactly ({ host }: { nixos.x = 1; })
```

**Missing attribute**: The context doesn't have the expected parameter.
Trace context keys to see what's available.

**Infinite recursion**: Aspects including each other in a cycle.
Check your `includes` chains for circular dependencies.
