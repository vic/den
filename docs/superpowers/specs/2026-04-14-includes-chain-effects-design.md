# Includes Chain Effects — Design Spec

**Date:** 2026-04-14
**Branch:** `feat/fx-diagram-integration`
**Status:** Draft

## Problem

The fx pipeline conflates two distinct provenance chains:

- **Definition path (B):** Where an aspect is defined — `meta.provider + name`. Set at definition time by the type system, preserved through `withIdentity`/`wrapIdentity`. Used for identity, exclusion keying, `provide-class`.
- **Includes path (A):** Why an aspect is in evaluation — who included it. Currently approximated by a single `__parent` string derived from definition-path identity during tree walking.

`__parent` is set in `resolveChild` using `parentPath`, which collapses anonymous wrapper nodes via `selfPath = if isMeaningful then rawSelfPath else parentPath`. This loses information when `deepRecurse`/`parametric.fixedTo` create multiple anonymous intermediate nodes between named aspects.

The legacy `structuredTrace` avoids this by carrying the full `aspect-chain` and post-filtering to the nearest meaningful ancestor. The fx pipeline has no equivalent.

`__parent` is referenced in 5 files (all must be updated):
- `nix/lib/aspects/fx/resolve.nix` — 6 emissions in `resolveChild`, `resolveConditional`, `mkPipeline`
- `nix/lib/aspects/fx/adapters.nix` — 2 reads in `structuredTraceHandler` and `tracingHandler`
- `nix/lib/diag/default.nix` — 1 emission (root resolve-complete)
- `templates/diag-fx-demo/modules/fx-debug.nix` — 1 emission (root resolve-complete)
- `templates/ci/modules/features/fx-parametric-meta.nix` — 1 read (test assertion)

Additionally, adapters (exclude/substitute) are currently global within the pipeline. The legacy pipeline scoped adapters to the subtree of the declaring aspect. There is no mechanism to support both behaviors.

## Design

### Core: chain-push / chain-pop effects

The includes path becomes an observable effect protocol. `go` in `resolveDeepEffectful` emits `chain-push` when entering a meaningful node's subtree and `chain-pop` when leaving.

Anonymous nodes (wrappers from `deepRecurse`, bare lambdas) are transparent — no push/pop. Their children see the same chain as the anonymous node itself. Anonymous leaf nodes that never resolve to a named aspect get identity projected from the chain head (nearest meaningful ancestor).

### Changes by file

#### `nix/lib/aspects/fx/resolve.nix`

**`go` function (lines ~148-233):**

- Remove `parentPath` parameter. `go` takes only `aspectVal`.
- After `resolveOne` returns `resolved`, compute `isMeaningful` as before.
- If meaningful: emit `chain-push { identity = rawSelfPath; }` before `resolveChildren`, emit `chain-pop null` after.
- If anonymous: call `resolveChildren` directly, no push/pop.
- Remove `selfPath` computation (no longer needed).

```nix
go = aspectVal:
  bind (resolveOne { inherit ctx class; aspect-chain = []; } aspectVal) (resolved:
    let
      rawSelfPath = adapters.pathKey (adapters.aspectPath resolved);
      rawName = resolved.name or "<anon>";
      isMeaningful =
        rawName != "<anon>" && rawName != "<function body>"
        && !(lib.hasPrefix "[definition " rawName);
      includes = map tagChild (resolved.includes or []);
    in
    bind classEmit (_:
      bind registerEmit (_:
        if isMeaningful then
          bind (send "chain-push" { identity = rawSelfPath; }) (_:
            resolveChildren includes (resolvedIncludes:
              bind (send "chain-pop" null) (_:
                pure (resolved // { includes = resolvedIncludes; })
              )
            )
          )
        else
          resolveChildren includes (resolvedIncludes:
            pure (resolved // { includes = resolvedIncludes; })
          )
      )
    )
  );
```

**`resolveChild` (lines ~237-289):**

- Remove `parentPath` parameter from `resolveChild` signature.
- Remove `__parent = parentPath` from all `resolve-complete` emissions. The handler derives parent from chain state.
- `resolveChildren` no longer passes `parentPath` to `resolveChild`.

**`resolveConditional` (lines ~291-330):**

- Same treatment — remove `parentPath` parameter, remove `__parent` from `resolve-complete`.

