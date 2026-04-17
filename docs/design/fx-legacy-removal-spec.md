# Remove Legacy Resolve Pipeline — Spec

**Branch:** `feat/forward-root` (worktree at `den-forward-redesign`, based on `origin/main`)
**Goal:** Delete the legacy resolve pipeline. Single resolution path via fx effects pipeline.

## Files to delete

| File | Lines | Reason |
|------|-------|--------|
| `nix/lib/statics.nix` | 32 | Only used by `parametric.nix` legacy paths |
| `nix/lib/aspects/resolve.nix` | 108 | Legacy tree walker, replaced by `fxResolve` |
| `nix/lib/aspects/adapters.nix` | 350 | GOF adapters for `resolve.withAdapter`, replaced by `meta.handleWith` + constraint handlers |

## Files to modify

### `nix/lib/aspects/types.nix`

Remove `defaultFunctor` and `__functor` wrapping from the aspect type system.

- **Delete** the `__functor` option from `aspectSubmodule` (line ~208-215). Aspects become plain attrsets.
- **Simplify** `providerFnType.merge`: remove the `__functor = _: eth.merge loc defs` wrapper. Merge directly: `merge = loc: defs: eth.merge loc defs;`
- **Remove** `cnf.defaultFunctor` parameter threading. `types` functions no longer take a `cnf` with `defaultFunctor`.

### `nix/lib/aspects/default.nix`

Remove the `fxEnabled` gate, `legacyResolve`, and `defaultFunctor`.

- **Delete** `legacyResolve` import
- **Delete** `fxEnabled` and the `if/else` gate
- **Delete** `defaultFunctor` and `typesConf`
- `resolve` becomes `fxResolveTree` directly (no gate)
- `types` built without `defaultFunctor`: `lib.mapAttrs (_: v: v {}) rawTypes`

### `nix/lib/parametric.nix`

Remove legacy machinery. Keep only what the fx pipeline uses.

**Delete:**
- `withOwn` (line ~155-171) — was `defaultFunctor`
- `deepRecurse` (line ~123-136) — built `{ class, aspect-chain }` functors
- `parametric.deep`, `parametric.deepParametrics` (line ~147-148) — used `deepRecurse`
- `applyDeep` (line ~41-94) — only used by legacy resolve
- `applyIncludes` (line ~96-105) — only used by legacy resolve
- References to `statics`, `owned`, `isCtxStatic` (line ~4)

**Keep:**
- `fixedTo` and variants (`fixedTo.exactly`, `fixedTo.atLeast`, `fixedTo.upTo`) — used by `ctxApply` to bind context values
- `atLeast`, `exactly`, `expands` — used throughout codebase
- `withIdentity` — used by `ctxApply` and fx pipeline
- `take`, `canTake` utilities

**Rewrite** `fixedTo` — currently `fixedTo.__functor = _: attrs: parametric.deep (...)` which calls `deep` → `deepRecurse`. With `deepRecurse` deleted, `fixedTo` must be reimplemented. It needs to bind context values to an aspect without the `{ class, aspect-chain }` functor chain. The simplest approach: `fixedTo` returns the aspect with context values merged, leaving the fx pipeline's `constantHandler` to provide `class` during resolution. The recursive include application that `deepRecurse` handled is already done by `aspectToEffect` + `emit-include` handler.

### `nix/lib/ctx-apply.nix`

Simplify — the fx pipeline's `transitionHandler` handles `into` traversal, but `ctxApply` is still the bridge between `den.ctx.*` and the pipeline.

**Keep** the `traverse` + `buildIncludes` logic (it produces the root includes list that `fxResolveTree` resolves). But:
- `buildIncludes` currently wraps with `parametric.fixedTo` (first visit) or `parametric.atLeast` (re-visit). With `fixedTo` rewritten (no `deepRecurse`), the wrapping becomes a simple context-value merge on the aspect attrset. The `isFirst` distinction may still matter for dedup.
- Remove `__ctxTrace` (tracing handled by fx trace handlers)
- The output shape stays the same: `{ includes = [...] }` wrapped with `withIdentity`. `fxResolveTree` receives this and resolves it.

### `nix/lib/ctx-types.nix`

- Line 48: `config.__functor = lib.mkForce ctxApply` — keep. This is how `den.ctx.host { ... }` works. `ctxApply` is the bridge, not the resolver.

### `modules/options.nix`

