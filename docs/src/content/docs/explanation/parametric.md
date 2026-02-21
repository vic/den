---
title: Parametric Aspects
description: How parametric functors enable context forwarding and adaptation.
---

> Use the source, Luke: [`nix/lib.nix`](https://github.com/vic/den/blob/main/nix/lib.nix) · [`nix/fn-can-take.nix`](https://github.com/vic/den/blob/main/nix/fn-can-take.nix)

## What Is a Parametric Aspect?

A **parametric** aspect delegates its [implicit arguments](https://sngeth.com/functional%20programming/2024/09/25/point-free-style/) to functions defined in its `.includes`.


The result of a `parametric` functions 
is an aspect that looks like this:

```nix
foo = {
  # context propagation into includes
  __functor = self: ctx: 
    map (f: f ctx) self.includes;

  # owned configs
  nixos.foo = 1;

  includes = [
    # functions receiving context
    (ctx: { nixos.bar = 2; })
  ];
}
```

When applied `foo { x = 1; }` the context
is propagated to the aspect includes.

Den provides several parametric functors in
`den.lib.parametric`. Each of them provides a
different `__functor` beaviour.

## den.lib.parametric

The most common functor. When applied it
includes the aspect owned config as well as
the result of applying the context to 
included functions that support `atLeast` the
same context.


```nix
# NOTE: context is known until application
foo = den.lib.parametric {
  # always included
  nixos.networking.hostName = "owned";

  includes = [
    # context received here
    ({ host, ... }: { nixos.time.timeZone = "UTC"; })
  ];
};
```

When applied with `foo { host = ...; user = ...; }`:

1. **Owned** configs (`nixos.networking.hostName`) are included
2. **Static** includes are included
3. **Functions** matching `atLeast` the context args are called

## parametric.atLeast

Only dispatches to includes — does **not** contribute owned configs:

```nix
foo = parametric.atLeast { 
  nixos.ignored = 22;
  includes = [ 
    ({ x, ...}: { nixos.x = x; })
    ({ x, y }: { nixos.y = y; })
    ({ z }: { nixos.z = z; })
  ]; 
};
```

Applied with `foo { x = 1; y = 2; }`:
- `{ x, ... }` matches (context has at least x)
- `{ x, y }` matches (context has at least x y)
- `{ z }` skipped (context has no z)

## parametric.exactly

Only dispatches to includes — does **not** contribute owned configs:

only calls functions with **exactly** matching args:

```nix
foo = parametric.exactly { 
  nixos.ignored = 22;
  includes = [ 
    ({ x, ...}: { nixos.x = x; })
    ({ x, y }: { nixos.y = y; })
    ({ z }: { nixos.z = z; })
  ]; 
};
```

Applied with `{ x = 1; y = 2; }`:
- `{ x, ... }` → skipped context is larget
- `{ x, y }` → called (exact match)
- `{ z }` → skipped no match


## parametric.fixedTo

This is an `atLeast` functor that also
contributes its **owned** configs and
ignores the context it is called with,
replacing it with a fixed one.

```nix
foo = parametric.fixedTo { planet = "Earth"; } {
  nixos.foo = "contributed";
  # functions have atLeast semantics
  includes = [
    ({ planet, ... }: { nixos.setting = planet; })
  ];
};
```

No matter what context `foo` receives, its includes always get
`{ planet = "Earth"; }`.

## parametric.expands

Like `fixedTo` but
adds attributes to the received context:

```nix
foo = parametric.expands { planet = "Earth"; } {
  includes = [
    ({ host, planet, ... }: {
      nixos.setting = "${host.name}/${planet}";
    })
  ];
};
```

Applied with `{ host = ...; }`, the includes receive
`{ host = ...; planet = "Earth"; }`.

## parametric.withOwn

Combinator that adds owned config and static includes on top of any
dispatch functor:

```nix
parametric.withOwn parametric.atLeast {
  nixos.foo = "owned";       # included always
  includes = [
    { nixos.bar = "static"; }  # included always
    ({ host, ... }: { ... })   # dispatched via atLeast
  ];
}
```

The `parametric` function itself is an alias for `(parametric.withOwn parametric.atLeast)`.


## Matching Rules Summary

| Functor | Owned configs | Statics includes | Functions includes semantics |
|---------|:-----:|:-------:|:---------:|
| `parametric` | ✓ | ✓ | atLeast |
| `parametric.atLeast` | ✗ | ✗ | atLeast |
| `parametric.exactly` | ✗ | ✗ | exactly |
| `parametric.fixedTo ctx` | ✓ | ✓ | fixed ctx |
| `parametric.expands ctx` | ✓ | ✓ | ctx + received |
| `parametric.withOwn F` | ✓ | ✓ | uses F |

## take.exactly and take.atLeast

For individual functions (not whole aspects), use [`den.lib.take`](/reference/lib/#denlibatake):


```nix
foo = parametric.atLeast { 
  includes = [ 
    (take.exactly ({ x, y }: ... ));
    (take.atLeast ({ x, y }: ... ));
  ]; 
};
```

Applied with `foo { x = 1; y = 2; z = 3; }`:
- `exactly { x, y }` is skipped
- `atLeast { x, y }` matches

This mechanism prevents functions with
lax context from matching everything,
which would **produce duplicate config values**.
