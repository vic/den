---
title: Share with Namespaces
description: Share and consume aspect libraries across repositories.
---

import { Aside } from '@astrojs/starlight/components';

<Aside type="tip">Source: [`nix/namespace.nix`](https://github.com/vic/den/blob/main/nix/namespace.nix)</Aside>

## What Are Namespaces?

Namespaces let you organize aspects into named collections that can be
shared across flakes and consumed by others.

## Define a Local Namespace

```nix
{ inputs, ... }: {
  imports = [ (inputs.den.namespace "ns" false) ];
  ns.tools.nixos.programs.vim.enable = true;
}
```

The second argument controls output:
- `false` — local only, not exposed as flake output
- `true` — exposed at `flake.denful.ns`
- A list of sources — merge from external inputs

## Consume Remote Namespaces

Import aspects from another flake's `denful` output:

```nix
{ inputs, ... }: {
  imports = [
    (inputs.den.namespace "provider" [ true inputs.other-flake ])
  ];

  den.aspects.igloo.includes = [ provider.tools._.editors ];
}
```

Multiple sources are merged. Local definitions override remote ones.

## Nested Provides in Namespaces

Namespaces support the full aspect tree with `provides`:

```nix
ns.root.provides.branch.provides.leaf.nixos.truth = true;
# access via:
ns.root._.branch._.leaf
```

## Expose as Flake Output

When the second argument is `true` (or a list containing `true`),
the namespace appears at `config.flake.denful.<name>`:

```nix
imports = [ (inputs.den.namespace "ns" true) ];
ns.foo.nixos.truth = true;
# available at config.flake.denful.ns
```

Other flakes can then consume it:

```nix
inputs.your-flake.denful.ns
```

## Merge Multiple Sources

Combine local, remote, and output in one namespace:

```nix
imports = [
  (inputs.den.namespace "ns" [
    inputs.sourceA
    inputs.sourceB
    true  # also expose as output
  ])
];

ns.gear.nixos.data = [ "local" ];
# merges with sourceA and sourceB's denful.ns.gear
```

## Use with Angle Brackets

When `__findFile` is in scope, namespace aspects are accessible via
angle brackets:

```nix
{ __findFile, ns, ... }: {
  _module.args.__findFile = den.lib.__findFile;
  den.aspects.igloo.includes = [ <ns/tools> ];
}
```

## Real-World: denful

[denful](https://github.com/vic/denful) is a community aspect distribution
built on Den namespaces — a lazyvim-like approach to Nix configurations.
