---
title: Context System
description: How den.ctx defines, transforms, and propagates context.
---


> Use the Source, Luke: [`modules/context/types.nix`](https://github.com/vic/den/blob/main/modules/context/types.nix) · [`modules/context/os.nix`](https://github.com/vic/den/blob/main/modules/context/os.nix)

## What Is a Context?

In Den, a **context** is an attribute set whose **names** (not values) determine
which functions get called. When Den applies a context `{ host, user }` to a
function `{ host, ... }: ...`, the function matches. A function `{ never }: ...`
does not match and is ignored.

## Why Named Contexts?

Named contexts `ctx.host { host }` and `ctx.hm-host { host }`
hold the same data, but `hm-host` **guarantees** that home-manager support was
validated. This follows the [**parse-don't-validate**](https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/) principle: you cannot
obtain an `hm-host` context unless all detection criteria passed.

```mermaid
graph LR
  H["den.ctx.host {host}"] -->|"hm-detect"| Check{"host OS supported by HM?<br/>host has HM users?<br/>inputs.home-manager exists?"}
  Check -->|"all true"| HMH["same data {host}<br/>as den.ctx.hm-host"]
  Check -->|"any false"| Skip["∅ skipped"]
  HMH -->|"guaranteed"| Use["HM pipeline<br/>proceeds safely"]
```

## Context Types: den.ctx

Each context type is defined in `den.ctx` with four components:

```nix
den.ctx.foobar = {
  desc = "The {foo, bar} context";
  conf = { foo, bar }: den.aspects.${foo}._.${bar};
  includes = [ /* parametric aspects */ ];
  into = {
    baz = { foo, bar }: [{ baz = computeBaz foo bar; }];
  };
};
```

| Component | Purpose |
|-----------|---------|
| `desc` | Human-readable description |
| `conf` | Given a context, find aspect responsible for configuration |
| `includes` | Parametric aspects activated for this context (aspect cutting-point) |
| `into` | Transformations fan-out into other context types |

## Context Application

A context type is callable — it's a functor:

```nix
aspect = den.ctx.foobar { foo = "hello"; bar = "world"; };
```

When applied, Den creates a new aspect that includes the following:

1. **owned configs** from the context itself
2. **main aspect config** via `conf` (e.g., `den.aspects.hello._.world`)
3. **included configs** — parametric aspects matching this context
4. **transforms** — calls each `into` function, producing new contexts
5. **recurses** — applies each produced context through its own pipeline

```mermaid
graph TD
  Apply["ctx.foobar { foo, bar }"]
  Apply --> Own["Owned configs"]
  Apply --> Conf["ctx → find aspect"]
  Apply --> Inc["includes → parametric aspects"]
  Apply --> Into["into.baz → new baz contexts"]
  Into --> Next["ctx.baz { baz }"]
  Next --> Own2["...recurse"]
```

## Transformation Types

Transformations have the type `source → [ target ]` — they return a **list**.
This enables two patterns:

```mermaid
graph TD
  subgraph "Fan-out (one → many)"
    Host1["{host}"] -->|"into.user"| U1["{host, user₁}"]
    Host1 -->|"into.user"| U2["{host, user₂}"]
    Host1 -->|"into.user"| U3["{host, user₃}"]
  end
  subgraph "Conditional (one → zero or one)"
    Host2["{host}"] -->|"into.hm-host"| Gate{"detection<br/>gate"}
    Gate -->|"passes"| HM["{host} as hm-host"]
    Gate -->|"fails"| Empty["∅ empty list"]
  end
```

**Fan-out** — one context producing many:

```nix
den.ctx.host.into.user = { host }:
  map (user: { inherit host user; }) (attrValues host.users);
```

One host fans out to N user contexts.

**Conditional propagation** — zero or one:

```nix
den.ctx.host.into.hm-host = { host }:
  lib.optional (isHmSupported host) { inherit host; };
```

If the condition fails, the list is empty and no `hm-host` context is created.
The data is the same `{ host }`, but the named context guarantees the validation
passed.

## Contexts as Aspect Cutting-Points

Contexts are aspect-like themselves. They have owned configs and `.includes`:

```nix
den.ctx.hm-host.nixos.home-manager.useGlobalPkgs = true;

den.ctx.hm-host.includes = [
  ({ host, ... }: { nixos.home-manager.backupFileExtension = "bak"; })
];
```

This is like `den.default.includes` **but scoped** — it only activates for
hosts with validated home-manager support. Use context includes to attach
aspects to specific pipeline stages instead of the catch-all `den.default`.

## Extending Context Flow

You can define new context types or new transformations into existing contexts from any module:

```nix
den.ctx.hm-host.into.foo = { host }: [ { foo = host.name; } ];
den.ctx.foo.conf = { foo }: { funny.names = [ foo ]; };
```

The module system merges these definitions. You can extend the pipeline
without modifying any built-in file.

## Built-in Context Types

Den defines these context types for its NixOS/Darwin/HM framework:

### den.ctx.host — `{ host }`

This is how NixOS configurations get created:

```nix
# use den API to apply the context to data
aspect = den.ctx.host {
  # value is `den.hosts.<system>.<name>`.
  host = den.hosts.x86_64-linux.igloo;
};

# use flake-aspects API to resolve nixos module
nixosModule = aspect.resolve { class = "nixos"; };

# use NixOS API to build the system
nixosConfigurations.igloo = lib.nixosSystem {
  modules = [ nixosModule ];
};
```

### den.ctx.user — `{ host, user }`

A host fan-outs a new context for each user.

### den.ctx.default

Aliased as `den.default`, used to define static global settings for hosts, users and homes.

### den.ctx.hm-host — `{ host }` 

Home Manager enabled host.

A den.ctx.host gets transformed into den.ctx.hm-host only if the [host supports home-manager](/explanation/context-pipeline/).

When activated, it imports the HM module.

### den.ctx.hm-user — `{ host, user }`

For each user that has its class value set to homeManager.

When activated enables the `homeManager` user configuration class.

### den.ctx.home — `{ home }`

Entry point for standalone Home-Manager configurations.

## Custom Context Types

Create your own for domain-specific pipelines:

```nix
den.ctx.greeting.conf = { hello }:
  { funny.names = [ hello ]; };

den.ctx.greeting.into.shout = { hello }:
  [{ shout = lib.toUpper hello; }];

den.ctx.shout.conf = { shout }:
  { funny.names = [ shout ]; };
```

Applying `den.ctx.greeting { hello = "world"; }` produces both
`"world"` and `"WORLD"` through the transformation chain.

See the [Context Pipeline](/explanation/context-pipeline/) for the complete data flow.
See the [`den.ctx` Reference](/reference/ctx/) for all built-in types.
