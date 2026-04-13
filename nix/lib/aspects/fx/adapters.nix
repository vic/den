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

  moduleHandler = class: {
    "resolve-complete" =
      { param, state }:
      let
        mods = if param ? ${class} && !(param.meta.excluded or false) then [ param.${class} ] else [ ];
      in
      {
        resume = param;
        state = state // {
          imports = (state.imports or [ ]) ++ mods;
        };
      };
  };

  collectPathsHandler = {
    "resolve-complete" =
      { param, state }:
      let
        isExcluded = param.meta.excluded or false;
      in
      {
        resume = param;
        state = state // {
          paths = (state.paths or [ ]) ++ (lib.optional (!isExcluded) (aspectPath param));
        };
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
    moduleHandler
    collectPathsHandler
    ;
}