- Line 39: `den.ctx.${kind} (...)` — keep. This calls `ctxApply` which produces the includes list. The fx pipeline resolves it lazily via `config.resolved`.
- The circular eval issue goes away if `defaultFunctor` is removed — type declarations no longer reference `config.den`.

### `nix/lib/forward.nix`

- Line 23: `sourceModule = mapModule (den.lib.aspects.resolve fromClass asp)` — this already calls `fxResolveTree` when fx is enabled (which is always after this change). No change needed.
- Line 22: `asp = if fwd ? fromAspect then fwd.fromAspect item else item.resolved or item` — `fromAspect` pattern changes (see providers below).

### `nix/lib/home-env.nix`

- Line 62: `{ class, aspect-chain }:` → `{ class, ... }:` (remove `aspect-chain` from destructuring, it's unused in the body)

### `nix/lib/default.nix`

- Remove `statics = ./statics.nix;` line

### Provider modules (remove `aspect-chain`)

**`modules/aspects/provides/os-class.nix`:**
```
{ class, aspect-chain }:        →  { class, ... }:
fromAspect = _: lib.head aspect-chain;  →  (remove fromAspect entirely — forward.nix uses item.resolved)
```

**`modules/aspects/provides/wsl.nix`:**
```
{ class, aspect-chain }:        →  { class, ... }:
fromAspect = _: lib.head aspect-chain;  →  (remove fromAspect)
```

**`modules/outputs/flakeSystemOutputs.nix`:**
```
{ class, aspect-chain }:        →  { class, ... }:
fromAspect = _: lib.head aspect-chain;  →  (remove fromAspect)
```

**`modules/aspects/provides/import-tree.nix`:**
```
{ class, aspect-chain }:        →  { class, ... }:
den.lib.take.unused aspect-chain ...  →  (compute path without aspect-chain)
```

**`modules/aspects/provides/unfree/unfree.nix`:**
```
{ class, aspect-chain }:        →  { class, ... }:
(aspect-chain already unused in body)
```

### FX pipeline cleanup

**`nix/lib/aspects/fx/pipeline.nix`:**
- Remove `"aspect-chain" = []` from `defaultHandlers` `constantHandler`
- Remove `"aspect-chain" = [self]` override in `mkPipeline`
- Delete `modules/fxPipeline.nix` (the option no longer exists)

**`nix/lib/aspects/fx/handlers/include.nix` (`wrapChild`):**
- The functor-attrset case (`isAttrs child && child ? __functor`) stays — it still handles `withIdentity`-produced functors from `ctxApply` and user-defined `__functor` aspects
- Update comments to document remaining functor sources (no longer `deepRecurse`/`defaultFunctor`)
- `normalizeModuleFn` calls `den.lib.aspects.types.aspectType.merge` — verify this is unaffected by `types.nix` changes

**`nix/lib/aspects/fx/handlers/include.nix` / `nix/lib/aspects/fx/pipeline.nix` / `nix/lib/aspects/fx/aspect.nix`:**
- Remove `meta.adapter` propagation — no legacy consumers remain. The fx pipeline only uses `meta.handleWith`.

**`nix/lib/aspects/default.nix` (`fxResolveTree`):**
- Review root normalization — comments reference `deepRecurse` and `{ class, aspect-chain }`. Update for post-removal shapes.
- Verify `fxResolveTree` handles `withIdentity`-wrapped ctxApply output (the shape `forward.nix` sends after `fromAspect` removal)

### `nix/lib/aspects/has-aspect.nix`

**Must rewrite before deleting `adapters.nix` and `resolve.nix`.** Currently calls `resolve.withAdapter adapters.collectPaths`. Replace with a query against the fx pipeline's `state.pathSet`:

```nix
# hasAspect becomes: resolve the entity's aspect tree via fx, check pathSet
hasAspect = class: tree: ref:
  let
    result = den.lib.aspects.resolve class tree;
    pathSet = result.state.pathSet or {};
    key = den.lib.aspects.fx.identity.pathKey (den.lib.aspects.fx.identity.aspectPath ref);
  in
  pathSet ? ${key};
```

This is the highest-risk item — `entity.hasAspect` is user-facing API.

### Test updates

**Delete entirely** (legacy-only tests):
- `templates/ci/modules/features/adapter-owner.nix`
- `templates/ci/modules/features/adapter-propagation.nix`
- `templates/ci/modules/features/aspect-adapter.nix`
- `templates/ci/modules/features/collect-paths.nix`
- `templates/ci/modules/features/resolve-adapters.nix`
- `templates/ci/modules/features/one-of-aspects.nix`

**Rewrite** (use fx equivalents):
- `templates/ci/modules/features/has-aspect.nix` — use rewritten `hasAspect`
- `templates/ci/modules/features/has-aspect-lib.nix` — same
- `templates/ci/modules/features/identity-preservation.nix` — if using `meta.adapter`
- `templates/ci/modules/features/provider-provenance.nix` — if using legacy adapters

**Remove `fxPipeline = false`** from all tests that set it (they must work on fx-only now)

**Update** `checkmate/modules/aspect-functor.nix`:
- Remove `aspect-chain` from identity fixture
- Remove `__functor` test cases if aspects no longer have functors

## What the `fromAspect` problem becomes

With `defaultFunctor` removed, aspects are plain attrsets. Provider functions like `os-class` are still functions (`{ class, ... }: ...`) but they're not wrapped in a functor by the type system.

The `fromAspect = _: lib.head aspect-chain` pattern was needed because `forward.nix` needs the root aspect to resolve. With the legacy pipeline gone:

- `item.resolved` (from `options.nix`) contains the ctxApply output — the includes list
- `forward.nix:22` already falls back to `item.resolved or item`
- If `fromAspect` is removed from all providers, `forward.nix` uses `item.resolved` which is exactly what it needs

So the `fromAspect` pattern goes away entirely — it was only needed to extract the root from the legacy `aspect-chain`.

**Caveat:** `item.resolved` is a `withIdentity`-wrapped ctxApply output (`{ includes = [...] }`), not a raw aspect. `fxResolveTree` must handle this shape — it already does (the `includes` list is what `aspectToEffect` compiles).

## Missing pieces to address

### `has-aspect.nix` / `collectPathSet`

Currently depends on `adapters.collectPaths` (being deleted). Must be reimplemented using fx pipeline's `state.pathSet` from the resolve result. `entity.hasAspect ref` becomes a query against the fx resolve output's accumulated path set.

### `namespace-types.nix`

Uses `ctxApply` indirectly via `den.ctx`. Should work unchanged since `ctxApply` is being simplified, not deleted.

### Circular eval verification

The claim: removing `defaultFunctor` breaks the circular eval chain `config.den → aspects → types → defaultFunctor → config.den`. Without `defaultFunctor`, type declarations don't touch `config.den`. BUT `options.nix:39` still accesses `den.ctx.${kind}` which IS `config.den.ctx.${kind}`. This path is safe because it's inside an option default (lazy), not at declaration time. The circularity was specifically from type-declaration-time access to `config.den`, which `defaultFunctor` caused.

### `ctxApply` stays as bridge (not migrated to `aspectToEffect`)

The fx spec's followup section says "`options.nix` can use `aspectToEffect` directly (no `ctxApply`)." However, `ctxApply` does useful work: it traverses `into` transitions and assembles the root includes list with provider/cross-provider contributions. The fx pipeline's `transitionHandler` handles transitions during resolution, but `ctxApply` runs BEFORE resolution to produce the input. Migrating `options.nix` to call `aspectToEffect` directly would require either: (a) making `aspectToEffect` handle `into` traversal at the root, or (b) keeping `ctxApply` logic somewhere. We keep `ctxApply` as the bridge — it's simpler and lower risk.

### `fixedTo` output shape after rewrite

Current `fixedTo` (via `deepRecurse`) produces a functor attrset with `__functor` and `__functionArgs = { class = true; aspect-chain = true; }`. `fxResolveTree` has a specific branch for this: `isFunctor && functorArgs != {}` → wrap with correct inner args.

After rewrite, `fixedTo` should produce a simpler shape — the aspect with context values available for the fx pipeline's `constantHandler` to provide. The exact shape must be compatible with `fxResolveTree`'s normalization. Test this explicitly.

### `wrapChild` after removal

With `defaultFunctor` removed, the functor-attrset case in `wrapChild` (`isAttrs child && child ? __functor`) still handles:
- User-defined `__functor` aspects (rare but valid)
- `ctxApply` output wrapped with `withIdentity` (which adds `__functor`)

The case doesn't disappear but becomes simpler — no more `defaultFunctor`-baked `{ class, aspect-chain }` args to detect and bypass.

## Verification

```bash
nix develop -c just ci ""
nix flake check
```

All tests must pass. The `fxPipeline` option no longer exists — fx is the only path.
