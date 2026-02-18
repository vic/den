---
title: Context-Aware Configurations
description: Make aspects produce conditional config based on host and user context.
---

## From Static to Dynamic

So far, aspects have been static attribute sets. But Den's power comes from
making them **functions of context**. When an aspect is a function, Den
passes it the current context — host, user, platform — and the function
decides what to produce.

## Step 1: A Simple Context Function

Instead of a static aspect, write a function:

```nix
{ den, ... }: {
  den.aspects.igloo.includes = [
    ({ host, ... }: {
      nixos.networking.hostName = host.name;
    })
  ];
}
```

Den calls this function with `{ host }` containing the host's attributes.
The result sets the hostname dynamically from the host's name.

## Step 2: React to User Context

Functions receiving `{ host, user, ... }` run once per user on each host:

```nix
{ den, ... }: {
  den.default.includes = [
    ({ host, user, ... }: {
      ${host.class}.users.users.${user.userName}.description =
        "${user.userName} on ${host.name}";
    })
  ];
}
```

Notice `${host.class}` — this dynamically targets `nixos` or `darwin`
depending on the host's platform. The same function works on both.

## Step 3: Conditional Configuration

Use standard Nix conditionals inside context functions:

```nix
{ den, lib, ... }:
let
  git-for-linux = { user, host, ... }:
    if !lib.hasSuffix "darwin" host.system
    then { homeManager.programs.git.enable = true; }
    else { };
in {
  den.aspects.tux.includes = [ git-for-linux ];
}
```

Git is enabled only for users on Linux hosts. On Darwin, the function
returns an empty set — no effect.

## Step 4: Use den.lib.parametric

For aspects that need to forward context to their own includes,
wrap them with `den.lib.parametric`:

```nix
{ den, ... }:
let
  workspace = den.lib.parametric {
    nixos.networking.hostName = "from-parametric";
    includes = [
      ({ host, ... }: { nixos.time.timeZone = "UTC"; })
    ];
  };
in {
  den.aspects.igloo.includes = [ workspace ];
}
```

The `parametric` functor ensures that:
1. **Owned** config (`nixos.networking.hostName`) is always included
2. **Functions** in `includes` receive the forwarded context
3. Functions whose parameters don't match are **silently skipped**

## Step 5: Understand Matching

Den matches context by **argument names**, not values:

| Function signature | `{ host }` | `{ host, user }` |
|--------------------|:---:|:---:|
| `{ host, ... }: ...` | ✓ | ✓ |
| `{ host, user }: ...` | ✗ | ✓ |
| `{ never, ... }: ...` | ✗ | ✗ |

- `atLeast` — function is called if context has **at least** the required args
- `exactly` — function is called only if context has **exactly** those args

## What You've Learned

- Aspects can be functions that receive `{ host, user, home, ... }`
- Context functions produce conditional, platform-aware configurations
- [`den.lib.parametric`](/explanation/parametric/) forwards context to nested includes
- Unmatched functions are [silently skipped](/explanation/parametric/#matching-rules-summary) — no errors
- `${host.class}` makes configs target the right Nix class dynamically

## Next

- [Bidirectional Dependencies](/guides/bidirectional/) — hosts and users configure each other
- [Context System](/explanation/context-system/) — deep dive into `den.ctx`
