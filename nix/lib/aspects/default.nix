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
      # builtins.isFunction is false for functor attrsets (sets with __functor).
      # Handle both raw lambdas and functors — forward.nix's fromAspect returns
      # fixedTo-wrapped aspects which are functor attrsets needing parametric resolution.
      # Only wrap functors whose inner function has named args (e.g. deepRecurse's
      # { class, aspect-chain }) — the default functor takes bare `ctx` (args={})
      # and should go through compileStatic to preserve class keys.
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

  types = lib.mapAttrs (_: v: v { }) rawTypes;
in
{
  inherit types fx;
  resolve = fxResolveTree;
  inherit (hasAspect) hasAspectIn collectPathSet mkEntityHasAspect;
  mkAspectsType = cnf': lib.mapAttrs (_: v: v cnf') rawTypes;
}
