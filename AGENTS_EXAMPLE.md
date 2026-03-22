# AGENTS.md — Den AI Agent Guide

> **For AI coding agents helping users adopt and use Den.**
> Den is an aspect-oriented, context-driven Dendritic Nix configuration framework.
> Read this document fully before generating any Den configuration.

---

## 1. Mandatory Source Consultation

**Always read the source on an as-needed basis.** Do not guess at API shapes or option names. Instead, look them up directly in the repository. The following directories are your primary references:

| Directory | What it contains |
|-----------|-----------------|
| `./docs/src/content/docs/` | Full user-facing documentation (explanation, guides, reference, tutorials) |
| `./nix/` | Core Den library (`parametric`, `canTake`, `take`, `__findFile`, context types, etc.) |
| `./modules/` | OS framework (schema options, aspect definition, batteries, context wiring, output) |
| `./templates/ci/modules/` | **Every Den feature as a fully isolated, executable nix-unit test** |

The CI test suite at `./templates/ci/modules/features/` is the **most authoritative** working-code reference. Every test is a self-contained, evaluated Nix expression that demonstrates exactly how a feature behaves. Read the relevant test file whenever you need a code example.

**Key source files to consult on demand:**

- `docs/src/content/docs/explanation/core-principles.mdx` — Design philosophy
- `docs/src/content/docs/explanation/aspects.mdx` — Aspect & functor pattern
- `docs/src/content/docs/explanation/parametric.mdx` — Parametric dispatch mechanics
- `docs/src/content/docs/explanation/context-pipeline.mdx` — Host → user → home pipeline
- `docs/src/content/docs/explanation/context-system.mdx` — `den.ctx` architecture
- `docs/src/content/docs/explanation/library-vs-framework.mdx` — Using Den without NixOS
- `docs/src/content/docs/reference/lib.mdx` — Full `den.lib` API
- `docs/src/content/docs/reference/ctx.mdx` — Full `den.ctx` API
- `docs/src/content/docs/reference/schema.mdx` — `den.hosts`, `den.homes`, `den.schema`
- `docs/src/content/docs/reference/aspects.mdx` — `den.aspects`, `den.provides`, `den.ful`
- `docs/src/content/docs/reference/batteries.mdx` — All `den.provides.*` batteries
- `docs/src/content/docs/reference/output.mdx` — Flake output generation
- `docs/src/content/docs/guides/` — Practical cookbooks (batteries, custom classes, namespaces, migration, debugging)
- `nix/lib/default.nix` — Library entrypoint (all sub-modules listed)
- `modules/options.nix` — `den.hosts`, `den.homes`, `den.schema` option declarations
- `modules/config.nix` — How hosts and homes are instantiated into flake outputs
- `modules/aspects/provides/` — All built-in battery implementations

---

## 2. Den in One Paragraph

