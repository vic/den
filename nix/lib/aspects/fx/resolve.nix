{
  lib,
  den,
  fx,
  aspect,
  handlers,
  ...
}:
let
  inherit (aspect) wrapAspect;
  inherit (handlers) contextHandlers missingArgError;

  # Keys that are structural (part of the identity envelope),
  # not owned configuration.
  structuralKeys = [
    "includes"
    "__functor"
    "__functionArgs"
    "name"
    "meta"
  ];

  # Wrap a resolved body in the identity envelope.
  # Takes name/meta from the original aspectVal,
  # includes + owned config from the resolved body.
  wrapIdentity =
    { aspectVal, resolved }:
    let
      owned = removeAttrs resolved structuralKeys;
      includes = resolved.includes or [ ];
      meta = aspectVal.meta or { };
    in
    {
      name = aspectVal.name or "<anon>";
      meta = {
        adapter = meta.adapter or null;
        provider = meta.provider or [ ];
      };
      inherit includes;
    }
    // owned;

  # Resolve a single aspect against the given context.
  # Static aspects pass through directly.
  # Parametric aspects (with __functor) are interpreted via fx.handle.
  resolveOne =
    {
      ctx,
      class,
      aspect-chain,
    }:
    aspectVal:
    let
      fn = if aspectVal ? __functor then aspectVal.__functor aspectVal else null;
      isStatic = fn == null || !lib.isFunction fn;

      body =
        if isStatic then
          aspectVal
        else
          let
            comp = wrapAspect ctx fn;
            allHandlers = contextHandlers { inherit ctx class aspect-chain; };
            result = fx.handle {
              handlers = allHandlers;
              state = { };
            } comp;
          in
          result.value;
    in
    wrapIdentity {
      inherit aspectVal;
      resolved = body;
    };

  # Strict variant: uses rotate topology to detect missing context args.
  # Known effects are handled by rotate; unknowns are re-suspended.
  # After rotate, we check isPure — if not, the aspect requires an arg
  # not present in ctx, and we throw a diagnostic error.
  resolveOneStrict =
    {
      ctx,
      class,
      aspect-chain,
    }:
    aspectVal:
    let
      fn = if aspectVal ? __functor then aspectVal.__functor aspectVal else null;
      isStatic = fn == null || !lib.isFunction fn;
      aspectName = aspectVal.name or "<anon>";

      body =
        if isStatic then
          aspectVal
        else
          let
            comp = wrapAspect ctx fn;
            knownHandlers = contextHandlers { inherit ctx class aspect-chain; };

            # Inner: handle known context args, rotate unknowns outward
            rotated = fx.rotate {
              handlers = knownHandlers;
              state = { };
            } comp;

            errorForEffect = missingArgError { inherit ctx aspectName; };
          in
          if fx.isPure rotated then
            # All effects handled. rotated.value = { value; state; } from rotate's return clause.
            rotated.value.value
          else
            # Unhandled effect: the aspect needs something not in ctx.
            errorForEffect rotated.effect.name;
    in
    wrapIdentity {
      inherit aspectVal;
      resolved = body;
    };

  # Recursively resolve an aspect and all its includes.
  # Uses resolveOne by default. Pass strict = true to use resolveOneStrict
  # for diagnostic errors on missing context args.
  resolveDeep =
    {
      ctx,
      class,
      aspect-chain,
      strict ? false,
    }:
    let
      resolver = (if strict then resolveOneStrict else resolveOne) { inherit ctx class aspect-chain; };
      go =
        aspectVal:
        let
          resolved = resolver aspectVal;
          resolvedIncludes = map (
            child:
            if lib.isFunction child then
              # Bare function include (e.g. { host, ... }: { ... }) — wrap
              # in a minimal aspect envelope so resolveOne can handle it.
              let
                childAspect = {
                  name = child.name or "<anon>";
                  meta = child.meta or { };
                  __functor = _: child;
                  __functionArgs = lib.functionArgs child;
                  includes = [ ];
                };
              in
              go childAspect
            else if builtins.isAttrs child && child ? name then
              # Named aspect (has envelope shape) — recurse
              go child
            else if builtins.isAttrs child then
              # Plain attrset config — pass through
              child
            else
              # Shouldn't happen in well-formed trees, but pass through
              child
          ) (resolved.includes or [ ]);
        in
        resolved // { includes = resolvedIncludes; };
    in
    go;

in
{
  inherit
    resolveOne
    resolveOneStrict
    resolveDeep
    wrapIdentity
    ;
}
