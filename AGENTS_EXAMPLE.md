# AGENTS.md — Den AI Coding Agent Guide

> **Den** is an Aspect-oriented, Context-driven Dendritic Nix configuration library and framework.
> This file is your primary operating manual. Read it fully before writing any Den Nix code.

---

## Table of Contents

1. [What Den Is](#what-den-is)
2. [How to Use This Repository as Reference](#how-to-use-this-repository-as-reference)
3. [Repository Map — Read These Directories](#repository-map)
4. [Core Concepts](#core-concepts)
   - [Aspects](#aspects)
   - [Parametric Dispatch](#parametric-dispatch)
   - [Context System & Pipeline](#context-system--pipeline)
   - [Schema — Hosts, Users, Homes](#schema--hosts-users-homes)
   - [den.default — Global Policies](#dendefault--global-policies)
5. [Feature Reference](#feature-reference)
   - [Declaring Hosts & Users](#declaring-hosts--users)
   - [Declaring Standalone Homes](#declaring-standalone-homes)
   - [Configuring Aspects (Owned, Includes, Provides)](#configuring-aspects)
   - [Home Environments (homeManager, hjem, maid)](#home-environments)
   - [Batteries (den.provides.*)](#batteries)
   - [Mutual Providers (Host↔User)](#mutual-providers)
   - [Custom Nix Classes via den.provides.forward](#custom-nix-classes)
   - [Guarded Forwarding](#guarded-forwarding)
   - [Namespaces & Cross-Flake Sharing](#namespaces--cross-flake-sharing)
   - [Angle Brackets Syntax](#angle-brackets-syntax)
   - [Schema Base Modules](#schema-base-modules)
   - [Custom Context Types](#custom-context-types)
   - [den.lib — Core Library Functions](#denlib--core-library-functions)
   - [Den as a Pure Library (Domain-Agnostic)](#den-as-a-pure-library)
   - [Output Generation](#output-generation)
   - [WSL Support](#wsl-support)
   - [MicroVM & Advanced Extensibility](#microvm--advanced-extensibility)
   - [flake-parts Integration (inputs', self')](#flake-parts-integration)
6. [Templates — Starter Points](#templates)
7. [CI Tests as Authoritative Examples](#ci-tests-as-authoritative-examples)
8. [Debugging](#debugging)
9. [Anti-Patterns](#anti-patterns)
10. [Migration from Existing Setups](#migration)
11. [Activation Commands](#activation-commands)

---

## What Den Is

Den is built on top of [flake-aspects](https://github.com/vic/flake-aspects) and provides:

- **A library** (`den.lib`) — domain-agnostic parametric dispatch, argument introspection, and aspect manipulation. Works for any Nix module system.
- **A framework** (`modules/`) — NixOS/nix-Darwin/Home-Manager specific: host/user/home schema types, a context pipeline, batteries, and flake output generation.

Den embraces your Nix choices: it works with or without flakes, with or without flake-parts. All parts are optional and replaceable.

The fundamental philosophy: **features (aspects) are the primary organisational unit**, not hosts. An aspect consolidates all class-specific configuration for a single concern. Hosts and users simply select which aspects apply to them.

---

## How to Use This Repository as Reference

**Always read source code and documentation as needed. Do not guess.**

- **Documentation lives in `./docs/src/content/docs/`** — structured as `explanation/`, `guides/`, `reference/`, and `tutorials/`. Read the relevant `.mdx`/`.md` file for any feature you are working with.
- **CI tests in `./templates/ci/modules/features/`** are the most authoritative, isolated, fully working examples of every Den feature. They use `nix-unit` and the `denTest` helper. Study them before writing any non-trivial Den code.
- **Source implementation is in `./nix/lib/`** (library primitives) and **`./modules/`** (framework, context types, batteries). Read the source when you need to understand exact semantics.
- **`./templates/`** contains complete starter templates for different setups. Read a relevant template when scaffolding a new project.

**Priority for answering any Den question:**

```
CI tests (./templates/ci/modules/features/) 
  → docs (./docs/src/content/docs/)
    → source (./nix/, ./modules/)
      → templates (./templates/)
```

---

## Repository Map

Read these directories on an as-needed basis:

| Path | Purpose |
|------|---------|
| `./docs/src/content/docs/` | Full documentation: explanation, guides, reference, tutorials |
| `./nix/lib/` | Core library: `parametric.nix`, `can-take.nix`, `den-brackets.nix`, `namespace.nix`, etc. |
| `./modules/` | Framework: `aspects/`, `context/`, `config.nix`, `options.nix`, `output.nix` |
| `./modules/aspects/provides/` | All built-in batteries (`forward.nix`, `mutual-provider.nix`, `define-user.nix`, etc.) |
| `./modules/context/` | Context type definitions (`os.nix`, `types.nix`, `user.nix`, `host.nix`) |
| `./templates/ci/modules/features/` | **CI feature tests — isolated, fully working examples of every feature** |
| `./templates/ci/modules/test-support/eval-den.nix` | Test harness showing how to set up `denTest` and `evalDen` |
| `./templates/default/` | Recommended starter: flake-parts + home-manager |
| `./templates/minimal/` | Minimal: flakes, no flake-parts |
| `./templates/noflake/` | No-flake: npins + lib.evalModules |
| `./templates/microvm/` | Advanced: custom context pipeline + MicroVM integration |
| `./templates/nvf-standalone/` | Den as library for non-NixOS domains (NVF neovim) |
| `./templates/example/` | Cross-platform NixOS + Darwin with namespaces |

---

## Core Concepts

### Aspects

An **aspect** is a Nix attrset with keys named after Nix classes (`nixos`, `darwin`, `homeManager`, `hjem`, `maid`, or any custom class), plus `includes` and `provides`. It consolidates all configuration for a single concern across all relevant Nix domains.

Den **auto-generates** a `parametric` aspect for every `den.hosts`, `den.homes`, and `den.hosts.<sys>.<name>.users` entry you declare. You extend those auto-generated aspects in any module file.

Read: `./docs/src/content/docs/explanation/aspects.mdx`, `./docs/src/content/docs/guides/configure-aspects.mdx`

Source: `./modules/aspects/definition.nix`

### Parametric Dispatch

Den inspects function arguments at evaluation time using `builtins.functionArgs`. A function in an `includes` list is called **only when its required arguments are satisfied by the current context**. This is parametric dispatch — no `mkIf`, no `enable` flags needed. The context shape **is** the condition.

| Context | Functions activated |
|---------|-------------------|
| `{ host }` | Functions requiring only `host` |
| `{ host, user }` | Functions requiring `host` and/or `user` |
| `{ home }` | Functions requiring `home` |

**Variants**: `parametric` (default, `atLeast`), `parametric.exactly`, `parametric.fixedTo`, `parametric.expands`, `parametric.atLeast`.

Read: `./docs/src/content/docs/explanation/parametric.mdx`, `./docs/src/content/docs/reference/lib.mdx`

CI tests: `./templates/ci/modules/features/parametric.nix`, `./templates/ci/modules/features/auto-parametric.nix`, `./templates/ci/modules/features/perUser-perHost.nix`

### Context System & Pipeline

Den's evaluation pipeline walks **context types** (`den.ctx.<name>`). Each context type defines:
- `_` (alias `provides`) — functions that contribute aspect fragments to this context.
- `into` — functions that produce derived contexts (fan-out).
- `includes` — aspect includes attached to this context type.
- `modules` — additional modules merged into the resolved output.

The built-in pipeline for OS configurations:

```
den.hosts → den.ctx.host {host}
               → into.user → den.ctx.user {host, user}
               → into.hm-host → den.ctx.hm-host {host}
                                  → into.hm-user → den.ctx.hm-user {host, user}
               → into.hjem-host, into.maid-host, into.wsl-host (batteries)
den.homes → den.ctx.home {home}
```

Read: `./docs/src/content/docs/explanation/context-pipeline.mdx`, `./docs/src/content/docs/explanation/context-system.mdx`, `./docs/src/content/docs/reference/ctx.mdx`

Source: `./modules/context/os.nix`, `./modules/context/types.nix`

CI tests: `./templates/ci/modules/features/context/`

### Schema — Hosts, Users, Homes

`den.schema.{host,user,home,conf}` are **base modules** (not aspects) — they define typed options and defaults applied to every entity of that kind. Use them for meta-configuration (capabilities, features) that aspects will later read.

- `den.schema.conf` — applied to all hosts, users, and homes.
- `den.schema.host` — all hosts.
- `den.schema.user` — all users.
- `den.schema.home` — all homes.

All host/user/home types have `freeformType` — you can attach arbitrary attributes as metadata.

Read: `./docs/src/content/docs/reference/schema.mdx`, `./docs/src/content/docs/guides/declare-hosts.mdx`

Source: `./modules/options.nix`

CI tests: `./templates/ci/modules/features/schema-base-modules.nix`, `./templates/ci/modules/features/host-options.nix`

### den.default — Global Policies

`den.default` is a special aspect applied to **every** host, user, and home. Use it for global policies such as `stateVersion`, globally included batteries, or universal settings.

**Important**: Owned configs and static includes from `den.default` are deduplicated across pipeline stages. Parametric functions in `den.default.includes` run at every context stage — use `den.lib.perHost`, `den.lib.perUser`, or `den.lib.perHome` to restrict to a specific context when needed.

Read: `./docs/src/content/docs/guides/configure-aspects.mdx`

CI tests: `./templates/ci/modules/features/default-includes.nix`, `./templates/ci/modules/features/context/den-default.nix`

---

## Feature Reference

### Declaring Hosts & Users

```nix
den.hosts.x86_64-linux.my-laptop.users.alice = {};
den.hosts.aarch64-darwin.mac.users.alice = {};
```

Key host options: `name`, `hostName`, `system`, `class` (auto: `"nixos"` or `"darwin"`), `aspect` (defaults to `name`), `instantiate`, `intoAttr`, `users`, plus any freeform metadata attributes.

Key user options: `name`, `userName`, `aspect`, `classes` (default `[ "homeManager" ]`), plus freeform.

Read: `./docs/src/content/docs/guides/declare-hosts.mdx`, `./docs/src/content/docs/reference/schema.mdx`

CI tests: `./templates/ci/modules/features/host-options.nix`, `./templates/ci/modules/features/user-classes.nix`

### Declaring Standalone Homes

```nix
den.homes.x86_64-linux.alice = {};
den.homes.x86_64-linux."alice@igloo" = {};  # bound to host igloo
```

`"user@host"` format: Den sets `home.hostName` and, if `igloo` exists as a `den.hosts` entry, automatically provides `osConfig` to the home's `homeManager` modules.

Key home options: `name`, `userName`, `system`, `class` (`"homeManager"`), `aspect`, `pkgs`, `instantiate`, `intoAttr`.

Read: `./docs/src/content/docs/guides/home-manager.mdx`

CI tests: `./templates/ci/modules/features/homes.nix`, `./templates/ci/modules/features/special-args-custom-instantiate.nix`

### Configuring Aspects

Aspects have three kinds of attributes:

1. **Owned configs** — keys named after a Nix class (`nixos`, `darwin`, `homeManager`, `hjem`, `maid`, `os`, or any custom class). Values are regular Nix modules (attrset or function form).

2. **`includes`** — a list of aspects/functions forming a dependency DAG. Three kinds of values:
   - Static attrset: `{ nixos.foo = …; }` — included unconditionally.
   - Static leaf (flake-aspects): `{ class, aspect-chain }: { … }` — evaluated during resolution.
   - Parametric function: `{ host, user, … }: { … }` — dispatched by context via `canTake`.

3. **`provides`** (alias `_`) — named sub-aspects accessible via `den.aspects.foo._.bar` or `den.aspects.foo.provides.bar`.

**Named aspects are always preferred over anonymous inline functions in `includes`.** Anonymous functions produce worse error traces.

Read: `./docs/src/content/docs/guides/configure-aspects.mdx`, `./docs/src/content/docs/reference/aspects.mdx`

CI tests: `./templates/ci/modules/features/parametric.nix`, `./templates/ci/modules/features/provides-parametric.nix`

### Home Environments

Den supports four home/user Nix classes:

| Class | Forwarded to | Requires |
|-------|-------------|---------|
| `user` | `users.users.<userName>` on NixOS/Darwin (built-in) | auto |
| `homeManager` | `home-manager.users.<userName>` | `inputs.home-manager`, user `classes = [ "homeManager" ]` |
| `hjem` | `hjem.users.<userName>` | `inputs.hjem`, user `classes = [ "hjem" ]` |
| `maid` | `users.users.<userName>.maid` | `inputs.nix-maid`, NixOS class, user `classes = [ "maid" ]` |

All home integrations are opt-in. Enable per user or globally:

```nix
den.schema.user.classes = lib.mkDefault [ "homeManager" ];
```

A user can participate in multiple classes simultaneously.

Read: `./docs/src/content/docs/guides/home-manager.mdx`

Source: `./modules/aspects/provides/home-manager.nix`, `./modules/aspects/provides/hjem.nix`, `./modules/aspects/provides/maid.nix`

CI tests: `./templates/ci/modules/features/hjem-class.nix`, `./templates/ci/modules/features/home-manager/`

### Batteries

Batteries are reusable aspects shipped under `den.provides.*` (aliased as `den._.*`).

| Battery | Purpose |
|---------|---------|
| `den._.define-user` | Creates OS-level user accounts + HM `home.username`/`home.homeDirectory` |
| `den._.hostname` | Sets `networking.hostName` from `host.hostName` |
| `den._.primary-user` | Marks user as admin: `wheel`/`networkmanager` groups on NixOS, `system.primaryUser` on Darwin, `defaultUser` on WSL |
| `den._.user-shell "fish"` | Sets login shell at OS and HM level |
| `den._.mutual-provider` | Enables host↔user cross-configuration via `.provides.` |
| `den._.forward { … }` | Creates custom Nix classes by forwarding module contents |
| `den._.import-tree` | Recursively imports non-dendritic `.nix` files, auto-detecting class from directory names |
| `den._.unfree [ "pkg" ]` | Enables specific unfree packages |
| `den._.tty-autologin "user"` | Configures TTY1 auto-login on NixOS |
| `den._.inputs'` | Exposes flake-parts `inputs'` as module argument |
| `den._.self'` | Exposes flake-parts `self'` as module argument |
| `den._.wsl` | Activates WSL integration context |
| `den._.os-user` | (built-in) Forwards `user` class to `users.users.<userName>` |
| `den._.os-class` | (built-in) Forwards `os` class to both `nixos` and `darwin` |

Read: `./docs/src/content/docs/guides/batteries.mdx`, `./docs/src/content/docs/reference/batteries.mdx`

Source: `./modules/aspects/provides/`

CI tests: `./templates/ci/modules/features/batteries/`

### Mutual Providers

By default the pipeline is unidirectional (host → users). Enabling `den._.mutual-provider` in `den.ctx.user.includes` activates bidirectional cross-configuration:

- `den.aspects.my-host.provides.to-users` — host configures all its users.
- `den.aspects.my-host.provides.<userName>` — host configures a specific user.
- `den.aspects.my-user.provides.to-hosts` — user configures all hosts it lives on.
- `den.aspects.my-user.provides.<hostName>` — user configures a specific host.
- `den.aspects.my-user.provides.<hostName>` also works for standalone `"user@host"` homes.

Read: `./docs/src/content/docs/guides/mutual.mdx`

Source: `./modules/aspects/provides/mutual-provider.nix`

CI tests: `./templates/ci/modules/features/user-host-mutual-config.nix`, `./templates/ci/modules/features/conditional-config.nix`

### Custom Nix Classes

`den.provides.forward` creates a new Nix class by forwarding module contents from a `fromClass` into a `intoPath` on an `intoClass`. This is how `homeManager`, `hjem`, `maid`, `user`, `os`, and `wsl` are implemented internally.

Parameters: `each`, `fromClass`, `intoClass`, `intoPath`, `fromAspect`, and optionally `guard`, `adaptArgs`, `adapterModule`.

Use `{ class, aspect-chain }:` as the function signature to access the current class being resolved and the aspect chain leading to it. `lib.head aspect-chain` gives the innermost aspect.

Register the class in the pipeline by adding the forwarder to `den.ctx.user.includes` or `den.ctx.host.includes`.

Read: `./docs/src/content/docs/guides/custom-classes.mdx`

Source: `./modules/aspects/provides/forward.nix`, `./modules/aspects/provides/os-user.nix`, `./modules/aspects/provides/os-class.nix`

CI tests:
- `./templates/ci/modules/features/forward-alias-class.nix` — alias class forwarding, `osConfig` access, platform-specific HM classes
- `./templates/ci/modules/features/forward-from-custom-class.nix` — full custom class creation
- `./templates/ci/modules/features/os-class.nix` — `os` class forwarding to both NixOS and Darwin
- `./templates/ci/modules/features/os-user-class.nix` — `user` class forwarding

### Guarded Forwarding

`den.provides.forward` accepts an optional `guard` parameter. The guard receives module args and optionally the loop item, and must return either `lib.optionalAttrs` (test on options/structure) or `lib.mkIf` (test on config values). Guards centralise feature-detection in one place; aspects write to the custom class without any `mkIf`.

- Use `lib.optionalAttrs (options ? foo)` to test whether an option exists.
- Use `lib.mkIf config.foo.enable` to test a config value.

Read: `./docs/src/content/docs/guides/custom-classes.mdx` (Guards section)

CI tests: `./templates/ci/modules/features/guarded-forward.nix`

### Namespaces & Cross-Flake Sharing

A namespace creates a scoped aspect library under `den.ful.<name>` and exposes it as a module argument `<name>`. Aspects inside a namespace are completely independent from `den.aspects`.

```nix
imports = [ (inputs.den.namespace "eg" true) ];   # create + export
imports = [ (inputs.den.namespace "eg" false) ];  # create, local only
imports = [ (inputs.den.namespace "eg" [ inputs.upstream ]) ]; # merge from upstream
```

Namespaces also have their own `ctx` and `schema` sub-namespaces for library-grade aspect publishing.

Upstream flake must expose `flake.denful.<name>` (set automatically by `den.namespace`).

Read: `./docs/src/content/docs/guides/namespaces.mdx`, `./docs/src/content/docs/reference/aspects.mdx`

Source: `./nix/lib/namespace.nix`, `./nix/lib/namespace-types.nix`

CI tests: `./templates/ci/modules/features/namespaces.nix`, `./templates/ci/modules/features/namespace-schemas.nix`, `./templates/ci/modules/features/namespace-provider.nix`, `./templates/ci/modules/features/provides-parametric.nix`

### Angle Brackets Syntax

`den.lib.__findFile` implements a `__findFile` that resolves `<name>` angle-bracket expressions:

| Expression | Resolves to |
|-----------|------------|
| `<den.x.y>` | `config.den.x.y` |
| `<aspect>` | `config.den.aspects.aspect` |
| `<aspect/sub>` | `config.den.aspects.aspect.provides.sub` |
| `<aspect/sub/deep>` | `config.den.aspects.aspect.provides.sub.provides.deep` |
| `<namespace>` | `config.den.ful.namespace` |
| `<namespace/aspect>` | `config.den.ful.namespace.aspect` |

Enable per-module:
```nix
{ den, __findFile, ... }: {
  _module.args.__findFile = den.lib.__findFile;
  …
}
```

Read: `./docs/src/content/docs/guides/angle-brackets.mdx`

Source: `./nix/lib/den-brackets.nix`

CI tests: `./templates/ci/modules/features/angle-brackets.nix`

### Schema Base Modules

`den.schema.host`, `den.schema.user`, `den.schema.home`, `den.schema.conf` accept `deferredModule` values. The module receives `{ host, lib, … }`, `{ user, host, lib, … }`, or `{ home, lib, … }` as `specialArgs`. Modules can define `options` with `lib.mkOption` and set defaults with `lib.mkDefault`.

These are not aspects — they define typed metadata on the entity objects themselves. Aspects then read these values from `host.*`, `user.*`, or `home.*`.

Read: `./docs/src/content/docs/reference/schema.mdx`

CI tests: `./templates/ci/modules/features/schema-base-modules.nix`

### Custom Context Types

Define new `den.ctx.<name>` entries to extend or replace the pipeline:

```nix
den.ctx.my-stage = {
  description = "…";
  _.my-stage = { my-data }: { class-name.foo = my-data.value; };
  into.next-stage = { my-data }: lib.optional condition { … };
};
den.ctx.host.into.my-stage = { host }: lib.optional host.feature.enable { inherit host; };
```

See `templates/microvm` for a production example with two-stage custom pipeline.

Read: `./docs/src/content/docs/explanation/context-system.mdx`, `./docs/src/content/docs/reference/ctx.mdx`

Source: `./modules/context/types.nix`

CI tests: `./templates/ci/modules/features/context/custom-ctx.nix`, `./templates/ci/modules/features/context/apply.nix`, `./templates/ci/modules/features/context/cross-provider.nix`

### den.lib — Core Library Functions

| Function | Purpose |
|----------|---------|
| `den.lib.parametric { … }` | Wrap aspect with `atLeast` context dispatch |
| `den.lib.parametric.exactly { … }` | Wrap with exactly-matching dispatch |
| `den.lib.parametric.fixedTo attrs aspect` | Call aspect with fixed context |
| `den.lib.parametric.expands attrs aspect` | Extend context before dispatch |
| `den.lib.canTake params fn` | `true` if `fn`'s required args ⊆ `params` (`atLeast`) |
| `den.lib.canTake.exactly params fn` | `true` if required args = `params` exactly |
| `den.lib.take.atLeast fn ctx` | Apply `fn ctx` if `canTake.atLeast`, else `{}` |
| `den.lib.take.exactly fn ctx` | Apply `fn ctx` if `canTake.exactly`, else `{}` |
| `den.lib.perHost aspect` | Restrict aspect to `{ host }` contexts only |
| `den.lib.perUser aspect` | Restrict aspect to `{ host, user }` contexts only |
| `den.lib.perHome aspect` | Restrict aspect to `{ home }` contexts only |
| `den.lib.statics aspect ctx` | Extract only static includes |
| `den.lib.owned aspect` | Extract owned configs (no includes, no functor) |
| `den.lib.isFn v` | `true` if `v` is function or has `__functor` |
| `den.lib.__findFile` | Angle bracket resolver |
| `den.lib.aspects` | Full flake-aspects API: `resolve`, `merge`, types |

Read: `./docs/src/content/docs/reference/lib.mdx`

Source: `./nix/lib/default.nix`, `./nix/lib/parametric.nix`, `./nix/lib/can-take.nix`

CI tests: `./templates/ci/modules/features/parametric.nix`, `./templates/ci/modules/features/perUser-perHost.nix`

### Den as a Pure Library

Den's `default.nix` (the `nixModule`) is domain-agnostic: no `den.hosts`, `den.homes`, or OS batteries. Use it to build context pipelines for any Nix module system (Terranix, NixVim, system-manager, NVF, etc.):

```nix
denModule = (import denPath).nixModule inputs;
# or
den-lib = import denPath { inherit lib config inputs; };
```

Read: `./docs/src/content/docs/explanation/library-vs-framework.mdx`

CI tests: `./templates/ci/modules/features/den-as-lib.nix`

Template: `./templates/nvf-standalone/`

### Output Generation

Den calls `host.instantiate { modules = [ host.mainModule { nixpkgs.hostPlatform = … } ]; }` for each host, and `home.instantiate { pkgs = …; modules = [ home.mainModule ]; }` for each home. Results are placed at `flake.<intoAttr>`.

Default `intoAttr` values: `[ "nixosConfigurations" name ]`, `[ "darwinConfigurations" name ]`, `[ "homeConfigurations" name ]`, `[ "systemConfigs" name ]`.

Override `instantiate` or `intoAttr` per entity:
```nix
den.hosts.x86_64-linux.myhost.instantiate = inputs.nixos-unstable.lib.nixosSystem;
den.hosts.x86_64-linux.myhost.intoAttr = [ "nixosConfigurations" "custom-name" ];
den.hosts.x86_64-linux.guest.intoAttr = [];  # suppress flake output
```

Den provides its own `flake` option (adapted from flake-parts) so output generation works identically with or without flake-parts.

Read: `./docs/src/content/docs/reference/output.mdx`

Source: `./modules/config.nix`, `./modules/output.nix`

### WSL Support

Enable WSL integration per host:
```nix
den.hosts.x86_64-linux.my-wsl.wsl.enable = true;
```
This activates `den.ctx.wsl-host` which imports the NixOS-WSL module and creates a `wsl` class forward. The `den._.primary-user` battery also sets `wsl.defaultUser`.

Source: `./modules/aspects/provides/wsl.nix`

### MicroVM & Advanced Extensibility

`templates/microvm` is the canonical reference for deep Den extensibility: custom `den.ctx` stages, custom `den.schema.host` options, and `den.provides.forward` to wire guest VM configuration into the host.

Key patterns:
- Extend `den.schema.host` with custom options via a module in `den.schema.host = { host, lib, … }: { options.microvm.guests = …; }`.
- Add pipeline stages: `den.ctx.host.into.microvm-host = { host }: lib.optional (host.microvm.guests != []) { inherit host; }`.
- Use `den.provides.forward` to forward a guest's resolved NixOS module into `host.nixos.microvm.vms.<name>.config`.
- Set `intoAttr = []` on guest hosts to suppress them as top-level flake outputs.

Read: `./docs/src/content/docs/tutorials/microvm.md`

Template: `./templates/microvm/`

### flake-parts Integration

`den._.inputs'` and `den._.self'` expose flake-parts' system-specialised `inputs'` and `self'` as module arguments inside aspect modules. Include them in `den.default` or per-aspect.

These only work when the module system is flake-parts. Source: `./modules/aspects/provides/flake-parts/`

CI tests: `./templates/ci/modules/features/batteries/flake-parts.nix`

---
