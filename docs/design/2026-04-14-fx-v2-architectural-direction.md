# FX Pipeline v2: Architectural Direction

**Date:** 2026-04-14
**Source:** Vic's code review on sini/den#2
**Status:** Planning

## Current State (v1 prototype)

The v1 fx pipeline works (463 tests, diagram generation, fxPipeline flag) but
uses effects as a layer ON TOP of the existing patterns:
- `resolveOne` has an internal `fx.handle` boundary per aspect
- `resolveDeepEffectful` does explicit tree walking (go/resolveChild/processApproved)
- `ctxApplyEffectful` produces a plain list, then resolution walks it
- Dedup is split between `ctxSeenHandler` and `assembleIncludes`

## v2 Target: Aspects Are Computations

### Core idea

Every aspect IS an effectful computation. An aspect's includes are not a list
to be walked -- they're a chain of computations bound together via `fx.bind`.
The tree structure emerges from effect composition, not explicit recursion.

### Key changes

1. **`fx.handle` only at edges.** No internal `fx.handle` in `resolveOne`.
   Resolution stays in the effectful world until the top-level `fxResolve`.
   `resolveOne` returns a `Computation aspect`, not a resolved attrset.

2. **`wrapAspect` produces recursive computations.** Instead of translating
   one aspect, it produces a computation that sends `provide-class` for each
   class key, then binds each include as a child computation. No manual `go`.

3. **`provide-class` effect.** Each aspect's class config (nixos, homeManager)
   is emitted as `fx.send "provide-class" { class; module; aspectIdentity; }`.
   A stateful handler accumulates modules and deduplicates by aspectPath.

4. **Exclude/replace as query effects.** Instead of pattern-matching on
   `resolve-include`, aspects send `fx.send "check-exclusion" identity` and
   the handler responds with keep/tombstone. The handler maintains a registry
   populated from `meta.adapter` declarations.

5. **Presence queries as effects.** `hasAspect` becomes `fx.send "is-present"
   ref` -- the handler checks its accumulated path set. No pre-scan needed.

6. **Remove flattenInto dedup from ctx-apply.** Dedup is entirely handler
   state (`ctxSeenHandler`). `assembleIncludes`'s seen-tracking goes away.

7. **Includes as computation chains in ctx-apply.** `buildStageIncludes`
   returns a computation chain (not a list). Main aspect, self-provider,
   cross-provider are bound together as sequential effect sends.

### nix-effects loading

Before merge, load nix-effects via `fetchTarball` fallback so users don't
need it as a flake input:
```nix
fx = inputs.nix-effects.lib or (import (fetchTarball fallback-url) { inherit lib; })
```

### Migration path

v1 stays for A/B testing (`fxPipeline` flag). v2 is built alongside,
eventually replacing v1. When v2 proves parity, the legacy pipeline and
v1 prototype are removed, and `fxPipeline` flag goes away.
