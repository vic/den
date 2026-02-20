---
title: Parametric Aspects
description: How parametric functors enable context forwarding and adaptation.
---

> Use the source, Luke: [`nix/lib.nix`](https://github.com/vic/den/blob/main/nix/lib.nix) · [`nix/fn-can-take.nix`](https://github.com/vic/den/blob/main/nix/fn-can-take.nix)

## What Is a Parametric Aspect?

A **parametric** aspect delegates its [implicit arguments](https://sngeth.com/functional%20programming/2024/09/25/point-free-style/) to functions defined in its `.includes`.

Den provides several parametric functors in
`den.lib.parametric`.

## den.lib.parametric

The most common functor.

Alias for `(parametric.withOwn parametric.atLeast)`:

```nix
# NOTE: context is implicit.
den.aspects.foo = den.lib.parametric {
  nixos.networking.hostName = "owned";  # always included
  includes = [
    ({ host, ... }: { nixos.time.timeZone = "UTC"; })
  ];
};
```

When applied with `{ host = ...; user = ...; }`:

1. **Owned** configs (`nixos.networking.hostName`) are included
2. **Static** includes are included
3. **Functions** matching `atLeast` the context args are called

## parametric.atLeast

Only dispatches to functions — does **not** include owned configs:

```nix
F = parametric.atLeast { includes = [ a b c ]; };
```

Applied with `{ x = 1; y = 2; }`:
- `{ x, ... }: ...` → called (has at least `x`)
- `{ x, y }: ...` → called (has exactly `x, y`)
- `{ z }: ...` → skipped (needs `z`)

## parametric.exactly

Like `atLeast`, but only calls functions with **exactly** matching args:

```nix
F = parametric.exactly { includes = [ a b c ]; };
```

Applied with `{ x = 1; y = 2; }`:
- `{ x, ... }: ...` → skipped (has `...`)
- `{ x, y }: ...` → called (exact match)
- `{ z }: ...` → skipped

Use `exactly` to prevent duplicate configs when the same function would
match multiple context stages.

## parametric.fixedTo

Replaces the context entirely:

```nix
foo = parametric.fixedTo { planet = "Earth"; } {
  includes = [
    ({ planet, ... }: { nixos.setting = planet; })
  ];
};
```

No matter what context `foo` receives, its includes always get
`{ planet = "Earth"; }`.

## parametric.expands

Adds attributes to the received context:

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

## Matching Rules Summary

| Functor | Owned | Statics | Functions |
|---------|:-----:|:-------:|:---------:|
| `parametric` (default) | ✓ | ✓ | atLeast |
| `parametric.atLeast` | ✗ | ✗ | atLeast |
| `parametric.exactly` | ✗ | ✗ | exactly |
| `parametric.withOwn F` | ✓ | ✓ | uses F |
| `parametric.fixedTo ctx` | ✓ | ✓ | fixed ctx |
| `parametric.expands ctx` | ✓ | ✓ | ctx + received |

## take.exactly and take.atLeast

For individual functions (not whole aspects), use [`den.lib.take`](/reference/lib/#denlibatake):

```nix
den.default.includes = [
  (den.lib.take.exactly ({ host }: { nixos.x = 1; }))
];
```

This prevents the function from matching `{ host, user }` contexts,
avoiding duplicate config values.
