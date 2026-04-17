{
  lib,
  den,
  ...
}:
let
  inherit (den.lib.aspects.fx.identity) aspectPath pathKey;

  # Derive parent from includesChain, filtering out self-references.
  # The chain contains raw identity strings from chain-push (pathKey of aspectPath).
  #
  # In structuredTraceHandler: selfPath is the raw pathKey — filter is effective
  # for meaningful nodes whose identity matches a chain entry.
  #
  # In tracingHandler: selfFullPath may be a disambiguated name (e.g.,
  # "host/resolve(desktop):provider") for anonymous nodes. Since anonymous nodes
  # don't push to the chain, the filter is a no-op for them — which is correct.
  # The filter only matters for meaningful (chain-pushing) nodes where
  # selfFullPath == raw pathKey.
  chainParent =
    chain: selfPath:
    let
      filtered = builtins.filter (p: p != selfPath) chain;
    in
    if filtered == [ ] then null else lib.last filtered;

  # Shared entry fields for both trace handlers.
  mkBaseEntry =
    class: param:
    {
      inherit class;
      provider = param.meta.provider or [ ];
      excluded = param.meta.excluded or false;
      excludedFrom = param.meta.excludedFrom or null;
      replacedBy = param.meta.replacedBy or null;
      isProvider = (param.meta.provider or [ ]) != [ ];
      handlers = param.meta.handleWith or [ ];
      hasClass = param ? ${class};
      isParametric = param.meta.isParametric or false;
      fnArgNames = param.meta.fnArgNames or [ ];
    };

  # Minimal trace handler — accumulates entries without disambiguation.
  # Use for tests that verify basic parent/entry structure.
  # For full tracing with anonymous entry disambiguation, use tracingHandler.
  structuredTraceHandler = class: {
    "resolve-complete" =
      { param, state }:
      let
        selfPath = pathKey (aspectPath param);
        entry = mkBaseEntry class param // {
          name = param.name or "<anon>";
          parent = chainParent (state.includesChain or [ ]) selfPath;
          ctxStage = param.__ctxStage or null;
          ctxKind = param.__ctxKind or null;
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
  # Module collection is handled by classCollectorHandler via emit-class effects.
  # Use as extraHandlers with mkPipeline.
  #
  # Disambiguates anonymous entries using context stage tags, matching the
  # legacy structuredTrace adapter's naming: stage/kind(aspect):provider.
  tracingHandler = class: {
    "resolve-complete" =
      { param, state }:
      let
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
        entry = mkBaseEntry class param // {
          inherit name ctxStage ctxKind;
          parent = chainParent (state.includesChain or [ ]) selfFullPath;
        };
      in
      {
        resume = param;
        state =
          state
          // {
            entries = (state.entries or [ ]) ++ [ entry ];
          }
          // lib.optionalAttrs (param ? __ctxStage) {
            currentStage = param.__ctxStage;
            currentKind = param.__ctxKind or null;
            currentCtxAspect = param.__ctxAspect or null;
          };
      };
  };

in
{
  inherit structuredTraceHandler tracingHandler;
}