**`mkPipeline` (lines ~405-450):**

- Root `resolve-complete` no longer needs `__parent = null` — empty chain produces `parent = null` in the handler.
- Add `chainHandler` to `defaultHandlers`.
- Add `includesChain = []` to `defaultState`.

#### `nix/lib/aspects/fx/handlers.nix`

**New `chainHandler`:**

```nix
chainHandler = {
  "chain-push" = { param, state }: {
    resume = null;
    state = state // {
      includesChain = (state.includesChain or []) ++ [ param.identity ];
    };
  };
  "chain-pop" = { param, state }:
    let chain = state.includesChain or []; in {
    resume = null;
    state = state // {
      includesChain = if chain == [] then [] else lib.init chain;
    };
  };
};
```

An empty-list guard on `chain-pop` prevents `lib.init []` from throwing. This should never fire if push/pop is balanced, but provides a safe degradation path if handler composition reorders effects.

**`adapterRegistryHandler` changes:**

`register-adapter`: stamp `ownerChain = state.includesChain or []` on each adapter entry (both identity-based and filter-based).

`check-exclusion`: for scoped adapters, verify the adapter's `ownerChain` is a prefix of the current `state.includesChain`. For global adapters, skip the ancestry check.

```nix
isAncestor = ownerChain: currentChain:
  lib.take (builtins.length ownerChain) currentChain == ownerChain;
```

Identity-based check becomes:
```nix
if registry ? ${identity} then
  let entry = registry.${identity}; in
  if entry.scope == "global"
     || isAncestor entry.ownerChain currentChain
  then
    # apply exclusion/substitution
  else
    # identity matched but out of scope — fall through to filters
    checkFilters
```

Filter-based check applies the same scoping:
```nix
# Only test filters whose owner is an ancestor of the current node
applicableFilters = builtins.filter (f:
  f.scope == "global" || isAncestor f.ownerChain currentChain
) filters;
failedFilter = if aspect != null
  then lib.findFirst (f: !(f.predicate aspect)) null applicableFilters
  else null;
```

Each filter entry gets `ownerChain` at registration time:
```nix
"register-adapter" = { param, state }:
  if param.type == "filter" then {
    resume = null;
    state = state // {
      adapterFilters = (state.adapterFilters or []) ++ [{
        predicate = param.predicate;
        owner = param.owner or "<anon>";
        scope = param.scope or "subtree";
        ownerChain = state.includesChain or [];
      }];
    };
  } else {
    # ... identity-based registration, also stamps ownerChain ...
  };
```

#### `nix/lib/aspects/fx/adapters.nix`

**`structuredTraceHandler` (lines ~93-120):**

- Remove `parent = param.__parent or null` at line 100.
- Read parent from state: `parent = let chain = state.includesChain or []; in if chain == [] then null else lib.last chain;`

**`tracingHandler` (lines ~128-183):**

- Remove `parent = param.__parent or null` at line 154.
- Read parent from state, same as above.
- No other changes to trace entry structure.

**Adapter API functions:**

```nix
excludeAspect = ref: {
  type = "exclude";
  scope = "subtree";
  identity = pathKey (aspectPath ref);
};

excludeAspect.global = ref: {
  type = "exclude";
  scope = "global";
  identity = pathKey (aspectPath ref);
};

substituteAspect = ref: replacement: {
  type = "substitute";
  scope = "subtree";
  identity = pathKey (aspectPath ref);
  replacementName = replacement.name or "<anon>";
  getReplacement = _: replacement;
};

substituteAspect.global = ref: replacement: {
  type = "substitute";
  scope = "global";
  identity = pathKey (aspectPath ref);
  replacementName = replacement.name or "<anon>";
  getReplacement = _: replacement;
};

filterAspect = pred: {
  type = "filter";
  scope = "subtree";
  predicate = pred;
};

filterAspect.global = pred: {
  type = "filter";
  scope = "global";
  predicate = pred;
};
```

#### `nix/lib/diag/default.nix`

Line 176 emits `resolve-complete` with `__parent = null` for the root node. Remove `__parent = null` — empty chain state produces `parent = null` in the handler.

#### `templates/diag-fx-demo/modules/fx-debug.nix`

