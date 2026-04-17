# FX Pipeline — Unified Effects Architecture

**Branch:** `feat/fx-resolution`
**Status:** Implemented (enabled by default)
**Depends on:** `nix-effects` with effectful handler support

## Overview

The fx pipeline replaces den's legacy recursive tree-walking resolution with an effects-based architecture. Aspects are compiled into effectful computations — the tree structure emerges from effect composition, not explicit recursion. All resolution strategy (constraint checking, dedup, tracing, context dispatch) lives in handlers.

### Design goals

1. **Aspects are computations.** An aspect `{ nixos = ...; includes = [...] }` compiles to a computation that emits `emit-class` per class and `emit-include` per child. The compilation function is `aspectToEffect`. Aspects know nothing about constraints, tracing, or chain tracking.
2. **No internal `fx.handle`.** Resolution stays in the effectful world from root to leaf. `fx.handle` runs once at the pipeline edge.
3. **All strategy in handlers.** Constraint checking, recursion, dedup, tracing, context dispatch — each is a handler. Handlers compose via `composeHandlers`. Adding new resolution behavior means adding a handler, not modifying the compiler.

## Module structure

```
nix/lib/aspects/fx/
  default.nix              — barrel: { lib, den } only, no init, no re-exports
  aspect.nix               — aspectToEffect compiler (compileStatic, compileFunctor)
  pipeline.nix             — mkPipeline, defaultHandlers, fxResolve, composeHandlers
  identity.nix             — aspectPath, pathKey, toPathSet, tombstone, collectPathsHandler, pathSetHandler
  constraints.nix          — exclude, substitute, filterBy constructors
  includes.nix             — includeIf conditional inclusion
  trace.nix                — structuredTraceHandler, tracingHandler
  handlers/
    default.nix            — barrel for handler subdirectory
    include.nix            — emit-include handler (effectful, owns recursion)
    transition.nix         — into-transition handler (scope.stateful)
    ctx.nix                — constantHandler, ctxSeenHandler
    tree.nix               — constraintRegistryHandler, chainHandler, classCollectorHandler
```

Every module takes `{ lib, den, ... }` as its function args. Dependencies are accessed via fully qualified paths (`den.lib.fx.identity.pathKey`, `den.lib.fx.constraints.exclude`, etc.). The nix-effects library is accessed as `den.lib.fx`.

There is no `init` function. Modules load lazily through the barrel — pure constructors (`exclude`, `substitute`, `filterBy`, `includeIf`) don't touch nix-effects at all.

## The aspect compiler: `aspectToEffect`

`aspectToEffect` replaces `resolveAspect`, `resolveOne`, `wrapAspect`, `wrapIdentity`, `emitClassConfig`, and `registerHandlers`. One function compiles any aspect into an effectful computation.

**Input:** An aspect attrset — `{ name, meta, nixos, homeManager, includes, __functor, ... }`

**Output:** A `Computation` that, when handled, emits effects for everything the aspect declares.

### Static aspects

For a non-functor aspect, `compileStatic` emits:

1. `emit-class` for each class key (everything not in the structural key set: `name`, `meta`, `includes`, `provides`, `into`, `__functor`, `__functionArgs`)
2. `register-constraint` for each entry in `meta.handleWith` / `meta.excludes`
3. `chain-push` (if the node is meaningful — has a real name, not `<anon>` or `<function body>`)
4. Self-provide children (`emitSelfProvide`), transition children (`emitTransitions`), and include children (`emitIncludes`) — all within the chain scope
5. `chain-pop` (if pushed)
6. `resolve-complete` with the resolved aspect

The compiler emits effects in this order via `fx.bind` chains. It does not check constraints, trace, or recurse — those are handler responsibilities.

### Functor (parametric) aspects

When an aspect has `__functor`, it's parametric. `compileFunctor` uses `bind.fn`:

