# FX Pipeline v2 Refactor Design

**Date:** 2026-04-13
**Branch:** `feat/fx-resolution`
**Source:** Vic's review (sini/den#2), validated with sini

## Context

v1 fx pipeline works (459 tests, A/B via `fxPipeline` flag) but uses effects as a layer on top of existing patterns. v2 makes aspects true computations — the tree emerges from `fx.bind` composition, not explicit recursion.

## Decisions

- **In-place refactoring** of v1 code (not parallel v2 functions). The `fxPipeline` flag already provides A/B against the legacy pipeline.
- **Lazy adapter registration** — parametric aspects can't be pre-scanned, so adapters register via effects during resolution. Exclusion checks default to "keep" for unregistered identities.

## Step 1: `resolveOne` returns Computation

Remove internal `fx.handle` at resolve.nix:73-76. `resolveOne` returns `Computation aspect` — the caller handles effects. `wrapAspect` already produces computations; the change is not handling them internally.

Impact: `resolveDeepEffectful` must accept computations instead of resolved attrsets.

## Step 2: Replace go-recursion with bind chains

Replace explicit `go`/`resolveChild`/`processApproved` loop (resolve.nix:156-313) with `fx.bind` composition. Each aspect's includes become child computations bound to the parent.

`resolve-include` and `resolve-complete` effects still fire at the same points, emitted by the computation chain rather than the loop.

Impact: Biggest structural change. Recursive loop becomes flat chain of bind calls.

## Step 3: `provide-class` effect + handler

Each aspect emits `fx.send "provide-class" { class; module; identity; }`. Stateful `provideClassHandler` accumulates modules and deduplicates by `aspectPath`.

Replaces `moduleHandler`'s current approach of checking `param[class]` on `resolve-complete`. `wrapAspect` gains responsibility for emitting `provide-class` for each class key.

## Step 4: Exclude/replace as stateful query effects

Two new effects:
- `fx.send "register-adapter" { type = "exclude"|"substitute"; identity; replacement?; }` — emitted when adapter aspects are encountered
- `fx.send "check-exclusion" identity` — handler responds with keep/tombstone based on current registry

For presence queries:
- `fx.send "is-present" ref` — checks accumulated path set in handler state, replacing `collectRawPaths` pre-scan for `includeIf` guards

Default-to-keep for unregistered identities. `excludeAspect`/`substituteAspect` handler overrides and `fx.rotate` scoping go away. Adapters become effect-emitting computations.

## Step 5: Remove flattenInto dedup from ctx-apply

Dedup tracking moves entirely to `ctxSeenHandler` state. Duplicated seen-tracking in `assembleIncludes` is removed. `flattenInto` keeps flattening role, loses dedup logic. `ctxSeenHandler` is single authority.

## Step 6: `buildStageIncludes` returns computation chain

Replace list `[mainAspect, selfProvResult?, crossProvResult?]` with `fx.bind` chain. `__ctxStage`/`__ctxKind`/`__ctxAspect` tagging moves into effects emitted by each computation rather than post-hoc list annotation.

`ctxApplyEffectful` consumes a computation instead of iterating a list.

## Implementation order

1 → 2 → 3 → 4 → 5 → 6 (sequential, each step tested against existing 459 tests + fxPipeline A/B)

## Key files

```
nix/lib/aspects/fx/
  resolve.nix    — steps 1, 2
  aspect.nix     — steps 2, 3
  handlers.nix   — steps 3, 4, 5
  adapters.nix   — step 4
  ctx-apply.nix  — steps 5, 6
  default.nix    — export updates
```