Den is built on [`flake-aspects`](https://github.com/vic/flake-aspects). It inverts the traditional host-centric Nix model: **aspects** (features) are the primary unit of organization. Each aspect declares its behavior per Nix *class* (`nixos`, `darwin`, `homeManager`, `hjem`, `maid`, `user`, custom…). Hosts simply include the aspects they need. A **context pipeline** (`den.ctx`) transforms host/user/home declarations into fully resolved Nix module system inputs. Parametric dispatch (via `builtins.functionArgs` introspection) means a function requiring `{ host, user }` is silently skipped in a `{ host }`-only context — no `mkIf`, no `enable` flags needed to gate context-sensitive configuration.

---

## 3. Core Concepts

### 3.1 Aspects

An aspect is an attrset containing:
- **Owned configs**: keys named after Nix classes (`nixos`, `darwin`, `homeManager`, `hjem`, `maid`, `user`, `os`, or any custom class). Values are plain attrset modules or function modules (`{ pkgs, ... }: { }`).
- **`includes`**: a list of other aspects, static attrsets, or parametric functions to include as dependencies.
- **`provides`**: named sub-aspects scoped to this aspect, accessible via `den.aspects.foo.provides.bar` or the shorthand `den.aspects.foo._.bar`.

Read: `docs/src/content/docs/explanation/aspects.mdx`, `docs/src/content/docs/guides/configure-aspects.mdx`  
CI examples: `templates/ci/modules/features/parametric.nix`, `templates/ci/modules/features/top-level-parametric.nix`, `templates/ci/modules/features/auto-parametric.nix`

### 3.2 Parametric Dispatch

Den uses `builtins.functionArgs` to inspect a function's declared arguments. A function is included only when all its **required** (non-default) arguments are present in the current context:

- `{ host, ... }` → matches `{ host }`, `{ host, user }`, etc. (atLeast)
- `{ host, user }` → matches only when both are present
- `{ home }` → matches only standalone home contexts
- `{ class, aspect-chain }` → static aspect (evaluated during resolution, not per-context)

`den.lib.parametric` wraps an aspect with this dispatch logic. `den.lib.canTake`, `den.lib.take.atLeast`, `den.lib.take.exactly` are the underlying primitives.

Read: `docs/src/content/docs/explanation/parametric.mdx`, `docs/src/content/docs/reference/lib.mdx`  
CI examples: `templates/ci/modules/features/parametric.nix`

**Parametric variants:**

| Constructor | Behavior |
|---|---|
| `den.lib.parametric` | Owned + statics + atLeast function includes |
| `den.lib.parametric.atLeast` | Only function includes matching atLeast |
| `den.lib.parametric.exactly` | Only function includes matching exactly |
| `den.lib.parametric.fixedTo attrs aspect` | Always uses given attrs as context |
| `den.lib.parametric.expands attrs aspect` | Extends received context with attrs |

**Context shortcuts** (built on `take.exactly` + `fixedTo`):
- `den.lib.perHost aspect` — runs only in `{ host }` contexts
- `den.lib.perUser aspect` — runs only in `{ host, user }` contexts
- `den.lib.perHome aspect` — runs only in `{ home }` contexts

CI example: `templates/ci/modules/features/perUser-perHost.nix`

### 3.3 Aspects are Auto-Generated

Den automatically creates a parametric aspect for every declared host, user, and home. You do not need to declare `den.aspects.igloo` from scratch — you just extend it. Any module file may contribute to any aspect.

Read: `docs/src/content/docs/guides/configure-aspects.mdx`

### 3.4 `includes` Three Kinds

1. **Static plain attrset**: `{ nixos.foo = 1; }` — always included unconditionally.
2. **Static leaf** `{ class, aspect-chain }: ...` — evaluated once during resolution.
3. **Parametric function** `{ host, user, ... }: ...` — evaluated per context, only when argument requirements are met.

> **Anti-pattern**: Avoid anonymous inline functions in `includes`. Use named aspects instead — this produces better error traces and more readable code.

---

## 4. Declaring Hosts, Users, and Homes

### 4.1 Hosts

```nix
den.hosts.x86_64-linux.laptop.users.alice = {};
den.hosts.aarch64-darwin.mac.users.alice = {};
```

Host options (all have defaults):

| Option | Default | Description |
|--------|---------|-------------|
| `name` | attrset key | Config name |
| `hostName` | `name` | Network hostname |
| `system` | parent key | Platform |
| `class` | auto from system | `"nixos"` or `"darwin"` |
| `aspect` | `name` | Primary aspect name |
| `instantiate` | class-dependent | OS builder function |
| `intoAttr` | class-dependent | Flake output path |
| `users` | `{}` | User declarations |
| `*` | from `den.schema.host` | Schema-defined options |
| `*` | | Freeform attributes (read from aspects via `host.myAttr`) |

Read: `docs/src/content/docs/guides/declare-hosts.mdx`, `docs/src/content/docs/reference/schema.mdx`  
CI examples: `templates/ci/modules/features/host-options.nix`

### 4.2 Users

```nix
den.hosts.x86_64-linux.laptop.users.alice = {
  classes = [ "homeManager" "hjem" ];
  userName = "alice";   # optional, defaults to key
};
```

User options:

| Option | Default | Description |
|--------|---------|-------------|
| `name` | attrset key | User config name |
| `userName` | `name` | System account name |
| `aspect` | `name` | Primary aspect |
| `classes` | `[ "homeManager" ]` | Home environment classes |
| `*` | from `den.schema.user` | Schema options |
| `*` | | Freeform (accessible via `user.myAttr`) |

CI examples: `templates/ci/modules/features/user-classes.nix`, `templates/ci/modules/features/host-options.nix`

### 4.3 Standalone Homes

```nix
den.homes.x86_64-linux.alice = {};         # → homeConfigurations.alice
den.homes.x86_64-linux."alice@laptop" = {}; # bound to hostname "laptop"
```

When `"alice@laptop"` is declared **and** `den.hosts.x86_64-linux.laptop` exists, the standalone home automatically receives `osConfig` pointing to the NixOS configuration.

Home options: `name`, `userName`, `system`, `class` (`"homeManager"`), `aspect`, `pkgs`, `instantiate`, `intoAttr`.

Read: `docs/src/content/docs/guides/home-manager.mdx`, `docs/src/content/docs/guides/declare-hosts.mdx`  
CI examples: `templates/ci/modules/features/homes.nix`, `templates/ci/modules/features/special-args-custom-instantiate.nix`

---

## 5. Configuring Aspects

### 5.1 Owned Configs

Class-keyed configs directly in the aspect. Can be attrset or function modules.

### 5.2 `den.default`

A special aspect applied to **all** hosts, users, and homes:

```nix
den.default = {
  nixos.system.stateVersion = "25.11";
  homeManager.home.stateVersion = "25.11";
  includes = [ den.provides.define-user den.provides.inputs' ];
};
```

> Owned configs in `den.default` are deduplicated across pipeline stages. Parametric functions in `den.default.includes` run at every stage — use `den.lib.perHost` / `den.lib.perUser` to restrict.

CI examples: `templates/ci/modules/features/default-includes.nix`, `templates/ci/modules/features/context/den-default.nix`

### 5.3 `provides` (Sub-Aspects)

```nix
den.aspects.tools.provides.editors = {
  homeManager.programs.helix.enable = true;
};
# Used as:
den.aspects.alice.includes = [ den.aspects.tools._.editors ];
```

`provides` can also be parametric functions.

CI examples: `templates/ci/modules/features/provides-parametric.nix`

---

## 6. Schema Base Modules

`den.schema.{conf,host,user,home}` provides shared meta-configuration (typed options with defaults) applied to every entity of the given kind. These are **not aspects** — they define metadata that aspects can later read from `host.*` / `user.*` / `home.*`.

```nix
den.schema.host = { host, lib, ... }: {
  options.hardened = lib.mkEnableOption "hardened profile";
  config.hardened = lib.mkDefault true;
};
den.schema.user = { user, lib, ... }: {
  config.classes = lib.mkDefault [ "homeManager" ];
};
den.schema.conf = { lib, ... }: {
  options.org = lib.mkOption { default = "myorg"; };
};
```

- `den.schema.conf` → applied to host, user, and home
- `den.schema.host` → all hosts (imports `conf`)
- `den.schema.user` → all users (imports `conf`)
- `den.schema.home` → all homes (imports `conf`)

Read: `docs/src/content/docs/reference/schema.mdx`  
CI examples: `templates/ci/modules/features/schema-base-modules.nix`

---

## 7. Context Pipeline (`den.ctx`)

### 7.1 Built-in Pipeline

```
den.hosts.x86_64-linux.laptop
  → den.ctx.host { host }
    → _.host  (fixedTo { host } → aspects.laptop)
    → _.user  (atLeast { host, user } → aspects.laptop)
    → into.user (per user) → den.ctx.user { host, user }
        → _.user (fixedTo { host, user } → aspects.alice)
    → into.hm-host  (if HM enabled and has HM users)
    → into.hjem-host (if hjem enabled and has hjem users)
    → into.maid-host (if maid enabled and has maid users)
    → into.wsl-host  (if host.wsl.enable = true)
```

Read: `docs/src/content/docs/explanation/context-pipeline.mdx`, `docs/src/content/docs/explanation/context-system.mdx`, `docs/src/content/docs/reference/ctx.mdx`  
CI examples: `templates/ci/modules/features/context/`

### 7.2 Context Type Anatomy

Each `den.ctx.<name>` has:
- `description` — human readable
- `_` / `provides` — map of provider functions, each taking context data and returning aspect fragments
- `into` — map of transformation functions producing new context values
- `includes` — aspect includes injected at this pipeline stage
- `modules` — additional modules merged into the resolved output

### 7.3 Built-in Context Types

| Context | Data | Purpose |
|---------|------|---------|
| `den.ctx.host` | `{ host }` | One per declared host |
| `den.ctx.user` | `{ host, user }` | One per user per host |
| `den.ctx.home` | `{ home }` | One per standalone home |
| `den.ctx.hm-host` | `{ host }` | Activates HM OS module |
| `den.ctx.hm-user` | `{ host, user }` | Forwards `homeManager` class |
| `den.ctx.wsl-host` | `{ host }` | WSL activation |
| `den.ctx.hjem-host` / `hjem-user` | `{ host }` / `{ host, user }` | hjem integration |
| `den.ctx.maid-host` / `maid-user` | `{ host }` / `{ host, user }` | nix-maid integration |

### 7.4 Custom Context Types

You can define entirely new `den.ctx.<name>` entries and wire them into the pipeline via `den.ctx.host.into.<name>`. See `templates/ci/modules/features/context/custom-ctx.nix` and the `templates/microvm` template for real examples.

CI examples: `templates/ci/modules/features/context/custom-ctx.nix`, `templates/ci/modules/features/context/cross-provider.nix`

### 7.5 Extending `den.ctx` with `includes`

Batteries and users extend `den.ctx.user.includes` or `den.ctx.host.includes` to inject behavior at that pipeline stage:

```nix
den.ctx.user.includes = [ den._.mutual-provider ];
```

---

## 8. Batteries (`den.provides.*` / `den._.*`)

`den.provides` and `den._` are aliases. All batteries live in `modules/aspects/provides/`. Always consult the source file for a battery to understand its exact behavior.

Read: `docs/src/content/docs/guides/batteries.mdx`, `docs/src/content/docs/reference/batteries.mdx`  
Source: `modules/aspects/provides/`

### System Batteries

| Battery | Usage | Effect |
|---------|-------|--------|
| `den._.define-user` | `den.default.includes = [ den._.define-user ]` | Creates `users.users.<name>` on OS + `home.username`/`home.homeDirectory` in HM |
| `den._.hostname` | `den.default.includes = [ den._.hostname ]` | Sets `networking.hostName` on NixOS/Darwin/WSL from `host.hostName` |
| `den._.primary-user` | `den.aspects.alice.includes = [ den._.primary-user ]` | Adds `wheel`/`networkmanager` groups (NixOS), sets `system.primaryUser` (Darwin), `wsl.defaultUser` (WSL) |
| `den._.user-shell` | `den.aspects.alice.includes = [ (den._.user-shell "fish") ]` | Sets login shell at OS and HM levels |
| `den._.mutual-provider` | `den.ctx.user.includes = [ den._.mutual-provider ]` | Enables bidirectional host↔user config via `provides.*` |
| `den._.tty-autologin` | `den.aspects.laptop.includes = [ (den._.tty-autologin "alice") ]` | Enables TTY1 autologin (NixOS) |
| `den._.wsl` | (auto-activated) | WSL activation; creates `wsl` forwarding class |
| `den._.os-user` | (auto-enabled) | Forwards `user` class to `users.users.<userName>` on OS |
| `den._.os-class` | (auto-enabled) | Forwards `os` class to both `nixos` and `darwin` |
| `den._.forward` | see §9 | Creates custom Nix classes by forwarding |
| `den._.import-tree` | see migration | Auto-imports directories of non-dendritic modules |
| `den._.unfree` | `den.aspects.laptop.includes = [ (den._.unfree [ "nvidia-x11" ]) ]` | Allows specific unfree packages |

CI examples: `templates/ci/modules/features/batteries/`

### Flake-Parts Batteries

| Battery | Effect |
|---------|--------|
| `den._.inputs'` | Exposes system-specialized `inputs'` as module arg |
| `den._.self'` | Exposes system-specialized `self'` as module arg |

CI example: `templates/ci/modules/features/batteries/flake-parts.nix`

---

## 9. Home Environments

Den supports multiple home environment classes. All are opt-in per user (via `user.classes`) or globally via `den.schema.user`.

### Enabling

```nix
# Per user
den.hosts.x86_64-linux.laptop.users.alice.classes = [ "homeManager" "hjem" ];

# Global default
den.schema.user.classes = lib.mkDefault [ "homeManager" ];
```

### `homeManager` Class

- Requires `inputs.home-manager` in flake inputs.
- The `homeManager` key in aspects forwards to `home-manager.users.<userName>`.
- Override HM module per host: `host.home-manager.module = inputs.home-manager-unstable.nixosModules.home-manager`.

### `hjem` Class

- Requires `inputs.hjem`.
- Users with `"hjem"` in `classes` get `hjem.users.<userName>` populated.
- Enable globally: `den.schema.host.hjem.enable = true`.

### `maid` Class

- Requires `inputs.nix-maid`.
- Host class must be `"nixos"`.
- Forwards into `users.users.<name>.maid`.

### `user` Class (Built-in)

- Always available.
- Forwards to `users.users.<userName>` on the OS.
- Replaces verbose `den.aspects.alice.nixos.users.users.alice.*` with `den.aspects.alice.user.*`.

### `os` Class (Built-in)

- Forwards to both `nixos` and `darwin` simultaneously.
- Useful for cross-platform settings that apply to all OS types.

CI examples: `templates/ci/modules/features/hjem-class.nix`, `templates/ci/modules/features/maid-class.nix`, `templates/ci/modules/features/os-class.nix`, `templates/ci/modules/features/os-user-class.nix`

Read: `docs/src/content/docs/guides/home-manager.mdx`

---

## 10. Mutual Providers

Enable bidirectional host↔user configuration using `den._.mutual-provider`:

```nix
den.ctx.user.includes = [ den._.mutual-provider ];

# User → specific host
den.aspects.alice.provides.laptop.nixos.programs.emacs.enable = true;

# User → all hosts it lives on
den.aspects.alice.provides.to-hosts = { host, ... }: { ... };

# Host → specific user
den.aspects.laptop.provides.alice.homeManager.programs.vim.enable = true;

# Host → all its users
den.aspects.laptop.provides.to-users = { user, ... }: { ... };

# Or more tersely with the `_` shorthand:
den.aspects.laptop._.to-users.homeManager.programs.direnv.enable = true;
```

Read: `docs/src/content/docs/guides/mutual.mdx`  
CI examples: `templates/ci/modules/features/user-host-mutual-config.nix`

---

## 11. Custom Nix Classes (`den._.forward`)

`den.provides.forward` creates new Nix classes by forwarding aspect content into a target submodule path on an existing class. This is how all built-in home integrations (`homeManager`, `hjem`, `maid`) and the `user` class are implemented.

Parameters:

| Parameter | Description |
|-----------|-------------|
| `each` | List of items to iterate over |
| `fromClass` | Custom class name to read from |
| `intoClass` | Target class to write into |
| `intoPath` | Target attribute path in target class |
| `fromAspect` | The aspect to read the custom class from |
| `guard` | (optional) Only forward when predicate returns true — use `lib.optionalAttrs` for option existence, `lib.mkIf` for config values |
| `adaptArgs` | (optional) Transform module arguments before forwarding |
| `adapterModule` | (optional) Custom submodule type for the forwarded submodule |

Source: `modules/aspects/provides/forward.nix`  
Read: `docs/src/content/docs/guides/custom-classes.mdx`  
CI examples: `templates/ci/modules/features/forward-alias-class.nix`, `templates/ci/modules/features/forward-from-custom-class.nix`, `templates/ci/modules/features/guarded-forward.nix`

### Guarded Forwarding

The `guard` function allows conditional class activation:

- `guard = { options, ... }: options ? environment.persistance` — forward only when the option exists
- `guard = { config, ... }: _item: lib.mkIf config.programs.vim.enable` — forward only when a config value is true

CI example: `templates/ci/modules/features/guarded-forward.nix`

---

## 12. Namespaces

Namespaces create scoped aspect libraries under `den.ful.<name>`, sharable across flakes.

```nix
# Create/export namespace
imports = [ (inputs.den.namespace "myns" true) ]; # true = export to flake.denful.myns

# Create local-only namespace
imports = [ (inputs.den.namespace "myns" false) ];

# Import from upstream flakes
imports = [ (inputs.den.namespace "myns" [ inputs.team-config ]) ];
```

After importing:
- `den.ful.myns` — the namespace attrset
- `myns` — module argument alias to `den.ful.myns`
- `flake.denful.myns` — flake output (if exported)

Each namespace has its own independent `aspects`, `ctx`, and `schema` sub-namespaces.

Read: `docs/src/content/docs/guides/namespaces.mdx`, `docs/src/content/docs/reference/aspects.mdx`  
CI examples: `templates/ci/modules/features/namespaces.nix`, `templates/ci/modules/features/namespace-schemas.nix`, `templates/ci/modules/features/namespace-provider.nix`

Source: `nix/lib/namespace.nix`

---

## 13. Angle Brackets Syntax

Enable optional syntactic sugar via `__findFile`:

```nix
{ den, ... }: {
  _module.args.__findFile = den.lib.__findFile;
}
```

Resolution rules (in order):
1. `<den.x.y>` → `config.den.x.y`
2. `<aspect>` → `config.den.aspects.aspect`
3. `<aspect/sub>` → `config.den.aspects.aspect.provides.sub`
4. `<namespace>` → `config.den.ful.namespace`
5. `<namespace/path>` → nested `provides` traversal

The `/` separator maps to `.provides.` in the lookup path.

To use angle brackets in a specific file, add `__findFile` to the module arguments attrset.

Read: `docs/src/content/docs/guides/angle-brackets.mdx`  
Source: `nix/lib/den-brackets.nix`  
CI examples: `templates/ci/modules/features/angle-brackets.nix`

---

## 14. `den.lib` API

Full reference: `docs/src/content/docs/reference/lib.mdx`  
Source: `nix/lib/default.nix`

| Function | Purpose |
|----------|---------|
| `den.lib.parametric` | Wrap aspect with context-aware dispatch (atLeast) |
| `den.lib.parametric.atLeast` | Same as `parametric` |
| `den.lib.parametric.exactly` | Match only when required args exactly equal context |
| `den.lib.parametric.fixedTo attrs aspect` | Apply aspect with fixed context |
| `den.lib.parametric.expands attrs aspect` | Extend context with attrs before dispatch |
| `den.lib.parametric.withOwn` | Low-level constructor |
| `den.lib.canTake params fn` | Check if fn's required args are satisfied (atLeast) |
| `den.lib.canTake.atLeast params fn` | Same as above |
| `den.lib.canTake.exactly params fn` | Exact parameter match check |
| `den.lib.take.atLeast fn ctx` | Call fn ctx if canTake.atLeast, else `{}` |
| `den.lib.take.exactly fn ctx` | Call fn ctx if canTake.exactly, else `{}` |
| `den.lib.perHost aspect` | Restrict to `{ host }` contexts |
| `den.lib.perUser aspect` | Restrict to `{ host, user }` contexts |
| `den.lib.perHome aspect` | Restrict to `{ home }` contexts |
| `den.lib.statics aspect ctx` | Extract only static includes |
| `den.lib.owned aspect` | Extract owned configs (no includes/functor) |
| `den.lib.isFn value` | True if value is function or has `__functor` |
| `den.lib.isStatic fn` | True if fn accepts `{ class, aspect-chain }` |
| `den.lib.__findFile` | Angle bracket resolver |
| `den.lib.aspects` | Full flake-aspects API (`resolve`, `merge`, types) |

---

## 15. Den as a Pure Library (Non-OS Domains)

Den's `den.lib` is domain-agnostic. It can configure any Nix module system (Terranix, NixVim, system-manager, NVF, MicroVM, custom). The OS framework (`modules/`) is entirely optional.

Import without the framework:
```nix
# Use the nixModule for any module system
denModule = (import inputs.den.outPath).nixModule inputs;
ev = lib.evalModules { modules = [ denModule <your-module> ]; };
```

Or call the library directly:
```nix
den-lib = import inputs.den.outPath { inherit lib config inputs; };
```

The library module has empty `den.ctx` and `den.aspects` — you populate them for your custom domain.

Read: `docs/src/content/docs/explanation/library-vs-framework.mdx`  
CI example: `templates/ci/modules/features/den-as-lib.nix`

---

## 16. Flake Output Generation

Den wires into `flake.nixosConfigurations`, `flake.darwinConfigurations`, `flake.homeConfigurations` automatically via `modules/config.nix`.

- Each host calls `host.instantiate { modules = [ host.mainModule { nixpkgs.hostPlatform = host.system; } ]; }`.
- `host.instantiate` defaults: `inputs.nixpkgs.lib.nixosSystem` (nixos), `inputs.darwin.lib.darwinSystem` (darwin).
- Override `instantiate` to use a different builder or add `specialArgs`.
- Override `intoAttr` to place output at a custom flake path (set to `[]` to suppress output entirely — used for microvm guests).

Read: `docs/src/content/docs
