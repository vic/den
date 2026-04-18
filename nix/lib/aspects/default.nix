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
      isBareFn = lib.isFunction resolved && !builtins.isAttrs resolved;
      isFunctor = !isBareFn && builtins.isAttrs resolved && resolved ? __functor;
      functorArgs = if isFunctor then builtins.functionArgs (resolved.__functor resolved) else { };
      needsWrap = isFunctor && functorArgs != { };
      wrapped =
        # Bare functions (e.g. { class, ... }: { ... }) → wrap as parametric aspect.
        if isBareFn then
          {
            __functor = _: resolved;
            __functionArgs = lib.functionArgs resolved;
            name = "<bare-fn>";
            meta = { };
            includes = [ ];
          }
        else if needsWrap then
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
