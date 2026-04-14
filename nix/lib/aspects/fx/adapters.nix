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

  excludeAspect = ref: {
    type = "exclude";
    identity = pathKey (aspectPath ref);
  };

  substituteAspect = ref: replacement: {
    type = "substitute";
    identity = pathKey (aspectPath ref);
    replacementName = replacement.name or "<anon>";
    getReplacement = _: replacement;
  };

  # Predicate-based filter. Excludes aspects where pred returns false.
  # pred receives the aspect attrset (with name, meta, includes, etc).
  filterAspect = pred: {
    type = "filter";
    predicate = pred;
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

  # Handler for get-path-set effect. Returns accumulated paths as a set.
  pathSetHandler = {
    "get-path-set" =
      { param, state }:
      let
        paths = state.paths or [ ];
        ps = toPathSet paths;
      in
      {
        resume = ps;
        inherit state;
      };
  };

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

  # Combined resolve-complete handler for tracing: collects trace entries and paths.
  # Module collection is handled by provideClassHandler via provide-class effects.
  # Use as extraHandlers with mkPipeline.
  #
  # Disambiguates anonymous entries using context stage tags, matching the
  # legacy structuredTrace adapter's naming: stage/kind(aspect):provider.
  tracingHandler = class: {
    "resolve-complete" =
      { param, state }:
      let
        isExcluded = param.meta.excluded or false;
        rawName = param.meta.originalName or param.name or "<anon>";
        provPath = lib.concatStringsSep "/" (param.meta.provider or [ ]);
        ctxStage = param.__ctxStage or (state.currentStage or null);
        ctxKind = param.__ctxKind or (state.currentKind or null);
        ctxAspect = param.__ctxAspect or (state.currentCtxAspect or null);
        meaningful =
          n: n != "<anon>" && n != "<function body>" && !(lib.hasPrefix "[definition " n) && n != null;
        isAnon = !meaningful rawName;
        name =
          if isAnon && ctxStage != null then
            let
              stage = ctxStage;
              kind = if ctxKind != null then ctxKind else "resolve";
              aspectTag = if ctxAspect != null then "(${ctxAspect})" else "";
              provTag = lib.optionalString (provPath != "") ":${provPath}";
            in
            "${stage}/${kind}${aspectTag}${provTag}"
          else
            rawName;
        selfFullPath = if provPath != "" then "${provPath}/${name}" else name;
        # Filter parent: skip self-references and anonymous intermediates.
        # Fall back to last meaningful parent tracked in state.
        rawParent = param.__parent or null;
        parent =
          if rawParent == null then
            null
          else if rawParent == selfFullPath then
            state.lastMeaningfulParent or null
          else if !meaningful (lib.last (lib.splitString "/" rawParent)) then
            state.lastMeaningfulParent or null
          else
            rawParent;
        entry = {
          inherit name class parent;
          provider = param.meta.provider or [ ];
          excluded = isExcluded;
          excludedFrom = param.meta.excludedFrom or null;
          replacedBy = param.meta.replacedBy or null;
          isProvider = (param.meta.provider or [ ]) != [ ];
          hasAdapter = (param.meta.adapter or null) != null;
          hasClass = param ? ${class};
          isParametric = param.meta.isParametric or false;
          fnArgNames = param.meta.fnArgNames or [ ];
          inherit ctxStage ctxKind;
        };
      in
      {
        resume = param;
        state =
          state
          // {
            paths = (state.paths or [ ]) ++ (lib.optional (!isExcluded) (aspectPath param));
            entries = (state.entries or [ ]) ++ [ entry ];
          }
          // lib.optionalAttrs (meaningful name) { lastMeaningfulParent = selfFullPath; }
          // lib.optionalAttrs (param ? __ctxStage) {
            currentStage = param.__ctxStage;
            currentKind = param.__ctxKind or null;
            currentCtxAspect = param.__ctxAspect or null;
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
    filterAspect
    collectPathsHandler
    includeIf
    pathSetHandler
    structuredTraceHandler
    tracingHandler
    ;
}