```nix
fx.bind.fn {
  __functionArgs = lib.functionArgs aspect;
  __functor = _: args: aspectToEffect (aspect args);
}
```

`bind.fn` sends one effect per declared arg (`host`, `user`, `class`, etc.). Handlers provide the values via `constantHandler`. The result feeds into the functor, producing a new aspect attrset, which is merged with the parent envelope's `meta` (preserving `meta.provider` chain) and recursively compiled.

### `wrapChild` normalization

`wrapChild` (in `handlers/include.nix`) normalizes each child in `includes` before the `emit-include` handler compiles it. This is the most bug-prone area of the pipeline — children arrive in many forms from the type system, user code, and `deepRecurse` wrappers.

**Three cases:**

1. **Attrset (not a function):** Pass through unchanged. Already a well-formed aspect.

2. **Functor attrset (isFunction=true, isAttrs=true):** These are attrsets with `__functor` — typically `deepRecurse` wrappers or type-system-merged aspects with `defaultFunctor`. The stale `__functionArgs` on the outer attrset may not reflect the real inner function's args. `wrapChild` extracts `innerFn = child.__functor child`, gets the real args from `innerFn`, and replaces `__functionArgs` so `aspectToEffect` makes the correct parametric/static decision.

3. **Bare lambda (isFunction=true, isAttrs=false):** Two sub-cases:
   - **Module function** (`{ config, lib, ... }: ...`): Detected via `canTake.upTo { lib; config; options; }`. Normalized via `normalizeModuleFn` (extracted helper that calls `aspectType.merge` to extract class keys — the only handler-layer reference to the type system).
   - **Parametric aspect** (`{ host, ... }: { nixos = ...; }`): Wrapped in an aspect envelope with `__functor`, `__functionArgs`, and empty `includes`.

This normalization is distinct from `fxResolveTree`'s root normalization (see Pipeline entry points below).

### ctx-stage tag propagation

`tagChild` propagates context stage tags (`__ctxStage`, `__ctxKind`, `__ctxAspect`) from parent to children that don't have their own. This preserves the context information through the tree so trace handlers can identify which context stage an aspect belongs to.

### Anonymous node handling

Anonymous nodes (name is `<anon>`, `<function body>`, or starts with `[definition `) are transparent to the includes chain — no `chain-push`/`chain-pop`. Two cases:

- **Wrapper around a named child** (e.g., `deepRecurse` scaffolding): The named child pushes its own identity when compiled. The wrapper is invisible in the chain.
- **Bare lambda leaf** (e.g., `{ host, ... }: { nixos = ...; }`): At `resolve-complete`, the handler reads `lib.last state.includesChain` as parent — the nearest meaningful ancestor. The trace handler disambiguates the name using ctx stage tags.

In both cases, the anonymous node doesn't corrupt the chain.

### Root `resolve-complete`

The root aspect has no parent sending `emit-include`, so no handler emits `resolve-complete` for it. Instead, `compileStatic` emits `resolve-complete` at the end of every aspect's compilation (including the root). This means `resolve-complete` is emitted by the compiler rather than the handler — a deviation from the "all strategy in handlers" principle, but it works correctly and covers both root and child cases uniformly.

### Identity preservation

`aspectToEffect` preserves `name` and `meta` from the input aspect. The computation carries the aspect's identity throughout — handlers can inspect it for constraint checking, tracing, etc.

## Effect protocol

```
Context:
  into-transition { key, transitionFn, ctx, self }   — handler walks transitions with scope.stateful
  ctx-seen <key>                                      — dedup handler for context stages

Aspect:
  emit-class { class, module, identity }              — handler accumulates modules
  emit-include { from, include }                      — handler checks constraints + recurses
  register-constraint { type, scope, identity, ... }  — handler stores in registry
  check-constraint { identity, aspect }               — handler queries registry

Tree:
  chain-push { identity }                             — handler tracks includes chain
  chain-pop                                           — handler pops includes chain
  resolve-complete <resolved-aspect>                  — handler emits trace entries
  get-path-set                                        — handler returns accumulated paths

Parametric:
  <arg-name>                                          — constantHandler resumes with value
```

