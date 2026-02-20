---
title: den.lib Reference
description: Library functions for parametric dispatch and context handling.
---

import { Aside } from '@astrojs/starlight/components';

<Aside type="tip">Source: [`nix/lib.nix`](https://github.com/vic/den/blob/main/nix/lib.nix) · [`nix/fn-can-take.nix`](https://github.com/vic/den/blob/main/nix/fn-can-take.nix) · [`nix/den-brackets.nix`](https://github.com/vic/den/blob/main/nix/den-brackets.nix)</Aside>

## den.lib.parametric

Creates a parametric aspect. Alias for `parametric.withOwn parametric.atLeast`.

```nix
den.lib.parametric { nixos.x = 1; includes = [ f ]; }
```

Includes owned configs, statics, and dispatches to functions via `atLeast`.

### parametric.atLeast

Dispatches **only** to functions whose required args are a subset of context:

```nix
F = parametric.atLeast { includes = [ a b ]; };
```

### parametric.exactly

Dispatches **only** to functions whose args match context exactly:

```nix
F = parametric.exactly { includes = [ a b ]; };
```

### parametric.fixedTo

Replaces context with a fixed attribute set:

```nix
F = parametric.fixedTo { x = 1; } aspect;
```

### parametric.expands

Merges extra attributes into received context:

```nix
F = parametric.expands { extra = 1; } aspect;
```

### parametric.withOwn

Combinator: adds owned + statics on top of a dispatch functor:

```nix
F = parametric.withOwn parametric.exactly aspect;
```

## den.lib.take

Individual function matching:

### take.atLeast

```nix
den.lib.take.atLeast ({ host, ... }: { nixos.x = 1; })
```

Wraps function to only be called when context has at least the required args.

### take.exactly

```nix
den.lib.take.exactly ({ host }: { nixos.x = 1; })
```

Only called when context has exactly these args, no more.

### take.unused

```nix
den.lib.take.unused ignored_value result
```

Returns `result`, ignoring the first argument. Used internally.

## den.lib.canTake

Function signature introspection:

```nix
den.lib.canTake { x = 1; } someFunction
# => true if someFunction can take at least { x }

den.lib.canTake.atLeast { x = 1; } someFunction
den.lib.canTake.exactly { x = 1; y = 2; } someFunction
```

## den.lib.aspects

Re-export of `flake-aspects` library. Provides:
- `aspects.types.aspectsType` — module type for aspect trees
- `aspects.types.providerType` — type for aspect providers
- `aspects.forward` — class forwarding implementation

## den.lib.isFn

Checks if a value is callable (function or attrset with `__functor`):

```nix
den.lib.isFn someValue  # => bool
```

## den.lib.owned

Extracts only owned configs from an aspect (removes `includes`, `__functor`):

```nix
den.lib.owned someAspect  # => { nixos = ...; darwin = ...; }
```

## den.lib.statics

Creates a functor that only resolves static includes from an aspect:

```nix
den.lib.statics someAspect { class = "nixos"; aspect-chain = []; }
```

## den.lib.isStatic

Checks if a function requires only `{ class, aspect-chain }`:

```nix
den.lib.isStatic someFunction  # => bool
```

## den.lib.__findFile

Angle-bracket resolver. Translates `<path>` expressions to aspect lookups:

```nix
_module.args.__findFile = den.lib.__findFile;
# then: <foo/bar> => den.aspects.foo.provides.bar
```
