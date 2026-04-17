# Remove Legacy Resolve Pipeline — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers-extended-cc:subagent-driven-development (if subagents available) or superpowers-extended-cc:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Delete the legacy resolve pipeline, leaving the fx effects pipeline as the single resolution path.

**Architecture:** Remove 3 legacy files (statics.nix, resolve.nix, adapters.nix), strip `defaultFunctor` from the type system, gut `parametric.nix` of legacy machinery, rewrite `has-aspect.nix` to use fx `pathSet`, remove `aspect-chain`/`fromAspect` from all providers, and clean up ~30 test files. Work iteratively — intermediate breakages are expected.

**Tech Stack:** Nix (flake-parts module system), nix-effects (effects library)

**Spec:** `docs/design/fx-legacy-removal-spec.md` (removal plan), `docs/design/fx-pipeline-spec.md` (fx architecture reference)

---

## File Map

### Files to delete (9)
- `nix/lib/statics.nix` — legacy static aspect wrapping
- `nix/lib/aspects/resolve.nix` — legacy tree walker
- `nix/lib/aspects/adapters.nix` — GOF adapter pattern for legacy resolve
- `modules/fxPipeline.nix` — `den.fxPipeline` option (no longer needed)
- `templates/ci/modules/features/adapter-owner.nix` — legacy adapter test
- `templates/ci/modules/features/adapter-propagation.nix` — legacy adapter test
- `templates/ci/modules/features/aspect-adapter.nix` — legacy adapter test
- `templates/ci/modules/features/collect-paths.nix` — legacy collectPaths test
- `templates/ci/modules/features/resolve-adapters.nix` — legacy resolve test
- `templates/ci/modules/features/one-of-aspects.nix` — legacy oneOfAspects test

### Files to modify (major changes)
- `nix/lib/aspects/default.nix` — remove fxEnabled gate, legacyResolve, defaultFunctor, typesConf; resolve=fxResolveTree directly; types built without defaultFunctor
- `nix/lib/aspects/types.nix` — remove `__functor` option from aspectSubmodule; simplify `providerFnType.merge`
- `nix/lib/parametric.nix` — delete withOwn, deepRecurse, deep, deepParametrics, applyDeep, applyIncludes, statics imports; rewrite fixedTo; remove parametric.__functor
- `nix/lib/ctx-apply.nix` — update buildIncludes for rewritten fixedTo
- `nix/lib/aspects/has-aspect.nix` — rewrite to use fx pipeline pathSet instead of legacy resolve.withAdapter
- `nix/lib/aspects/fx/pipeline.nix` — remove aspect-chain from constantHandler and mkPipeline root override

### Files to modify (minor changes)
- `nix/lib/default.nix:32` — remove `statics = ./statics.nix;`
- `nix/lib/home-env.nix:62` — `{ class, aspect-chain }:` → `{ class, ... }:`
- `modules/aspects/provides/os-class.nix` — remove aspect-chain, fromAspect
- `modules/aspects/provides/wsl.nix` — remove aspect-chain, fromAspect
- `modules/outputs/flakeSystemOutputs.nix` — remove aspect-chain, fromAspect
- `modules/aspects/provides/import-tree.nix` — remove aspect-chain (take.unused is identity)
- `modules/aspects/provides/unfree/unfree.nix` — remove aspect-chain from destructuring
- `checkmate/modules/aspect-functor.nix` — update identity shape expectations if needed

**IMPORTANT: `forward.nix` keeps its `fromAspect` hook.** Only providers that use `fromAspect = _: lib.head aspect-chain` have their `fromAspect` removed. `osConfigurations.nix`, `hmConfigurations.nix`, `os-user.nix`, and template files use `fromAspect` with proper context objects (e.g., `den.ctx.host { inherit host; }`) — these must stay.

### Template files with `aspect-chain` (need updating)
- `templates/flake-parts-modules/modules/perSystem-forward.nix:6,11` — `{ class, aspect-chain }:` + `fromAspect = _: lib.head aspect-chain`
- `templates/nvf-standalone/modules/nvf-integration.nix:20,26` — same pattern

### Test files with `aspect-chain` in forward patterns (need updating)
- `templates/ci/modules/features/forward.nix:15,46` — raw `{ class, aspect-chain }:` lambdas in `fromAspect`
- `templates/ci/modules/features/forward-alias-class.nix:15,84,136` — `fromAspect = _: lib.head aspect-chain`
- `templates/ci/modules/features/guarded-forward.nix:33,65,112` — same
- `templates/ci/modules/features/forward-from-custom-class.nix:14,48,85,126,175` — same
- `templates/ci/modules/features/dynamic-intopath.nix:35,94` — same

### Test files to modify (~28+)
- All files with `den.fxPipeline = false` ��� remove that line
- `templates/ci/modules/features/fx-flag.nix` — delete entirely (option no longer exists)
- `templates/ci/modules/features/has-aspect.nix` — rewrite Section F (meta.adapter tests) to use fx constraints
- `templates/ci/modules/features/has-aspect-lib.nix` — rewrite to use fx pipeline APIs
- `templates/ci/modules/features/aspect-path.nix` — rewrite to use `fx.identity.aspectPath` instead of `adapters.aspectPath`
- `templates/ci/modules/features/deadbugs/issue-369-*.nix` — marked "CRASHES with fx", investigate and fix or skip

---

## Task 0: Establish baseline

**Goal:** Confirm all tests pass on the current branch before making changes.

**Files:** None modified

**Acceptance Criteria:**
- [ ] `nix develop -c just ci ""` runs and reports test count
- [ ] Record baseline test count for comparison

**Verify:** `nix develop -c just ci ""` → all tests pass

**Steps:**

- [ ] **Step 1: Run full test suite**

```bash
nix develop -c just ci ""
```

Record the number of passing tests (expected: ~493 from main).

- [ ] **Step 2: Commit nothing — this is observation only**

---

## Task 1: Delete legacy pipeline files and remove the fxPipeline gate

**Goal:** Remove the 3 legacy pipeline files, the fxPipeline option module, and all their imports. Make `resolve = fxResolveTree` unconditionally. Delete legacy-only test files.

**Files:**
- Delete: `nix/lib/statics.nix`
- Delete: `nix/lib/aspects/resolve.nix`
- Delete: `nix/lib/aspects/adapters.nix`
- Delete: `modules/fxPipeline.nix`
- Delete: `templates/ci/modules/features/adapter-owner.nix`
- Delete: `templates/ci/modules/features/adapter-propagation.nix`
- Delete: `templates/ci/modules/features/aspect-adapter.nix`
- Delete: `templates/ci/modules/features/collect-paths.nix`
- Delete: `templates/ci/modules/features/resolve-adapters.nix`
- Delete: `templates/ci/modules/features/one-of-aspects.nix`
- Delete: `templates/ci/modules/features/fx-flag.nix`
- Modify: `nix/lib/aspects/default.nix:9-14,54,60-62,66-67,72`
- Modify: `nix/lib/default.nix:32`

