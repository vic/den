{
  lib,
  den,
  fx,
  ...
}:
let
  aspectPath = a: (a.meta.provider or [ ]) ++ [ (a.name or "<anon>") ];

  pathKey = path: lib.concatStringsSep "/" path;

  toPathSet =
    paths:
    builtins.listToAttrs (
      builtins.map (p: {
        name = pathKey p;
        value = true;
      }) paths
    );

  tombstone = resolved: extra: {
    name = "~${resolved.name or "<anon>"}";
    meta =
      (resolved.meta or { })
      // {
        excluded = true;
        originalName = resolved.name or "<anon>";
      }
      // extra;
    includes = [ ];
  };

  excludeAspect =
    ref:
    let
      refPath = aspectPath ref;
    in
    {
      "resolve-include" =
        { param, state }:
        let
          ap = aspectPath param;
        in
        if ap == refPath || lib.take (builtins.length refPath) ap == refPath then
          {
            resume = [ (tombstone param { excludedFrom = state.ownerName or "<anon>"; }) ];
            inherit state;
          }
        else
          {
            resume = [ param ];
            inherit state;
          };
    };

  substituteAspect =
    ref: replacement:
    let
      refPath = aspectPath ref;
    in
    {
      "resolve-include" =
        { param, state }:
        if aspectPath param == refPath then
          {
            resume = [
              (tombstone param {
                excludedFrom = state.ownerName or "<anon>";
                replacedBy = replacement.name or "<anon>";
              })
              replacement
            ];
            inherit state;
          }
        else
          {
            resume = [ param ];
            inherit state;
          };
    };

in
{
  inherit
    aspectPath
    pathKey
    toPathSet
    tombstone
    excludeAspect
    substituteAspect
    ;
}
