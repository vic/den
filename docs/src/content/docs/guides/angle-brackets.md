---
title: Angle Brackets Syntax
description: Opt-in shorthand for resolving deep aspect paths.
---

import { Aside } from '@astrojs/starlight/components';

<Aside type="tip">Source: [`nix/den-brackets.nix`](https://github.com/vic/den/blob/main/nix/den-brackets.nix)</Aside>

<Aside type="caution">Angle brackets is an experimental, opt-in feature.</Aside>

## What It Does

Den's `__findFile` resolves angle-bracket expressions to aspect paths:

| Expression | Resolves to |
|------------|-------------|
| `<den.lib>` | `den.lib` |
| `<den.default>` | `den.default` |
| `<igloo>` | `den.aspects.igloo` |
| `<foo/bar>` | `den.aspects.foo.provides.bar` |
| `<foo/bar/baz>` | `den.aspects.foo.provides.bar.provides.baz` |
| `<ns/tools>` | `den.ful.ns.tools` |

## Enable Per-Module

Bring `__findFile` into scope from module arguments:

```nix
{ den, __findFile, ... }: {
  _module.args.__findFile = den.lib.__findFile;
  den.aspects.igloo.includes = [ <den/define-user> ];
}
```

## Enable Globally

Create a module that sets it for all modules:

```nix
{ den, ... }: {
  _module.args.__findFile = den.lib.__findFile;
}
```

Then use it anywhere:

```nix
{ __findFile, ... }: {
  den.default.includes = [ <den/define-user> ];
  den.aspects.igloo.includes = [ <foo/bar/baz> ];
}
```

## Enable via Let-Binding

For a single lexical scope:

```nix
{ den, ... }:
let
  inherit (den.lib) __findFile;
in {
  den.aspects.igloo.includes = [ <den/define-user> ];
}
```

## Namespace Access

With a namespace `ns` enabled:

```nix
{ __findFile, ns, ... }: {
  ns.moo.silly = true;
  # access:
  expr = <ns/moo>;  # resolves to den.ful.ns.moo
}
```

## Deep Nested Provides

Slashes translate to `.provides.` in the aspect tree:

```nix
den.aspects.foo.provides.bar.provides.baz.nixos.programs.fish.enable = true;
den.aspects.igloo.includes = [ <foo/bar/baz> ];
# igloo gets fish enabled
```