**Acceptance Criteria:**
- [ ] All 4 legacy files deleted
- [ ] 7 legacy test files deleted
- [ ] `nix/lib/aspects/default.nix` no longer imports resolve.nix or adapters.nix
- [ ] `fxEnabled` gate removed, `resolve = fxResolveTree` directly
- [ ] `statics` removed from `nix/lib/default.nix`

**Verify:** `nix eval .#lib --override-input den . 2>&1 | head -5` — should not error on missing files (may still error on downstream references, that's expected)

**Steps:**

- [ ] **Step 1: Delete legacy files**

```bash
rm nix/lib/statics.nix
rm nix/lib/aspects/resolve.nix
rm nix/lib/aspects/adapters.nix
rm modules/fxPipeline.nix
```

- [ ] **Step 2: Delete legacy-only test files**

```bash
rm templates/ci/modules/features/adapter-owner.nix
rm templates/ci/modules/features/adapter-propagation.nix
rm templates/ci/modules/features/aspect-adapter.nix
rm templates/ci/modules/features/collect-paths.nix
rm templates/ci/modules/features/resolve-adapters.nix
rm templates/ci/modules/features/one-of-aspects.nix
rm templates/ci/modules/features/fx-flag.nix
```

- [ ] **Step 3: Edit `nix/lib/aspects/default.nix`**

Remove imports, fxEnabled gate, defaultFunctor, typesConf. The file becomes:

```nix
{
  lib,
  den,
  inputs,
  ...
}:
let
  rawTypes = import ./types.nix { inherit den lib; };
  hasAspect = import ./has-aspect.nix { inherit den lib; };
  fx = import ./fx { inherit den lib; };

  fxResolveTree =
    class: resolved:
    let
      isRawFn = builtins.isFunction resolved;
      isFunctor = builtins.isAttrs resolved && resolved ? __functor;
      functorArgs = if isFunctor then builtins.functionArgs (resolved.__functor resolved) else { };
      needsWrap = isRawFn || (isFunctor && functorArgs != { });
      wrapped =
        if needsWrap then
          let
            innerFn = if isFunctor then resolved.__functor resolved else resolved;
            innerArgs = if isFunctor then functorArgs else builtins.functionArgs innerFn;
          in
          {
            __functor = _: innerFn;
            __functionArgs = innerArgs;
            name = resolved.name or "<function body>";
            meta = resolved.meta or { };
            includes = resolved.includes or [ ];
          }
        else
          resolved;
    in
    fx.pipeline.fxResolve {
      inherit class;
      self = wrapped;
      ctx = { };
    };

  types = lib.mapAttrs (_: v: v {}) rawTypes;
in
{
  inherit types fx;
  resolve = fxResolveTree;
  inherit (hasAspect) hasAspectIn collectPathSet mkEntityHasAspect;
  mkAspectsType = cnf': lib.mapAttrs (_: v: v cnf') rawTypes;
}
```

Key changes:
- Line 9-10: remove `adapters` and `legacyResolve` imports
- Line 14: remove `fxEnabled = den.fxPipeline or true;`
- Lines 54: `resolve = fxResolveTree` directly (not in `inherit` block — it's a renamed binding)
- Lines 56-62: remove `defaultFunctor`, `typesConf` entirely
- Line 62: `types = lib.mapAttrs (_: v: v {}) rawTypes;` — pass empty attrset instead of `typesConf`
- Remove `adapters` from exports
- `mkAspectsType` no longer references `typesConf`
- Update fxResolveTree comments to remove references to `deepRecurse` and `defaultFunctor`

- [ ] **Step 4: Edit `nix/lib/default.nix:32`**

Remove the statics import line:
```
statics = ./statics.nix;
```

- [ ] **Step 5: Smoke test**

```bash
nix eval .#lib --override-input den . 2>&1 | head -20
```

Expect downstream breakages (has-aspect.nix references `adapters`, parametric.nix references `statics`). That's fine — next tasks fix those.

- [ ] **Step 6: Commit**

```bash
nix develop -c just fmt
git add nix/lib/aspects/default.nix nix/lib/default.nix
git commit -c core.hooksPath=/dev/null -m "chore: delete legacy pipeline files and fxPipeline gate

Remove statics.nix, resolve.nix, adapters.nix, fxPipeline.nix.
Delete 7 legacy-only test files.
resolve = fxResolveTree unconditionally, types built without defaultFunctor."
```

---

## Task 2: Strip defaultFunctor from the type system

**Goal:** Remove `__functor` option from `aspectSubmodule` in types.nix and simplify `providerFnType.merge`. Aspects become plain attrsets without type-system-baked functors.

**Files:**
- Modify: `nix/lib/aspects/types.nix:31-41,208-215`
- Modify: `checkmate/modules/aspect-functor.nix` (update identity shape expectations)

**Acceptance Criteria:**
- [ ] `aspectSubmodule` no longer has `__functor` option
- [ ] `providerFnType.merge` no longer wraps in `{ __functor = _: eth.merge ... }`
- [ ] `rawTypes` functions accept `cnf` but ignore `defaultFunctor` (it's no longer passed)
- [ ] `checkmate/modules/aspect-functor.nix` updated if it expects `__functor` in identity

**Verify:** `nix eval .#lib --override-input den . 2>&1 | head -20` — types load without defaultFunctor

**Steps:**

- [ ] **Step 1: Read types.nix fully to understand cnf threading**

Read the file to find all references to `cnf.defaultFunctor` and `cnf` parameter usage.

- [ ] **Step 1b: Verify providerFnType.merge multi-module composition**

Before simplifying `providerFnType.merge`, grep for provider attributes defined across multiple module files. The current merge routes through `aspectType.merge` which composes multiple definitions. The simplified `eth.merge loc defs` must preserve this composition for cases where the same provider is defined in multiple modules. If no multi-module provider definitions exist, the simplification is safe.

```bash
# Check for providers split across modules:
grep -r "provides\." modules/ --include="*.nix" | grep -v description | sort | uniq -d
```

- [ ] **Step 2: Remove `__functor` option from `aspectSubmodule`**

In `nix/lib/aspects/types.nix`, find the `__functor` option block (lines ~208-215) inside `aspectSubmodule` options and delete it entirely:

```nix
# DELETE this block:
__functor = lib.mkOption {
  internal = true;
  visible = false;
  description = "Functor to default provider";
  type = lastFunctionTo (providerType cnf);
  defaultText = lib.literalExpression "lib.const";
  default = cnf.defaultFunctor or lib.const;
};
```

- [ ] **Step 3: Simplify `providerFnType.merge`**

Change from wrapping in `{ __functor = _: eth.merge ... }` to direct merge:

```nix
# Before (lines ~31-41):
merge =
  loc: defs:
  (aspectType cnf).merge loc [
    {
      file = (lib.last defs).file;
      value = {
        __functor = _: eth.merge loc defs;
      };
    }
  ];

# After:
merge = loc: defs: eth.merge loc defs;
```

The `providerFnType.merge` no longer needs to route through `aspectType.merge` — it directly merges the function definitions. Provider functions are now plain functions, not functor-wrapped aspects.

- [ ] **Step 4: Clean up cnf parameter**

If `cnf` is only used for `defaultFunctor` in `types.nix`, the `cnf` parameter can be simplified. Check all uses of `cnf` in the file. If other uses exist (e.g., `providerType cnf`, `aspectType cnf`), keep `cnf` but note it no longer carries `defaultFunctor`.

- [ ] **Step 5: Update checkmate/modules/aspect-functor.nix**

Read the file and check if it expects `__functor` in the aspect identity shape (line ~72-88). After removing `__functor` from `aspectSubmodule`, aspects no longer have type-system-baked functors. Update the test's expected identity shape and remove any `__functor` assertions.

- [ ] **Step 6: Smoke test**

```bash
nix eval .#lib --override-input den . 2>&1 | head -20
```

- [ ] **Step 7: Commit**

```bash
nix develop -c just fmt
git add nix/lib/aspects/types.nix checkmate/modules/aspect-functor.nix
git commit -c core.hooksPath=/dev/null -m "chore: strip defaultFunctor from type system

Remove __functor option from aspectSubmodule.
Simplify providerFnType.merge to direct merge (no functor wrapping).
Aspects are now plain attrsets — no type-system-baked functors."
```

---

## Task 3: Gut parametric.nix of legacy machinery

**Goal:** Remove all legacy-only functions from parametric.nix. Rewrite `fixedTo` without `deepRecurse`. Keep only what the fx pipeline uses.

**Files:**
- Modify: `nix/lib/parametric.nix` (major rewrite)

**Acceptance Criteria:**
- [ ] Deleted: `withOwn`, `deepRecurse`, `deep`, `deepParametrics`, `applyDeep`, `applyIncludes`, `mapIncludes`, `includeOwnedAndStatics`, `includeNothing`
- [ ] Deleted: `statics` imports (`owned`, `statics`, `isCtxStatic`)
- [ ] Deleted: `parametric.__functor` (was `_: parametric.withOwn parametric.atLeast`)
- [ ] `fixedTo` rewritten to bind context values without `deepRecurse`
- [ ] `parametric.atLeast` and `parametric.exactly` rewritten without `applyIncludes`
- [ ] `parametric.expands` rewritten without `withOwn`
- [ ] Kept: `withIdentity`, `carryMeta`, `canTake`/`take` usage, `fixedTo` (rewritten)

**Verify:** `nix eval .#lib.parametric --override-input den . 2>&1 | head -10`

**Steps:**

- [ ] **Step 1: Understand what fixedTo must produce for the fx pipeline**

`fixedTo attrs aspect` is called from `ctx-apply.nix:92` on the first visit to a context node. It binds context values (`attrs`) to an aspect so the fx pipeline's `constantHandler` can provide them during resolution.

Current: `fixedTo attrs` → `parametric.deep (lib.flip parametric.atLeast attrs)` → `deepRecurse` → produces `{ class, aspect-chain }:` functor.

New: `fixedTo attrs aspect` should produce the aspect with a `__functor` that applies `attrs` via `take.atLeast` when called. The recursive include application that `deepRecurse` handled is now done by `aspectToEffect` + the `emit-include` handler. So `fixedTo` just needs to bind context at the top level.

```nix
# New fixedTo: bind context values to aspect, let fx pipeline handle recursion
parametric.fixedTo.__functor = _: attrs: aspect:
  aspect // {
    __functor = self: ctx:
      withIdentity self {
        includes = builtins.filter (x: x != {})
          (map (take.atLeast (attrs // ctx)) (self.includes or []));
      };
    __functionArgs = builtins.intersectAttrs attrs (builtins.functionArgs (aspect.__functor or (_: _: {})) aspect or {});
  };
```

Wait — this is more nuanced. `fixedTo` needs to make the aspect's includes resolvable with the bound context. The fx pipeline calls `aspectToEffect` which detects `__functor` → `compileFunctor` → `bind.fn` sends each arg as an effect → `constantHandler` provides values.

Simpler approach: `fixedTo attrs aspect` wraps the aspect with a functor that, when called with `ctx`, merges `attrs // ctx` and applies `take.atLeast` to each include. The fx pipeline's `bind.fn` will request the args via effects, `constantHandler` provides them.

Actually, the simplest correct approach: `fixedTo` should apply the context values eagerly to the aspect's parametric includes, producing a partially-bound aspect. The fx pipeline handles the rest (class binding, further recursion).

```nix
parametric.fixedTo.__functor = _: attrs: aspect:
  withIdentity aspect {
    includes = builtins.filter (x: x != {})
      (map (i: if canTake.atLeast attrs i then carryMeta i (take.atLeast i attrs) else i)
        (aspect.includes or []));
  };
```

This eagerly applies known context (`attrs`) to each include that can accept it. Includes that can't accept the context pass through unchanged for the fx pipeline to handle.

The named variants follow the same pattern with `take.exactly`, `take.atLeast`, `take.upTo`.

- [ ] **Step 2: Rewrite parametric.nix**

The file becomes:

```nix
{ lib, den, ... }:
let
  inherit (den.lib) take canTake;

  withIdentity =
    self: extra:
    let
      meta = self.meta or { };
    in
    {
      name = self.name or "<anon>";
      meta = {
        adapter = meta.adapter or null;
        handleWith = meta.handleWith or null;
        excludes = meta.excludes or [ ];
        provider = meta.provider or [ ];
      };
    }
    // extra;

  carryMeta =
    fn: result:
    if builtins.isAttrs result && fn ? meta && !(result ? meta) then
      result // { inherit (fn) meta; }
    else
      result;

  # Apply context values eagerly to includes that accept them.
  # The fx pipeline handles further recursion via emit-include handler.
  applyCtxToIncludes = takeFn: attrs: includes:
    builtins.filter (x: x != { }) (
      map (
        i:
        if canTake.upTo attrs i then
          carryMeta i (takeFn i attrs)
        else
          i
      ) (includes or [ ])
    );

  parametric.fixedTo.__functor = _: attrs: aspect:
    withIdentity aspect {
      includes = applyCtxToIncludes take.atLeast attrs (aspect.includes or [ ]);
    };
  parametric.fixedTo.exactly = attrs: aspect:
    withIdentity aspect {
      includes = applyCtxToIncludes take.exactly attrs (aspect.includes or [ ]);
    };
  parametric.fixedTo.atLeast = attrs: aspect:
    withIdentity aspect {
      includes = applyCtxToIncludes take.atLeast attrs (aspect.includes or [ ]);
    };
  parametric.fixedTo.upTo = attrs: aspect:
    withIdentity aspect {
      includes = applyCtxToIncludes take.upTo attrs (aspect.includes or [ ]);
    };

  parametric.atLeast = aspect: ctx:
    withIdentity aspect {
      includes = applyCtxToIncludes take.atLeast ctx (aspect.includes or [ ]);
    };

  parametric.exactly = aspect: ctx:
    withIdentity aspect {
      includes = applyCtxToIncludes take.exactly ctx (aspect.includes or [ ]);
    };

  # expands needs runtime ctx — includes may need BOTH bound attrs AND pipeline-provided
  # context (host, user, etc.). Unlike fixedTo (which is called from ctxApply where ctx
  # is already known), expands is called at aspect definition time. The fx pipeline strips
  # bare-ctx functors via compileStatic, so we use named args to trigger compileFunctor.
  #
  # IMPORTANT: Verify this works by checking parametric.nix and parametric-context.nix tests.
  # If the current tests pass with fxPipeline=true on main, the current withOwn+atLeast
  # approach works somehow — study how before rewriting. If tests only run with
  # fxPipeline=false, the fx path was never tested and we need to design from scratch.
  #
  # Safest approach: make expands produce a static attrset (like fixedTo) since the bound
  # attrs are the only extra context. The pipeline's constantHandler provides host/user/class.
  # Includes that need both bound attrs AND runtime ctx: if canTake.upTo fails (not all
  # required args provided by attrs alone), the include passes through unchanged and the
  # pipeline handles it normally — it sends effects for ALL the include's args, but
  # constantHandler doesn't know about the bound attrs. This is a gap.
  #
  # Resolution: extend constantHandler at the ctxApply level. ctxApply already calls
  # fixedTo with the ctx values. For expands, the bound attrs should be propagated to
  # the pipeline's context. Study the test expectations before choosing an approach.
  parametric.expands = attrs: aspect:
    withIdentity aspect {
      includes = applyCtxToIncludes take.atLeast attrs (aspect.includes or [ ]);
    };

  parametric.withIdentity = withIdentity;

in
parametric
```

Key decisions:
- `fixedTo attrs aspect` eagerly applies `attrs` to the aspect's includes via `take.atLeast`. No functor wrapping — produces a static attrset.
- `atLeast aspect ctx` does the same (called from ctx-apply.nix for repeat visits).
- `expands attrs aspect` — **CAUTION: semantic change.** The old code merged runtime ctx with bound attrs (`ctx // attrs`). The new code only applies bound attrs eagerly. This works if includes only need the bound attrs OR if includes that need runtime ctx have all required args provided by the pipeline's constantHandler. **Verify against test expectations.** If tests fail, `expands` may need to produce a functor with named `__functionArgs` to trigger `compileFunctor` in the fx pipeline.
- `withIdentity` and `carryMeta` kept unchanged.
- `applyCtxToIncludes` is a shared helper for all variants — uses `canTake.upTo` to check if include accepts the context (matching the old applyDeep guard), then applies with the requested take function.

**IMPORTANT:** This rewrite changes `parametric.atLeast` from a curried form `parametric.applyIncludes take.atLeast` (which returned an aspect with `__functor`) to a direct function `aspect: ctx: withIdentity ...`. Check all call sites to verify they pass both args. Key call sites:
- `ctx-apply.nix:92`: `parametric.atLeast stripped item.ctx` — already passes both args ✓
- `ctx-apply.nix:116` (old line): `parametric.atLeast` inside `fixedTo` — removed with deepRecurse
- `checkmate/modules/aspect-functor.nix`: uses `parametric.atLeast` — verify call pattern

- [ ] **Step 3: Verify `parametric.expands` callers**

Search for `parametric.expands` usage to confirm the new signature is compatible.

- [ ] **Step 4: Smoke test**

```bash
nix eval .#lib.parametric --override-input den . 2>&1 | head -20
```

- [ ] **Step 5: Commit**

```bash
nix develop -c just fmt
git add nix/lib/parametric.nix
git commit -c core.hooksPath=/dev/null -m "refactor: gut parametric.nix of legacy machinery

Remove withOwn, deepRecurse, deep, deepParametrics, applyDeep,
applyIncludes, statics imports. Rewrite fixedTo to eagerly apply
context values — fx pipeline handles recursion via emit-include."
```

---

## Task 4: Verify ctx-apply.nix compatibility

**Goal:** Verify `buildIncludes` works with the rewritten `fixedTo` (now produces static attrsets, not functors). No changes to `forward.nix` — the `fromAspect` hook stays.

**Files:**
- Verify: `nix/lib/ctx-apply.nix:90-92` (may not need changes)

**IMPORTANT:** `forward.nix:22` keeps its `fromAspect` branch unchanged. Many providers (`osConfigurations.nix`, `hmConfigurations.nix`, `os-user.nix`, template files) use `fromAspect` with proper context objects — NOT `lib.head aspect-chain`. Only the `aspect-chain`-dependent `fromAspect` implementations are removed from individual providers in Task 5.

**Acceptance Criteria:**
- [ ] `buildIncludes` works with static-attrset-producing `fixedTo`
- [ ] `forward.nix` is unchanged (fromAspect hook preserved for legitimate callers)

**Verify:** `nix eval .#lib --override-input den . 2>&1 | head -10`

**Steps:**

- [ ] **Step 1: Review ctx-apply.nix buildIncludes**

Current line 92:
```nix
(if isFirst then parametric.fixedTo item.ctx stripped else parametric.atLeast stripped item.ctx)
```

With the rewritten `fixedTo` and `atLeast`, both now return static attrsets (no functor). The call pattern is already correct:
- `parametric.fixedTo item.ctx stripped` — `fixedTo` is `attrs: aspect:` → `item.ctx stripped` ✓
- `parametric.atLeast stripped item.ctx` — `atLeast` is `aspect: ctx:` → `stripped item.ctx` ✓

Verify that `fxResolveTree` handles the static attrset output (no `__functor` on the result). Check `fxResolveTree`'s normalization — it passes static attrsets through unchanged to `fxResolve`, which is correct.

If no change is needed, document why and move on.

- [ ] **Step 2: Smoke test**

```bash
nix eval .#lib --override-input den . 2>&1 | head -20
```

- [ ] **Step 3: Commit (only if changes were needed)**

```bash
nix develop -c just fmt
git add nix/lib/ctx-apply.nix
git commit -c core.hooksPath=/dev/null -m "refactor: verify ctx-apply.nix works with rewritten fixedTo"
```

---

## Task 5: Remove aspect-chain from providers, templates, and home-env.nix

**Goal:** Remove `aspect-chain` destructuring and `fromAspect = _: lib.head aspect-chain` from provider modules, template files, and test files that use this pattern. Keep `fromAspect` where it uses proper context objects.

**Files:**
- Modify: `modules/aspects/provides/os-class.nix:18,27`
- Modify: `modules/aspects/provides/wsl.nix:41,49`
- Modify: `modules/outputs/flakeSystemOutputs.nix:17,29` (approx)
- Modify: `modules/aspects/provides/import-tree.nix:64,66`
- Modify: `modules/aspects/provides/unfree/unfree.nix:14`
- Modify: `nix/lib/home-env.nix:62`
- Modify: `templates/flake-parts-modules/modules/perSystem-forward.nix:6,11`
- Modify: `templates/nvf-standalone/modules/nvf-integration.nix:20,26`
- Modify: `templates/ci/modules/features/forward.nix:15,46`
- Modify: `templates/ci/modules/features/forward-alias-class.nix:15,84,136`
- Modify: `templates/ci/modules/features/guarded-forward.nix:33,65,112`
- Modify: `templates/ci/modules/features/forward-from-custom-class.nix:14,48,85,126,175`
- Modify: `templates/ci/modules/features/dynamic-intopath.nix:35,94`

**IMPORTANT:** `forward.nix:22` keeps its `fromAspect` hook — only the providers with `fromAspect = _: lib.head aspect-chain` lose their `fromAspect`. Providers using `fromAspect = _: den.ctx.host { inherit host; }` (osConfigurations, hmConfigurations, os-user) keep it.

**Acceptance Criteria:**
- [ ] No file references `aspect-chain` as a destructured arg (grep confirms zero matches)
- [ ] Providers that used `fromAspect = _: lib.head aspect-chain` no longer define `fromAspect`
- [ ] Providers using `fromAspect` with proper context objects are unchanged
- [ ] `home-env.nix` uses `{ class, ... }:` instead of `{ class, aspect-chain }:`
- [ ] `import-tree.nix` passes path directly (no `take.unused`)
- [ ] Template files updated

**Verify:** `nix eval .#lib --override-input den . 2>&1 | head -10`

**Steps:**

- [ ] **Step 1: Edit os-class.nix**

```nix
# Before:
os-class =
  { class, aspect-chain }:
  den.provides.forward {
    each = [ "nixos" "darwin" ];
    fromClass = _: "os";
    intoClass = lib.id;
    intoPath = _: [ ];
    fromAspect = _: lib.head aspect-chain;
  };

# After:
os-class =
  { class, ... }:
  den.provides.forward {
    each = [ "nixos" "darwin" ];
    fromClass = _: "os";
    intoClass = lib.id;
    intoPath = _: [ ];
  };
```

- [ ] **Step 2: Edit wsl.nix**

Same pattern: `{ class, aspect-chain }:` → `{ class, ... }:`, remove `fromAspect` line.

- [ ] **Step 3: Edit flakeSystemOutputs.nix**

Same pattern: `{ class, aspect-chain }:` → `{ class, ... }:`, remove `fromAspect` line.

- [ ] **Step 4: Edit import-tree.nix**

```nix
# Before:
den.provides.import-tree.__functor =
  _: root:
  { class, aspect-chain }:
  let
    path = den.lib.take.unused aspect-chain "${toString root}/_${class}";

# After:
den.provides.import-tree.__functor =
  _: root:
  { class, ... }:
  let
    path = "${toString root}/_${class}";
```

`take.unused` is defined as `_unused: used: used` — it's just identity on the second arg. So removing it and inlining the path is correct.

- [ ] **Step 5: Edit unfree.nix**

```nix
# Before:
__functor = _self: allowed-names: { class, aspect-chain }:

# After:
__functor = _self: allowed-names: { class, ... }:
```

`aspect-chain` was already unused in the body.

- [ ] **Step 6: Edit home-env.nix**

```nix
# Before (line 62):
{ class, aspect-chain }:

# After:
{ class, ... }:
```

`aspect-chain` was unused in the body — the function only references `host`, `user`, `ctxName`, and `class` (implicitly via includes).

- [ ] **Step 7: Edit template files**

**`templates/flake-parts-modules/modules/perSystem-forward.nix`:** `{ class, aspect-chain }:` → `{ class, ... }:`, remove `fromAspect = _: lib.head aspect-chain;`

**`templates/nvf-standalone/modules/nvf-integration.nix`:** Same pattern.

- [ ] **Step 8: Edit forward test files**

For each of these test files, apply the same pattern: `{ class, aspect-chain }:` → `{ class, ... }:`, remove `fromAspect = _: lib.head aspect-chain;`. For test files where the `fromAspect` lambda directly uses `aspect-chain` in the return value (e.g., `forward.nix:15` returns `{ src.names = ["forwarded"]; }`), just change the destructuring to `{ class, ... }:` — the `aspect-chain` binding was unused in the body.

Files:
- `templates/ci/modules/features/forward.nix:15,46`
- `templates/ci/modules/features/forward-alias-class.nix:15,84,136`
- `templates/ci/modules/features/guarded-forward.nix:33,65,112`
- `templates/ci/modules/features/forward-from-custom-class.nix:14,48,85,126,175`
- `templates/ci/modules/features/dynamic-intopath.nix:35,94`

Read each file first to understand how `aspect-chain` is used. In most cases it's only in the `fromAspect = _: lib.head aspect-chain` pattern. But some may use it differently — adapt accordingly.

- [ ] **Step 9: Verify no remaining aspect-chain references**

```bash
grep -rn "aspect-chain" nix/ modules/ templates/ --include="*.nix" | grep -v "\.md" | grep -v "# comment"
```

Should only show stale comments (addressed in Task 10), not code.

- [ ] **Step 10: Smoke test**

```bash
nix eval .#lib --override-input den . 2>&1 | head -20
```

- [ ] **Step 11: Commit**

```bash
nix develop -c just fmt
git add modules/aspects/provides/os-class.nix modules/aspects/provides/wsl.nix modules/outputs/flakeSystemOutputs.nix modules/aspects/provides/import-tree.nix modules/aspects/provides/unfree/unfree.nix nix/lib/home-env.nix templates/flake-parts-modules/modules/perSystem-forward.nix templates/nvf-standalone/modules/nvf-integration.nix templates/ci/modules/features/forward.nix templates/ci/modules/features/forward-alias-class.nix templates/ci/modules/features/guarded-forward.nix templates/ci/modules/features/forward-from-custom-class.nix templates/ci/modules/features/dynamic-intopath.nix
git commit -c core.hooksPath=/dev/null -m "refactor: remove aspect-chain from all providers, templates, and tests

Providers use { class, ... } instead of { class, aspect-chain }.
Only aspect-chain-dependent fromAspect removed — context-based fromAspect kept.
import-tree.nix inlines path (take.unused was identity)."
```

---

## Task 6: Clean up fx pipeline (remove aspect-chain compat shim)

**Goal:** Remove the `aspect-chain` compatibility shim from the fx pipeline's `constantHandler` and `mkPipeline` root override.

**Files:**
- Modify: `nix/lib/aspects/fx/pipeline.nix:50-61,96-102`

**Acceptance Criteria:**
- [ ] `defaultHandlers` no longer provides `"aspect-chain" = []`
- [ ] `mkPipeline` no longer overrides with `"aspect-chain" = [self]`
- [ ] Comments about aspect-chain compat updated/removed

**Verify:** `nix eval .#lib --override-input den . 2>&1 | head -10`

**Steps:**

- [ ] **Step 1: Edit pipeline.nix defaultHandlers**

Remove the `"aspect-chain" = [];` line and its comment from `defaultHandlers`:

```nix
# Before (lines 50-61):
defaultHandlers =
  { class, ctx }:
  handlers.constantHandler (
    ctx
    // {
      inherit class;
      "aspect-chain" = [ ];
    }
  )
  // ...

# After:
defaultHandlers =
  { class, ctx }:
  handlers.constantHandler (
    ctx
    // {
      inherit class;
    }
  )
  // ...
```

- [ ] **Step 2: Edit pipeline.nix mkPipeline**

Remove the root aspect-chain override:

```nix
# Before (lines 98-102):
rootHandlers =
  defaultHandlers { inherit class ctx; }
  // handlers.constantHandler {
    "aspect-chain" = [ self ];
  };

# After:
rootHandlers = defaultHandlers { inherit class ctx; };
```

Remove the stale comment about aspect-chain on lines 96-97.

- [ ] **Step 3: Smoke test**

```bash
nix eval .#lib --override-input den . 2>&1 | head -20
```

- [ ] **Step 4: Commit**

```bash
nix develop -c just fmt
git add nix/lib/aspects/fx/pipeline.nix
git commit -c core.hooksPath=/dev/null -m "refactor: remove aspect-chain compat shim from fx pipeline

constantHandler no longer provides aspect-chain.
Root override removed from mkPipeline.
Provider functions no longer expect aspect-chain."
```

---

## Task 7: Rewrite has-aspect.nix to use fx pipeline

**Goal:** Replace `resolve.withAdapter adapters.collectPaths` with fx pipeline's `fxFullResolve` and `state.pathSet`. This is the highest-risk user-facing API change.

**Files:**
- Modify: `nix/lib/aspects/has-aspect.nix` (full rewrite)
- Modify: `nix/lib/aspects/default.nix` (export adjustments if needed)

**Acceptance Criteria:**
- [ ] `collectPathSet` uses fx pipeline resolve, not legacy `resolve.withAdapter`
- [ ] `hasAspectIn` returns correct results for all test cases
- [ ] `mkEntityHasAspect` works with fx pipeline output
- [ ] `refKey` uses fx identity functions instead of legacy `adapters.aspectPath`/`pathKey`

**Verify:** `nix eval .#lib --override-input den . 2>&1 | head -10`

**Steps:**

- [ ] **Step 1: Rewrite has-aspect.nix**

```nix
# Query whether an aspect is structurally present in a resolved tree.
# Entity-facing wiring lives in modules/context/has-aspect.nix.
{ lib, den, ... }:
let
  inherit (den.lib.aspects.fx) identity;
  inherit (identity) aspectPath pathKey;

  # Validate a ref has both `name` and `meta` (aspectPath requires
  # both) and return its slash-joined path key.
  refKey =
    ref:
    if (ref ? name) && (ref ? meta) then
      pathKey (aspectPath ref)
    else
      throw "hasAspect: ref must have both `name` and `meta` (got ${builtins.typeOf ref}).";

  # Resolve tree via fx pipeline and extract the pathSet from state.
  # IMPORTANT: Uses fxResolveTree-equivalent normalization to handle raw
  # lambdas and functor attrsets that may arrive from entity configs.
  # fxResolve returns { imports }, but we need state.pathSet from fxFullResolve.
  # Inline the same root normalization that fxResolveTree does.
  collectPathSet =
    { tree, class }:
    let
      isRawFn = builtins.isFunction tree;
      isFunctor = builtins.isAttrs tree && tree ? __functor;
      functorArgs = if isFunctor then builtins.functionArgs (tree.__functor tree) else { };
      needsWrap = isRawFn || (isFunctor && functorArgs != { });
      normalized =
        if needsWrap then
          let
            innerFn = if isFunctor then tree.__functor tree else tree;
            innerArgs = if isFunctor then functorArgs else builtins.functionArgs innerFn;
          in
          {
            __functor = _: innerFn;
            __functionArgs = innerArgs;
            name = tree.name or "<function body>";
            meta = tree.meta or { };
            includes = tree.includes or [ ];
          }
        else
          tree;
      result = den.lib.aspects.fx.pipeline.fxFullResolve {
        inherit class;
        self = normalized;
        ctx = { };
      };
    in
    result.state.pathSet or { };

  hasAspectIn =
    {
      tree,
      class,
      ref,
    }:
    (collectPathSet { inherit tree class; }) ? ${refKey ref};

  mkEntityHasAspect =
    {
      tree,
      primaryClass,
      classes,
    }:
    let
      setFor = builtins.listToAttrs (
        map (c: {
          name = c;
          value = collectPathSet {
            inherit tree;
            class = c;
          };
        }) (lib.unique ([ primaryClass ] ++ classes))
      );
      check = class: ref: (setFor.${class} or { }) ? ${refKey ref};
      bareFn = check primaryClass;
    in
    {
      __functor = _: bareFn;
      forClass = check;
      forAnyClass = ref: lib.any (c: check c ref) classes;
    };
in
{
  inherit
    hasAspectIn
    collectPathSet
    mkEntityHasAspect
    ;
}
```

Key changes:
- Import `identity.{aspectPath, pathKey}` from fx instead of `adapters.{pathKey, toPathSet, aspectPath}`
- `collectPathSet` uses `fx.pipeline.fxFullResolve` and reads `result.state.pathSet` directly
- `refKey` uses `identity.aspectPath` and `identity.pathKey` (same logic, different module)
- `fxFullResolve` needs `self = tree` — verify this matches what `fxResolveTree` does (the root normalization). `collectPathSet` may need to go through `fxResolveTree` instead of `fxFullResolve` to get the root wrapping. Check if `tree` is already a resolved aspect or needs normalization.

`collectPathSet` now inlines the same root normalization as `fxResolveTree` — it handles raw lambdas and functor attrsets. This avoids needing to export `fxFullResolve` through `default.nix` while ensuring correctness regardless of the input shape.

- [ ] **Step 2: Check has-aspect.nix callers**

Search for `mkEntityHasAspect`, `hasAspectIn`, `collectPathSet` usage to verify the `tree` argument shape.

- [ ] **Step 3: Smoke test**

```bash
nix eval .#lib --override-input den . 2>&1 | head -20
```

- [ ] **Step 4: Commit**

```bash
nix develop -c just fmt
git add nix/lib/aspects/has-aspect.nix nix/lib/aspects/default.nix
git commit -c core.hooksPath=/dev/null -m "refactor: rewrite has-aspect.nix to use fx pipeline pathSet

Replace resolve.withAdapter + adapters.collectPaths with
fxFullResolve + state.pathSet. Uses fx identity functions."
```

---

## Task 8: Remove fxPipeline=false from all test files

**Goal:** Remove `den.fxPipeline = false;` from all test files that set it. Tests must work on the fx-only pipeline.

**Files:**
- Modify: ~28 test files under `templates/ci/modules/features/` and `templates/ci/modules/features/deadbugs/`

**Acceptance Criteria:**
- [ ] No test file sets `den.fxPipeline = false`
- [ ] No test file references `den.fxPipeline` at all

**Verify:** `grep -r "fxPipeline" templates/ | wc -l` → 0

**Steps:**

- [ ] **Step 1: Bulk-remove fxPipeline lines**

For each file that contains `den.fxPipeline = false;`, remove that line. The affected files (from grep earlier):

```
templates/ci/modules/features/deadbugs/issue-460-parametric-dedup.nix
templates/ci/modules/features/deadbugs/issue-448-mixed-merge.nix
templates/ci/modules/features/provider-provenance.nix
templates/ci/modules/features/top-level-parametric.nix
templates/ci/modules/features/has-aspect-lib.nix
templates/ci/modules/features/has-aspect.nix
templates/ci/modules/features/identity-preservation.nix
templates/ci/modules/features/aspect-path.nix
templates/ci/modules/features/cross-context-forward.nix
templates/ci/modules/features/deadbugs/cybolic-routes.nix
templates/ci/modules/features/deadbugs/issue-254-ctx-hm-user-includes.nix
templates/ci/modules/features/deadbugs/issue-261-parametric-aspect-from-remote-namespace.nix
templates/ci/modules/features/deadbugs/issue-292-hm-used-when-no-mutual-enabled.nix
templates/ci/modules/features/deadbugs/issue-297-mutual-not-including-host-owned-and-included-statics.nix
templates/ci/modules/features/deadbugs/issue-311-nested-includes-are-parametric.nix
templates/ci/modules/features/deadbugs/issue-369-namespace-system-scoped-inputs.nix
templates/ci/modules/features/deadbugs/issue-423-static-sub-aspect-parametric-parent.nix
templates/ci/modules/features/deadbugs/issue-442-parametric-included-by-parametric.nix
templates/ci/modules/features/deadbugs/static-include-dup-package.nix
templates/ci/modules/features/default-includes.nix
templates/ci/modules/features/flake-parts.nix
templates/ci/modules/features/fx-integration.nix
```

Also check `fx-integration.nix` — if it tests both paths, it may need rewriting.

For each file: read it, find the `den.fxPipeline = false;` line, remove it. If the line is `den.fxPipeline = true;`, also remove it (the option no longer exists).

- [ ] **Step 2: Handle has-aspect.nix test Section F**

Section F (lines ~442-542) tests `meta.adapter` interactions with `hasAspect`. These use `den.lib.aspects.adapters.excludeAspect`, `substituteAspect`, `oneOfAspects` — all from the deleted `adapters.nix`.

Rewrite these tests to use fx constraint equivalents:
- `adapters.excludeAspect ref` → `den.lib.aspects.fx.constraints.exclude ref` on `meta.handleWith`
- `adapters.substituteAspect ref replacement` → `den.lib.aspects.fx.constraints.substitute ref replacement` on `meta.handleWith`
- `adapters.oneOfAspects [...]` → use `includeIf` or constraint-based equivalent

If the fx equivalents don't map cleanly, these tests may need to be redesigned or some may be deleted if the behavior being tested was legacy-only.

- [ ] **Step 3: Handle has-aspect-lib.nix**

Tests reference `adapters.collectPaths`, `adapters.aspectPath`, `adapters.excludeAspect`, `resolve.withAdapter`. All legacy APIs. Rewrite to test the new `has-aspect.nix` functions directly:
- `hasAspectIn` — same API, just uses fx internally
- `collectPathSet` — same API
- `mkEntityHasAspect` — same API
- `refKey` — internal, test via `hasAspectIn`
- Remove tests for `adapters.aspectPath` (now in `fx.identity.aspectPath`)

- [ ] **Step 4: Rewrite aspect-path.nix**

`templates/ci/modules/features/aspect-path.nix` sets `den.fxPipeline = false` on all 11 tests and calls `den.lib.aspects.adapters.aspectPath` directly. Both the option and the module are gone. Rewrite to use `den.lib.aspects.fx.identity.aspectPath` (same logic, different location):

```nix
# Before:
expr = den.lib.aspects.adapters.aspectPath den.aspects.foo;
# After:
expr = den.lib.aspects.fx.identity.aspectPath den.aspects.foo;
```

Remove `den.fxPipeline = false` from all test cases.

- [ ] **Step 5: Handle issue-369 (CRASHES with fx)**

`templates/ci/modules/features/deadbugs/issue-369-namespace-system-scoped-inputs.nix` has 3 tests marked `# CRASHES with fx`. These test `self'` and `inputs'` provider includes which crash in the fx pipeline. Options:
1. If the crash is a known bug to fix later: mark tests with `skip = true` or delete them with a comment referencing the issue
2. If the crash is fixable: investigate and fix
3. If the feature is no longer supported: delete the tests

Read the file, reproduce the crash, diagnose. At minimum, the `den.fxPipeline = false` line must be removed. If the tests can't pass on fx-only, skip or delete them with an explanatory comment.

- [ ] **Step 6: Handle other test adjustments**

Some tests may reference `den.lib.aspects.adapters` for non-hasAspect uses. Search and fix:
```bash
grep -r "adapters\." templates/ci/modules/features/ --include="*.nix"
```

- [ ] **Step 7: Verify**

```bash
grep -r "fxPipeline" templates/ | wc -l
# Should be 0

grep -r "den.lib.aspects.adapters" templates/ | wc -l
# Should be 0
```

- [ ] **Step 8: Commit**

```bash
nix develop -c just fmt
git add templates/ci/modules/features/
git commit -c core.hooksPath=/dev/null -m "test: remove fxPipeline=false and rewrite legacy adapter tests

All tests run on fx-only pipeline.
has-aspect tests rewritten to use fx constraints.
has-aspect-lib tests use new fx-based APIs."
```

---

## Task 9: Run full test suite and fix failures

**Goal:** All tests pass on the fx-only pipeline. Fix any remaining breakages from the cascade of changes.

**Files:** Various (determined by test failures)

**Acceptance Criteria:**
- [ ] `nix develop -c just ci ""` passes all tests
- [ ] No references to deleted files remain
- [ ] `nix flake check` passes

**Verify:** `nix develop -c just ci ""` → all tests pass

**Steps:**

- [ ] **Step 1: Run full test suite**

```bash
nix develop -c just ci ""
```

- [ ] **Step 2: For each failure, diagnose and fix**

Common expected failures:
1. **Tests referencing `den.lib.aspects.adapters`** — update to use fx equivalents or delete if legacy-only
2. **Tests expecting `__functor` on aspects** — update expectations (aspects are plain attrsets now)
3. **Tests expecting `aspect-chain` in resolved output** — remove those assertions
4. **Provider functions failing due to missing `aspect-chain` arg** — verify all providers were updated in Task 5
5. **`fixedTo` shape mismatch** — the fx pipeline's `fxResolveTree` normalization may need adjustment for the new static-attrset output from `fixedTo` (no longer a functor)
6. **`checkmate/modules/aspect-functor.nix`** — may need updates if it tests `defaultFunctor` behavior

- [ ] **Step 3: Fix fxResolveTree normalization if needed**

After Task 3's `fixedTo` rewrite, the output is a static attrset (no `__functor`). `fxResolveTree` currently has special handling for functor attrsets. With `fixedTo` producing statics, the `needsWrap` logic should pass them through unchanged. Verify this is correct:

```nix
# fxResolveTree: isFunctor = resolved ? __functor → false for static attrsets
# needsWrap = isRawFn || (isFunctor && functorArgs != {}) → false
# → passes through to fxResolve unchanged ✓
```

- [ ] **Step 4: Run tests again after fixes**

```bash
nix develop -c just ci ""
```

Iterate until all pass.

- [ ] **Step 5: Final verification**

```bash
nix flake check
```

- [ ] **Step 6: Commit any remaining fixes**

```bash
nix develop -c just fmt
# git add specific files that were fixed
git commit -c core.hooksPath=/dev/null -m "fix: resolve test failures from legacy pipeline removal"
```

---

## Task 10: Final cleanup and documentation

**Goal:** Remove stale comments, update documentation references, clean up any remaining legacy artifacts.

**Files:** Various

**Acceptance Criteria:**
- [ ] No comments reference `defaultFunctor`, `deepRecurse`, `aspect-chain` (as a pipeline concept), or legacy resolve
- [ ] `fxResolveTree` comments are accurate for post-removal state
- [ ] No dead code remains

**Verify:** `grep -rn "deepRecurse\|defaultFunctor\|legacyResolve\|aspect-chain" nix/ modules/ --include="*.nix" | grep -v "\.md"` → minimal/zero hits

**Steps:**

- [ ] **Step 1: Search for stale references**

```bash
grep -rn "deepRecurse\|defaultFunctor\|legacyResolve\|statics\.nix\|resolve\.nix\|adapters\.nix" nix/ modules/ --include="*.nix"
grep -rn "aspect-chain" nix/ modules/ --include="*.nix"
```

- [ ] **Step 2: Update stale comments**

Fix any comments that reference removed concepts. Key locations:
- `fxResolveTree` in `default.nix` — comments about `deepRecurse`, `defaultFunctor`
- `pipeline.nix` — comments about aspect-chain compat
- `handlers/include.nix` — `wrapChild` comments about `deepRecurse` wrappers

- [ ] **Step 3: Verify no dead exports**

Check that `default.nix` exports don't reference removed items:
- `adapters` should not be exported
- `mkAspectsType` still works (passes empty cnf or user-provided cnf')

- [ ] **Step 4: Final test run**

```bash
nix develop -c just ci ""
nix flake check
```

- [ ] **Step 5: Commit**

```bash
nix develop -c just fmt
# git add specific files
git commit -c core.hooksPath=/dev/null -m "chore: clean up stale comments and dead references"
```

---

## Dependency Graph

```
Task 0 (baseline)
  └─► Task 1 (delete legacy files + gate)
       └─► Task 2 (strip defaultFunctor from types + checkmate)
            └─► Task 3 (gut parametric.nix, rewrite fixedTo)
                 ├─► Task 4 (verify ctx-apply compat — forward.nix UNCHANGED)
                 │    └─► Task 5 (providers + templates + forward tests + home-env)
                 │         └─► Task 6 (fx pipeline: remove aspect-chain shim)
                 └─► Task 7 (rewrite has-aspect.nix with root normalization)
                      └─┐
                         └─► Task 8 (remove fxPipeline=false, rewrite legacy tests)
                              └─► Task 9 (fix test failures)
                                   └─► Task 10 (cleanup stale comments)
```

Tasks 4-6 and Task 7 can run in parallel after Task 3.
Task 8 depends on BOTH Task 6 and Task 7 completing.
Tasks 9-10 are sequential.

## Review-Identified Risks

These items were flagged during plan review and must be carefully handled:

1. **`parametric.expands` semantic change (Task 3):** Old code merged runtime ctx with bound attrs. New code eagerly applies only bound attrs. If includes need both, the pipeline's constantHandler may not have the bound attrs. Verify against `parametric.nix` and `parametric-context.nix` tests.

2. **`providerFnType.merge` multi-module composition (Task 2):** The old merge routed through `aspectType.merge`. The simplified direct merge may drop composition for providers defined across multiple modules. Verify no multi-module providers exist before simplifying.

3. **`issue-369` tests crash on fx (Task 8):** Three tests marked "CRASHES with fx" — these test `self'`/`inputs'` provider includes. Must be investigated, fixed, or explicitly skipped.

4. **`forward.nix` fromAspect hook MUST stay (Task 4-5):** `osConfigurations.nix`, `hmConfigurations.nix`, `os-user.nix` all use `fromAspect` with proper context objects. Only the `lib.head aspect-chain` pattern is removed from individual providers.
