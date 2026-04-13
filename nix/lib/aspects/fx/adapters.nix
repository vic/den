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
        mods =
          if param ? ${class} && !(param.meta.excluded or false) then
            [
              (lib.setDefaultModuleLocation "${class}@${param.name or "<anon>"}" param.${class})
            ]
          else
            [ ];
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

  includeIf = guardFn: aspects: {
    name = "<includeIf>";
    meta = {
      conditional = true;
      guard = guardFn;
      aspects = aspects;
    };
    includes = [ ];
  };

  # Non-effectful walk of raw includes tree. Collects aspectPaths from
  # all named aspects (skips conditionals, bare functions without name).
  # Used to back hasAspect guards.
  collectRawPaths =
    includes:
    lib.concatMap (
      child:
      if builtins.isAttrs child && child ? name && !(child.meta.conditional or false) then
        [ (aspectPath child) ] ++ collectRawPaths (child.includes or [ ])
      else
        [ ]
    ) includes;

  # Trace handler that accumulates structured entries for each resolved aspect.
  # Reads __ctxStage/__ctxKind from provider-tagged aspects (set by ctxApply),
  # falls back to state.currentStage/currentKind (set by ctxTraceHandler).
  structuredTraceHandler = class: {
    "resolve-complete" =
      { param, state }:
      let
        entry = {
          name = param.name or "<anon>";
          inherit class;
          parent = param.__parent or null;
          provider = param.meta.provider or [ ];
          excluded = param.meta.excluded or false;
          excludedFrom = param.meta.excludedFrom or null;
          replacedBy = param.meta.replacedBy or null;
          isProvider = (param.meta.provider or [ ]) != [ ];
          hasAdapter = (param.meta.adapter or null) != null;
          hasClass = param ? ${class};
          isParametric = param.meta.isParametric or false;
          fnArgNames = param.meta.fnArgNames or [ ];
          ctxStage = param.__ctxStage or (state.currentStage or null);
          ctxKind = param.__ctxKind or (state.currentKind or null);
        };
      in
      {
        resume = param;
        state = state // {
          entries = (state.entries or [ ]) ++ [ entry ];
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
    includeIf
    collectRawPaths
    structuredTraceHandler
    ;
}