Line 15 emits `resolve-complete` with `__parent = null`. Same treatment as `diag/default.nix`.

#### `templates/ci/modules/features/fx-parametric-meta.nix`

Line 136 reads `param.__parent or "ROOT"` from `resolve-complete` params to test parent tracking. Update to read from `state.includesChain`:

```nix
parent = let chain = state.includesChain or []; in
  if chain == [] then "ROOT" else lib.last chain;
parents = (state.parents or []) ++ [ parent ];
```

Line 154 assertion comment references `__parent` — update to reference chain-derived parent.

#### `nix/lib/diag/graph.nix`

No changes needed. Graph construction reads `parent` from trace entries, which the handlers now derive correctly from chain state.

### What stays unchanged

- **Definition identity** (`meta.provider + name`) — untouched
- **`wrapIdentity` / `withIdentity`** — untouched
- **`wrapChild`** — untouched
- **Context tag propagation** (`__ctxStage`, `__ctxKind`, `__ctxAspect`) — still folded by `tagChild`
- **`provide-class` effect** — still uses definition identity
- **`resolveOne` / `resolveOneStrict`** — untouched
- **`ctxApplyEffectful`** — untouched

### Anonymous node handling

Anonymous nodes are transparent to the chain:

1. **Wrapper around a named child** (e.g., `deepRecurse` scaffolding): No push/pop. The named child pushes its own identity when `go` processes it. The wrapper is invisible in the chain.

2. **Bare lambda leaf** (e.g., `{ host, ... }: { nixos = ...; }`): No push/pop. At `resolve-complete`, the handler reads `last chain` as parent — the nearest meaningful ancestor. The `tracingHandler` still disambiguates the name using ctx stage tags (`host/aspect(desktop)`), giving it a trace identity derived from context.

In both cases, the anonymous node doesn't corrupt the chain. Its ancestor's identity covers it until a named descendant appears.

### Adapter scoping semantics

- `excludeAspect ref` (default, scoped): Excludes `ref` only within the subtree of the aspect that declared the adapter. If `desktop` excludes `foo`, only `foo` included through `desktop`'s subtree is excluded. A sibling aspect that also includes `foo` is unaffected.

- `excludeAspect.global ref`: Excludes `ref` everywhere in the pipeline, regardless of where it's included. This is the power tool for pipeline-wide exclusions.

- Same pattern for `substituteAspect` and `filterAspect`.

- **Root-registered scoped adapters** are effectively global: `isAncestor [] anyChain` is always true (empty prefix matches everything). This is correct — the root aspect is the ancestor of the entire tree. Authors who want to emphasize intent can use `excludeAspect.global` explicitly, but the behavior is the same.

### Diagram observability

Chain effects are observable by any handler. This enables:

- **Sequence diagrams:** `chain-push`/`chain-pop` map to activation bars on lifelines. Resolution order and nesting depth are explicit without reconstruction.
- **Scope visualization:** A handler can observe adapter registration alongside the current chain, showing scope boundaries in diagrams.
- **Composable analysis:** Depth tracking, per-subtree counts, cycle detection — all addable as handlers without touching `go`.

### Edge cases

**Multiple ctx stages for one aspect:** Each `parametric.fixedTo` wrapper creates a separate resolution path. Each path's subtree gets its own push/pop sequence with the correct chain at that point. The `tracingHandler` sees different chain states, giving correct parents.

**Root node:** Empty chain at `resolve-complete` → `parent = null`. No special casing needed.

**Conditional nodes (`includeIf`):** `resolveConditional` calls `resolveChild` for each guarded include. Same as regular children — `resolveChild` calls `go`, which handles push/pop internally.

**Substituted nodes:** Tombstone emits `resolve-complete` with current chain (correct parent). Replacement emits `resolve-complete` with current chain (correct parent — same subtree as the original).

### Verification

After implementation, the existing debug module (`templates/diag-fx-demo/modules/fx-debug.nix`) compares fx vs legacy parent assignments. Success criteria:

```
nix eval --json --override-input den path:. path:./templates/diag-fx-demo#debug
```

For every aspect, the fx parent list should match the legacy parent list. The diagram output (`just ci` / `nix flake check`) should show correct edges with no bidirectional links from parent confusion.

All 471 existing checks must continue to pass.
