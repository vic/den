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
  inherit (handlers) contextHandlers;

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

  # Recursively resolve an aspect and all its includes.
  resolveDeep =
    {
      ctx,
      class,
      aspect-chain,
    }:
    let
      go =
        aspectVal:
        let
          resolved = resolveOne { inherit ctx class aspect-chain; } aspectVal;
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
  inherit resolveOne resolveDeep wrapIdentity;
}
