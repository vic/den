# Standalone emit-include handler — owns recursion via aspectToEffect.
# Handles: emit-include
# Sends: check-constraint, resolve-complete, get-path-set (via resolveConditional)
# State reads: (none directly — delegates to other handlers via effects)
{
  lib,
  den,
  ...
}:
let
  fx = den.lib.fx;
  identity = den.lib.aspects.fx.identity;
  inherit (den.lib.aspects.fx.aspect) aspectToEffect emitIncludes;

  # Normalize a NixOS module function ({ config, lib, ... }: ...) into an aspect
  # attrset by running it through the type system's merge. This extracts class keys
  # (nixos, homeManager, etc.) from the module's return value.
  # Coupling note: this is the only handler-layer reference to den.lib.aspects.types.
  normalizeModuleFn =
    child:
    den.lib.aspects.types.aspectType.merge
      [ (child.name or "<deferred>") ]
      [
        {
          file = "<deferred>";
          value = child;
        }
      ];

  # Wrap bare function includes in an aspect envelope.
  wrapChild =
    child:
    if lib.isFunction child then
      (
        # For attrset-with-functor children, extract the actual inner function
        # to get the real args for bind.fn resolution. This bypasses stale
        # __functionArgs on the attrset and gives aspectToEffect the correct
        # isParametric decision — whether it's a deepRecurse wrapper needing
        # { class, aspect-chain } or a raw parametric aspect needing { host }.
        if builtins.isAttrs child then
          let
            innerFn = child.__functor child;
            # innerFn may be a function (parametric) or a value (factory functor).
            innerArgs = if builtins.isFunction innerFn then builtins.functionArgs innerFn else { };
          in
          child
          // {
            __functor = _: if builtins.isFunction innerFn then innerFn else _: innerFn;
            __functionArgs = innerArgs;
            includes = child.includes or [ ];
          }
        else
          let
            args = lib.functionArgs child;
            # NixOS module functions are deferred modules, not parametric aspects.
            isModuleFn = den.lib.canTake.upTo {
              lib = true;
              config = true;
              options = true;
            } child;
          in
          if isModuleFn then
            normalizeModuleFn child
          else
            {
              name = child.name or "<anon>";
              meta = child.meta or { };
              __functor = _: child;
              __functionArgs = args;
              includes = [ ];
            }
      )
    else
      child;

  tombstoneAll =
    aspects:
    builtins.foldl' (
      acc: a:
      fx.bind acc (
        results:
        let
          ts = identity.tombstone a { guardFailed = true; };
        in
        fx.bind (fx.send "resolve-complete" ts) (_: fx.pure (results ++ [ ts ]))
      )
    ) (fx.pure [ ]) aspects;

  # Handle includeIf guards via get-path-set.
  resolveConditional =
    condNode:
    fx.bind (fx.send "get-path-set" null) (
      pathSet:
      let
        guardCtx = {
          hasAspect = ref: pathSet ? ${identity.pathKey (identity.aspectPath ref)};
        };
        pass = condNode.meta.guard guardCtx;
      in
      if pass then emitIncludes condNode.meta.aspects else tombstoneAll condNode.meta.aspects
    );

  # Exclude: create tombstone and emit resolve-complete.
  excludeChild =
    child: owner:
    let
      ts = identity.tombstone child { excludedFrom = owner; };
    in
    fx.bind (fx.send "resolve-complete" ts) (_: fx.pure [ ts ]);

  # Substitute: tombstone original, resolve replacement via aspectToEffect.
  substituteChild =
    child: decision:
    let
      ts = identity.tombstone child {
        excludedFrom = decision.owner;
        replacedBy = decision.replacement.name or "<anon>";
      };
    in
    fx.bind (fx.send "resolve-complete" ts) (
      _:
      fx.bind (aspectToEffect decision.replacement) (
        resolved:
        fx.pure [
          ts
          resolved
        ]
      )
    );

  handlers = den.lib.aspects.fx.handlers;

  # Keep: resolve via aspectToEffect (which emits resolve-complete internally).
  # If the child carries __ctx (from parametric.bindCtx), install a scoped
  # constantHandler via scope.run so nested parametric includes get context
  # values (host, user, etc.). Uses scope.run (not scope.stateful) because
  # constantHandler only provides values — outer state from rotated effects
  # (emit-class, chain-push, etc.) is preserved.
  keepChild =
    child:
    let
      comp = aspectToEffect child;
      hasCtx = builtins.isAttrs child && child ? __ctx && child.__ctx != { };
    in
    if hasCtx then
      fx.bind (fx.effects.scope.run { handlers = handlers.constantHandler child.__ctx; } comp) (
        resolved: fx.pure [ resolved ]
      )
    else
      fx.bind comp (resolved: fx.pure [ resolved ]);

  # Derive a stable name for anonymous aspects from parent chain + index.
  nameAnon =
    state: idx:
    let
      chain = state.includesChain or [ ];
      parent = if chain == [ ] then "<root>" else lib.last chain;
    in
    "${parent}/<anon>:${toString idx}";

  isMeaningfulName =
    name: name != "<anon>" && name != "<function body>" && !(lib.hasPrefix "[definition " name);

  # The handler. param is { child, idx } from emitIncludes.
  includeHandler = {
    "emit-include" =
      { param, state }:
      let
        rawChild = param.child or param;
        idx = param.idx or null;
        wrapped = wrapChild rawChild;
        # Replace anonymous names with parent+index derived identity.
        child =
          if idx != null && !(isMeaningfulName (wrapped.name or "<anon>")) then
            wrapped // { name = nameAnon state idx; }
          else
            wrapped;
        childIdentity = identity.pathKey (identity.aspectPath child);
        isConditional = builtins.isAttrs child && child ? meta && child.meta ? guard;
      in
      {
        resume =
          if isConditional then
            resolveConditional child
          else
            fx.bind
              (fx.send "check-constraint" {
                identity = childIdentity;
                aspect = child;
              })
              (
                decision:
                if decision.action == "exclude" then
                  excludeChild child decision.owner
                else if decision.action == "substitute" then
                  substituteChild child decision
                else
                  keepChild child
              );
        inherit state;
      };
  };

in
{
  inherit includeHandler wrapChild;
}
