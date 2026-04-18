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
      isFunctor = builtins.isAttrs resolved && resolved ? __functor;
      functorArgs = if isFunctor then builtins.functionArgs (resolved.__functor resolved) else { };
      # Only wrap functors whose inner function has named args (e.g. deepRecurse's
      # { class, aspect-chain }). Plain aspects with default functor (lib.const,
      # bare args) go through compileStatic directly.
      needsWrap = isFunctor && functorArgs != { };
      wrapped =
        if needsWrap then
          {
            __functor = _: resolved.__functor resolved;
            __functionArgs = functorArgs;
            name = resolved.name or "<function body>";
            meta = resolved.meta or { };
            includes = resolved.includes or [ ];
          }
        else
          resolved;
      # Extract __ctx from ctxApply-tagged aspects. These carry context values
      # (host, user, etc.) that the pipeline's constantHandler needs to provide
      # to nested parametric includes.
      ctx = resolved.__ctx or { };
    in
    fx.pipeline.fxResolve {
      inherit class ctx;
      self = wrapped;
    };

  types = lib.mapAttrs (_: v: v { }) rawTypes;
in
{
  inherit types fx;
  resolve = fxResolveTree;
  inherit (hasAspect) hasAspectIn collectPathSet mkEntityHasAspect;
  mkAspectsType = cnf': lib.mapAttrs (_: v: v cnf') rawTypes;
}