## Handlers

### `emit-include` handler (include.nix) — owns recursion

The central handler. Intercepts `emit-include` effects and returns an effectful resume:

1. Wraps the child via `wrapChild` (normalizes bare lambdas into aspect envelopes)
2. Checks if the child is conditional (`meta.conditional`)
3. For conditional children: evaluates the guard against the accumulated path set
4. For regular children: sends `check-constraint` to query the constraint registry
5. Based on the constraint decision:
   - **keep**: recursively calls `aspectToEffect child`, emits `resolve-complete`
   - **exclude**: creates a tombstone, emits `resolve-complete`
   - **substitute**: creates a tombstone, recursively resolves the replacement

This is the only place recursion happens. The handler closes over `aspectToEffect` for recursive compilation.

### `constantHandler` (ctx.nix) — parametric value provider

Replaces the former `parametricHandler`, `staticHandler`, and `contextHandlers`. For each key-value pair, resumes with the value when that key appears as an effect name. Provides `class`, `host`, `user`, and any other context values to parametric aspects.

Includes `aspect-chain = []` as a compatibility shim for type-system-baked provider functions (see Compatibility Shims below).

### `ctxSeenHandler` (ctx.nix) — context dedup

Tracks which context stages have been seen. Returns `{ isFirst }` so the transition handler can skip duplicate processing.

### `constraintRegistryHandler` (tree.nix) — constraint storage and lookup

Handles `register-constraint` and `check-constraint`:

- **register-constraint**: Accumulates constraints as a list per identity, stamping `ownerChain` from the current `state.includesChain` for scoped constraints. Multiple constraints for the same identity are preserved (not overwritten).
- **check-constraint**: Finds the first in-scope constraint for the identity (first-registered wins), then falls back to filter predicates. Returns `{ action = "keep"|"exclude"|"substitute"; ... }`. Scoped constraints only apply when the owner's chain is a prefix of the current chain.

### `chainHandler` (tree.nix) — includes-path tracking

Handles `chain-push` and `chain-pop`. Maintains `state.includesChain` — the stack of meaningful ancestor identities. Anonymous nodes are transparent (no push/pop). Trace handlers derive `parent` from `lib.last state.includesChain` instead of an explicit `__parent` field. `chain-pop` on an empty chain throws a descriptive error to surface push/pop mismatches immediately.

### `classCollectorHandler` (tree.nix) — module accumulation

Handles `emit-class`. Accumulates modules by class, deduplicates by identity.

### `transitionHandler` (transition.nix) — context transitions

Handles `into-transition`. For each transition key:

1. Looks up the target context aspect from `den.ctx` by path. If the path doesn't exist, emits a diagnostic tombstone with `transitionMissing = true` (rather than silently skipping).
2. Sends `ctx-seen` for dedup (using `/` separator matching `pathKey` convention).
3. For each new context value, installs scoped handlers via `scope.stateful` with `constantHandler (parentCtx // newCtx)` — explicitly merging parent context so the scoped handler is self-contained rather than relying on `scope.stateful` fallthrough for parent keys.

Uses `scope.stateful` (not `scope.run`) to preserve handler state across scoped computations.

### Trace handlers (trace.nix) — observation

`structuredTraceHandler` and `tracingHandler` consume `resolve-complete` effects. They read parent from `state.includesChain` (not from the param). Trace entries carry a `handlers` field (the actual handler data from `meta.handleWith`) instead of a boolean `hasAdapter`.

### `collectPathsHandler` (identity.nix) — path accumulation

Handles `resolve-complete`. Accumulates aspect paths into both `state.paths` (list) and `state.pathSet` (attrset) incrementally, skipping excluded aspects (tombstones).

