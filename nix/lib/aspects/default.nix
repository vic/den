{
  lib,
  den,
  inputs,
  ...
}:
let
  rawTypes = import ./types.nix { inherit den lib; };
  adapters = import ./adapters.nix { inherit den lib; };
  legacyResolve = import ./resolve.nix { inherit den lib; };
  hasAspect = import ./has-aspect.nix { inherit den lib; };
  fx = import ./fx { inherit den lib; };

  fxEnabled = den.fxPipeline or true;

  # When fxPipeline is enabled, resolve uses the unified aspectToEffect pipeline.
  # Raw functions (e.g. { class, aspect-chain }: ...) can reach resolve from
  # forward.nix's fromAspect. Wrap them so aspectToEffect handles them as parametric.
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

  resolve = if fxEnabled then fxResolveTree else legacyResolve;

  # defaultFunctor is baked into the aspect type system (types.nix:178).
  # It uses parametric.withOwn which creates { class, aspect-chain } functors.
  # The fx pipeline provides aspect-chain = [] via constantHandler as a compat shim.
  # TODO: Replace with a simpler functor when the legacy pipeline is removed.
  defaultFunctor = (den.lib.parametric { }).__functor;
  typesConf = { inherit defaultFunctor; };
  types = lib.mapAttrs (_: v: v typesConf) rawTypes;
in
{
  inherit
    types
    adapters
    resolve
    fx
    ;
  inherit (hasAspect) hasAspectIn collectPathSet mkEntityHasAspect;
  mkAspectsType = cnf': lib.mapAttrs (_: v: v (typesConf // cnf')) rawTypes;
}
