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
        # isParametric decision.
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
      if pass then emitIncludes { } condNode.meta.aspects else tombstoneAll condNode.meta.aspects
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
  # Context is provided either by __ctx on the child (data-driven, from
  # transitions or parent propagation) or by the root constantHandler.
  #
  # For parametric children, probe each required arg via probe-arg effect.
  # Args already in child.__ctx are known-available and skip probing.
  # Unresolvable includes are skipped (resolved at deeper context level).
  keepChild =
    child:
    let
      childArgs = child.__functionArgs or { };
      childCtx = child.__ctx or { };
      isParametric = childArgs != { } && child ? __functor;
    in
    if isParametric then
      let
        # Only probe args not already provided by __ctx.
        unresolvedKeys = builtins.filter (k: !(builtins.hasAttr k childCtx)) (builtins.attrNames childArgs);
        _t = builtins.trace "keepChild: ${child.name or "?"} args=${toString (builtins.attrNames childArgs)} __ctx=${toString (builtins.attrNames childCtx)} hasZ=${toString (childCtx ? z)} unresolved=${toString unresolvedKeys}";
        probeArgs =
          keys:
          if keys == [ ] then
            fx.pure true
          else
            let
              key = builtins.head keys;
              rest = builtins.tail keys;
            in
            fx.bind (fx.send "probe-arg" key) (
              isAvailable: if isAvailable then probeArgs rest else fx.pure false
            );
      in
      _t (
        fx.bind (probeArgs unresolvedKeys) (
          allAvailable:
          let
            _t2 = builtins.trace "keepChild: ${child.name or "?"} allAvailable=${toString allAvailable}";
          in
          _t2 (
            if allAvailable then
              fx.bind (aspectToEffect child) (resolved: fx.pure [ resolved ])
            else
              fx.pure [ ]
          )
        )
      )
    else
      fx.bind (aspectToEffect child) (resolved: fx.pure [ resolved ]);

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

  # The handler. param is { child, idx, parentCtx? } from emitIncludes.
  includeHandler = {
    "emit-include" =
      { param, state }:
      let
        rawChild = param.child or param;
        idx = param.idx or null;
        parentCtx = param.parentCtx or { };
        wrapped = wrapChild rawChild;
        # Propagate parent's __ctx to child (child's own __ctx takes precedence).
        withCtx =
          if parentCtx != { } then wrapped // { __ctx = parentCtx // (wrapped.__ctx or { }); } else wrapped;
        # Replace anonymous names with parent+index derived identity.
        child =
          if idx != null && !(isMeaningfulName (withCtx.name or "<anon>")) then
            withCtx // { name = nameAnon state idx; }
          else
            withCtx;
        _ti = builtins.trace "includeHandler: name=${child.name or "?"} parentCtx=${toString (builtins.attrNames parentCtx)} __ctx=${
          toString (builtins.attrNames (child.__ctx or { }))
        } isParametric=${toString ((child.__functionArgs or { }) != { } && child ? __functor)}";
        childIdentity = identity.pathKey (identity.aspectPath child);
        isConditional = builtins.isAttrs child && child ? meta && child.meta ? guard;
      in
      _ti {
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