### `pathSetHandler` (identity.nix) — path set query

Handles `get-path-set`. Returns `state.pathSet` directly (O(1)), used by `includeIf` guards to evaluate `hasAspect` queries.

### Conditional inclusion via `includeIf`

`includeIf guardFn aspects` creates a conditional node: `{ name = "<includeIf>"; meta = { guard = guardFn; aspects = aspects; }; }`.

The `emit-include` handler detects conditional nodes by checking `child.meta ? guard` and evaluates the guard against the accumulated path set. If the guard passes, each guarded aspect is emitted via `emit-include` (hitting the handler for constraint checking and recursion). If the guard fails, each guarded aspect gets a tombstone with `guardFailed = true`.

The guard function receives `{ hasAspect = ref: ...; }` where `hasAspect` checks the handler's accumulated `pathSet` state. Because resolution is sequential (left-to-right through includes), guards can only see aspects resolved before them in the tree. Reordering includes may change which guards pass.

## Constraints

### `meta.handleWith`

The extension point where aspect authors provide handlers governing resolution of their subtree. Accepts a single record, a list of records, or null.

```nix
meta.handleWith = exclude foo;
meta.handleWith = [ (exclude foo) (substitute bar baz) (filterBy pred) ];
```

### `meta.excludes` (sugar)

Convenience field that expands into `meta.handleWith`:

```nix
meta.excludes = [ foo bar ];
# Equivalent to: meta.handleWith = [ (exclude foo) (exclude bar) ];
```

When both are set, `excludes` appends (takes final say).

### Constraint constructors

All live in `constraints.nix`. Each has a default (subtree-scoped) and `.global` variant. `exclude` and `substitute` validate that `ref` is an attrset, throwing a descriptive error on misuse:

| Constructor | Effect |
|---|---|
| `exclude ref` | Exclude `ref` from this subtree |
| `exclude.global ref` | Exclude `ref` everywhere in the pipeline |
| `substitute ref replacement` | Replace `ref` with `replacement` in this subtree |
| `substitute.global ref replacement` | Replace `ref` globally |
| `filterBy pred` | Exclude children failing `pred` in this subtree |
| `filterBy.global pred` | Filter globally |

Scoped constraints use includes-chain ancestry (`isAncestor ownerChain currentChain`) to determine applicability. Root-registered scoped constraints are effectively global since the empty prefix matches everything.

### `meta.adapter` (legacy)

Reverted to accept only legacy function adapters (the GOF adapter pattern used by `resolve.withAdapter`). The fx pipeline reads `meta.handleWith`, not `meta.adapter`. Both fields are carried through `wrapIdentity`/`withIdentity` until legacy removal.

## Includes chain provenance

The includes chain replaces `__parent` string tracking. It's an observable effect protocol:

- **`chain-push { identity }`** — emitted when entering a meaningful node's subtree
- **`chain-pop`** — emitted when leaving

Anonymous nodes (wrappers from `deepRecurse`, bare lambdas) are transparent — no push/pop. Their children see the parent's chain. This gives correct parent attribution without the information loss of the old single-`__parent` approach.

### Diagram observability

Chain effects are observable by any handler:
- Sequence diagrams: `chain-push`/`chain-pop` map to activation bars
- Scope visualization: adapter registration alongside current chain shows scope boundaries
- Composable analysis: depth tracking, per-subtree counts, cycle detection — all addable as handlers

## Context transitions

Contexts are aspects. They have `name`, `meta`, `includes`, `provides` — like any aspect — plus an `into` attrset defining context transitions.

`aspectToEffect` handles contexts the same way, with two additions:
- `.into` keys are excluded from class emission (they're transitions, not configs)
- An `into-transition` effect is emitted per transition key

The `transitionHandler` processes each transition:

1. Applies the transition function: `{ host } -> [{ host, user: alice }, { host, user: bob }]`
2. For each new context value, installs scoped handlers via `scope.stateful` containing a `constantHandler` with the new values
3. Runs `aspectToEffect targetCtx` inside the scope

Each context value is local to its scope. `den.ctx.user` running inside a `user = alice` scope sees `alice` via the scoped `constantHandler`.

Self-provide auto-include: if `aspect.provides.${aspect.name}` exists, it's automatically included — the aspect provides its own sub-aspects.

## Pipeline flow

```
aspectToEffect(rootAspect)
  -> emit-class for each class key
  -> register-constraint for meta.handleWith
  -> chain-push (if meaningful)
  -> emit-include for each child
    -> handler checks constraint
    -> handler recurses: aspectToEffect(child)
      -> (child may have into transitions)
      -> into-transition handler installs scoped handlers
      -> aspectToEffect(targetCtx) runs in scope
  -> chain-pop (if pushed)
  -> resolve-complete

fx.handle { handlers = defaultHandlers; state = defaultState; } computation
  -> { value = resolvedTree; state = { entries, paths, imports, ... }; }
```

`mkPipeline` composes the handler set and runs `fx.handle` once at the pipeline edge. `fxResolve` and `fxResolveTree` are the public entry points.

## Pipeline entry points and A/B gating

### `den.fxPipeline` option

Defined in `modules/fxPipeline.nix`. A boolean option (default `true`) that switches the resolution path:

```nix
resolve = if fxEnabled then fxResolveTree else legacyResolve;
```

This gate lives in `nix/lib/aspects/default.nix`. When `false`, the entire fx pipeline is bypassed and the legacy recursive `resolve` function handles resolution. Legacy adapter tests (`resolve.withAdapter`) run with `fxPipeline = false`.

### `fxResolveTree` — root entry point

`fxResolveTree` (in `nix/lib/aspects/default.nix`) normalizes the root aspect before entering the pipeline. This is separate from `wrapChild` (which normalizes children inside the pipeline).

Root normalization handles aspects arriving from `forward.nix`'s `fromAspect`, which may be raw lambdas or `fixedTo`-wrapped functor attrsets:

1. **Raw lambda** (`isFunction=true, isAttrs=false`): Wrapped in an aspect envelope with `__functor`, `__functionArgs`, `name`, `meta`, `includes`.
2. **Functor attrset with named args** (`isAttrs=true, __functor` present, `functionArgs != {}`): Same treatment — extract inner function, wrap with correct `__functionArgs`.
3. **Functor attrset with no args** (default functor, `functionArgs == {}`): Pass through to `compileStatic` to preserve class keys.
4. **Plain attrset**: Pass through unchanged.

After normalization, `fxResolveTree` calls `fx.pipeline.fxResolve { class; self = wrapped; ctx = {}; }`.

Note: `ctx` is always `{}` at root — context values are provided by handlers during resolution, not passed in from the entry point.

### `fxResolve` and `mkPipeline`

`fxResolve` delegates to `mkPipeline`, which:
1. Composes `defaultHandlers` (with root-level `aspect-chain = [self]` override) with any `extraHandlers`
2. Compiles the root aspect via `aspectToEffect self`
3. Runs `fx.handle` with the composed handlers and `defaultState`
4. Returns `{ imports = result.state.imports; }` — the accumulated NixOS/HM modules

## nix-effects dependency

The fx pipeline depends on a nix-effects fork with effectful handler support (`sini/nix-effects#feat/effectful-handlers`). Two key extensions:

### Effectful handlers (resume with computations)

Standard nix-effects handlers return `{ resume = value; state; }` where `resume` is a plain value. The fork allows `resume` to be a computation. The trampoline interpreter (`interpret` and `rotateInterpret`) detects computations by checking `resume ? _tag && (resume._tag == "Pure" || resume._tag == "Impure")`:

- **Plain value resume**: existing behavior — value feeds directly to the continuation
- **`Pure` computation resume**: unwraps the value and feeds it to the continuation
- **`Impure` computation resume**: appends the original continuation queue to the computation's queue (queue splicing). The computation's effects run first under the same handler set, then the original continuation resumes with the result.

State threading: when a handler returns an effectful resume, the sub-computation runs with the handler's updated state. Effects in the sub-computation that modify state propagate through to the original continuation. This is correct — the sub-computation is part of the same handling scope.

Backward compatible — plain value resumes are unchanged.

### `scope.stateful`

Preserves handler state across scoped computations. Critical for the transition handler: without it, inner computations would run with `state = null`, losing accumulated constraint registries, path sets, and trace entries. Uses `state.get`/`state.put` internally.

### Loading

- Accessed as `den.lib.fx` (set once, available to all fx modules)
- Loaded from flake input when available, falls back to locked `fetchTarball`

## What was removed

The following modules and functions from the pre-fx architecture no longer exist in the fx pipeline:

| Removed | Replaced by |
|---|---|
| `go` / `resolveChild` / `resolveChildren` (explicit recursion) | `aspectToEffect` + `emit-include` handler |
| `resolveOne` / `resolveOneStrict` (per-aspect `fx.handle`) | `aspectToEffect` (no internal handle boundary) |
| `wrapAspect` / `wrapIdentity` / `emitClassConfig` | `aspectToEffect` (single compiler) |
| `ctx-apply.nix` / `ctx-stage.nix` | Context transitions through `aspectToEffect` + `into-transition` handler |
| `resolve-deep.nix` | Handler-driven recursion via `emit-include` |
| `resolve-handler.nix` (`resolveIncludeHandler`) | `handlers/include.nix` (effectful handler) |
| `resolve-one.nix` | `aspect.nix` (`aspectToEffect`) |
| `resolve-legacy.nix` | Removed |
| `parametricHandler` / `staticHandler` / `contextHandlers` | `constantHandler` |
| `ctxProviderHandler` / `ctxTraverseHandler` / `ctxTraceHandler` / `ctxEmitHandler` | Removed (dead after unified pipeline) |
| `fx/adapters.nix` (monolithic) | Split into `identity.nix`, `constraints.nix`, `includes.nix`, `trace.nix` |
| `init` function / explicit arg threading | `{ lib, den }` module pattern, lazy barrel |
| `__parent` string field | `chain-push`/`chain-pop` effect protocol |
| `meta.adapter` for fx records | `meta.handleWith` (fx) / `meta.adapter` reverted to legacy functions only |
| `adapterRegistryHandler` / `register-adapter` / `check-exclusion` | `constraintRegistryHandler` / `register-constraint` / `check-constraint` |
| `hasAdapter` boolean in trace entries | `handlers` field (carries actual handler data) |

## Compatibility shims

These exist because the type system operates at declaration time and cannot be gated on `config.den.fxPipeline` without circular evaluation:

### `aspect-chain` in `constantHandler`

`defaultFunctor` (from `parametric.withOwn`) is baked into every aspect at type-declaration time. Provider functions from `providerFnType.merge` create `{ class, aspect-chain }` functors. When `aspectToEffect` encounters these via `bind.fn`, it sends `aspect-chain` as an effect. `constantHandler` provides `aspect-chain = []`.

At root level, `aspect-chain = [self]` is overridden because downstream consumers of the legacy resolve pipeline (`resolve.nix`, `home-env.nix`) and type-system-baked provider functions (`parametric.nix`) expect `aspect-chain` to contain the resolution chain. Note: the comment in `pipeline.nix:89` attributing this to `forward.nix` is stale — `forward.nix` does not reference `aspect-chain`.

### `options.nix` uses legacy `ctxApply`

`config.resolved` in `options.nix` can't access `config.den` without circularity, so it always goes through the legacy `ctxApply` path. The fx pipeline receives pre-wrapped (parametric) aspects.

### Legacy adapter tests on `fxPipeline = false`

Tests that explicitly call `resolve.withAdapter` (the legacy adapter API) run with `fxPipeline = false`. The fx pipeline uses constraints instead of the `{ aspect, recurse, ... }` adapter protocol. These tests verify legacy behavior and don't need fx equivalents.

## Known architectural constraints

### Circular evaluation prevents gating on `den.fxPipeline`

`defaultFunctor` feeds into `typesConf` -> `types` -> aspect option declarations. Accessing `den.fxPipeline` (a config value) during type declaration creates circular evaluation: `config.den` -> aspects -> types -> `defaultFunctor` -> `config.den`. This was verified — it produces `attribute 'den' missing` errors.

The same applies to `options.nix`: `config.resolved` is an option default and can't access `config.den` without circularity.

**Implication:** The type system always bakes `defaultFunctor` (`parametric.withOwn`) into every aspect. Provider functions from `providerFnType.merge` always create `{ class, aspect-chain }` functors. The fx pipeline must handle this via the `constantHandler` shim.

### Template circular eval with barrel imports

`fx/default.nix` barrel imports effectful modules (`pipeline.nix`, `handlers/include.nix`, etc.) that access `den.lib.aspects.fx.*` siblings in their `let` blocks. When anything forces `den.lib.aspects.fx` during module system initialization (e.g., `meta.handleWith = den.lib.aspects.fx.exclude ...`), it can trigger circular eval through `config.den`.

The old `init` pattern avoided this because effectful modules were only loaded when `init(nxFx)` was explicitly called at runtime. The barrel loads them at import time. Pure constructors (`exclude`, `substitute`, `filterBy`) don't trigger this because they don't reference effectful siblings.

### `resolve-complete` placement deviation

`resolve-complete` is emitted inside `compileStatic` (the aspect compiler) for every aspect, including the root. This means the compiler knows about a resolution lifecycle event rather than leaving it entirely to handlers. It works correctly and covers the root case (which has no parent handler) uniformly, but deviates from the "all strategy in handlers" principle. Lower priority — can address when the type system is reworked.

## Followup work

### forward.nix redesign

The `aspect-chain` compatibility shim is consumed by type-system-baked provider functions (`parametric.nix`, `home-env.nix`) and the legacy resolve pipeline (`resolve.nix`). The root override (`aspect-chain = [self]`) exists to satisfy these consumers. The target: expose `root` from the fx pipeline result so consumers can read it directly, then remove the `aspect-chain` root override.

### Type system rework

When the legacy pipeline is removed:
1. Remove `defaultFunctor` / `parametric.withOwn` from the type system
2. Remove `providerFnType.merge`'s `__functor` wrapping
3. Aspects become plain attrsets — no functor needed
4. Remove `aspect-chain` handler from pipeline
5. Remove `aspect-chain` consumption from `home-env.nix`, `parametric.nix`, `resolve.nix`
6. `options.nix` can use `aspectToEffect` directly (no `ctxApply`)

## Integration points

| File | Role |
|---|---|
| `nix/lib/aspects/default.nix` | `fxResolveTree`, `defaultFunctor`, resolution gate |
| `modules/options.nix` | `config.resolved` (legacy ctxApply, circular eval constraint) |
| `nix/lib/parametric.nix` | `defaultFunctor` source (type-system-baked) |
| `nix/lib/statics.nix` | `isCtxStatic`, `{ class, aspect-chain }` functors |
| `nix/lib/forward.nix` | builds NixOS/HM modules from resolved aspect trees |
| `nix/lib/home-env.nix` | consumes `{ class, aspect-chain }` in provider functions |

## Verification

```bash
nix develop -c just ci ""
```

All tests pass. The `fxPipeline` flag defaults to `true`. Legacy tests using `resolve.withAdapter` run with `fxPipeline = false`.
