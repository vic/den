{
  lib,
  den,
  fx,
  ...
}:
let
  # Build handler set from parametric context.
  # Each key in ctx becomes a handler that resumes with the value.
  parametricHandler =
    ctx:
    builtins.mapAttrs (
      _: value:
      { param, state }:
      {
        resume = value;
        inherit state;
      }
    ) ctx;

  # Handle class and aspect-chain effects.
  staticHandler =
    { class, aspect-chain }:
    {
      "class" =
        { param, state }:
        {
          resume = class;
          inherit state;
        };
      "aspect-chain" =
        { param, state }:
        {
          resume = aspect-chain;
          inherit state;
        };
    };

  # Merge parametric + static into a single handler set.
  contextHandlers =
    {
      ctx,
      class,
      aspect-chain,
    }:
    parametricHandler ctx // staticHandler { inherit class aspect-chain; };

  # Build diagnostic error for unhandled effect (missing context arg).
  missingArgError =
    { ctx, aspectName }:
    effectName:
    let
      available = builtins.attrNames ctx ++ [
        "class"
        "aspect-chain"
      ];
    in
    throw "aspect '${aspectName}' requires '${effectName}' but context only provides: ${toString available}";

  # Dedup handler. Tracks seen keys in state.seen.
  ctxSeenHandler = {
    "ctx-seen" =
      { param, state }:
      let
        isFirst = !((state.seen or { }) ? ${param});
      in
      {
        resume = { inherit isFirst; };
        state = state // {
          seen = (state.seen or { }) // {
            ${param} = true;
          };
        };
      };
  };

  # Provider resolution. Looks up provides chains.
  ctxProviderHandler = {
    "ctx-provider" =
      { param, state }:
      let
        inherit (param)
          kind
          self
          ctx
          key
          prev
          prevCtx
          ;
      in
      if kind == "self" then
        {
          resume = self.provides.${self.name} or null;
          inherit state;
        }
      else if kind == "cross" && prev != null then
        let
          pathHead = lib.head (lib.splitString "." key);
          provFn = prev.provides.${pathHead} or null;
        in
        {
          resume = if provFn != null then provFn prevCtx else null;
          inherit state;
        }
      else
        {
          resume = null;
          inherit state;
        };
  };

  # Traverse handler. Default: proceed (resume null).
  ctxTraverseHandler = {
    "ctx-traverse" =
      { param, state }:
      {
        resume = null;
        inherit state;
      };
  };

  # Tracing variant of ctx-traverse handler. Accumulates ctxTrace items
  # and sets currentStage/currentKind in state for structuredTraceHandler.
  ctxTraceHandler = {
    "ctx-traverse" =
      { param, state }:
      let
        ctx = if builtins.isAttrs param.ctx then param.ctx else { };
        ctxKeys = builtins.attrNames ctx;
        entityNames = lib.concatMap (
          k:
          let
            v = ctx.${k} or null;
          in
          lib.optional (builtins.isAttrs v && v ? name) {
            kind = k;
            name = v.name;
            aspect = v.aspect or v.name;
          }
        ) ctxKeys;
        item = {
          key = param.key;
          selfName = param.self.name or "<anon>";
          prevName = if param.prev != null then param.prev.name or "<anon>" else null;
          hasSelfProvider = (param.self.provides or { }) ? ${param.self.name or ""};
          hasCrossProvider =
            param.prev != null && (param.prev.provides or { }) ? ${lib.head (lib.splitString "." param.key)};
          inherit ctxKeys entityNames;
          provideNames = builtins.attrNames (param.self.provides or { });
        };
      in
      {
        resume = null;
        state = state // {
          ctxTrace = (state.ctxTrace or [ ]) ++ [ item ];
          currentStage = param.key;
          currentKind = "aspect";
        };
      };
  };

  # Default ctx-provide handler: pass aspect through.
  # Tracing handlers can intercept to track provider contributions.
  ctxEmitHandler = {
    "ctx-emit" =
      { param, state }:
      {
        resume = param.aspect;
        inherit state;
      };
  };

  # Adapter registry. Handles register-adapter and check-exclusion effects.
  # Supports identity-based (exclude, substitute) and predicate-based (filter).
  adapterRegistryHandler = {
    "register-adapter" =
      { param, state }:
      if param.type == "filter" then
        {
          resume = null;
          state = state // {
            adapterFilters = (state.adapterFilters or [ ]) ++ [
              {
                predicate = param.predicate;
                owner = param.owner or "<anon>";
              }
            ];
          };
        }
      else
        {
          resume = null;
          state = state // {
            adapterRegistry = (state.adapterRegistry or { }) // {
              ${param.identity} = {
                type = param.type;
                getReplacement = param.getReplacement or (_: null);
                owner = param.owner or "<anon>";
              };
            };
          };
        };

    # Check if an aspect should be excluded/substituted/filtered.
    # First checks identity-based registry, then predicate filters.
    # param = { identity; aspect; } where aspect is the full attrset
    # for predicate evaluation.
    "check-exclusion" =
      { param, state }:
      let
        identity = param.identity or param;
        aspect = param.aspect or null;
        registry = state.adapterRegistry or { };
        filters = state.adapterFilters or [ ];
      in
      if registry ? ${identity} then
        let
          entry = registry.${identity};
        in
        if entry.type == "exclude" then
          {
            resume = {
              action = "exclude";
              owner = entry.owner;
            };
            inherit state;
          }
        else if entry.type == "substitute" then
          {
            resume = {
              action = "substitute";
              replacement = entry.getReplacement null;
              owner = entry.owner;
            };
            inherit state;
          }
        else
          {
            resume = {
              action = "keep";
            };
            inherit state;
          }
      else
        # No identity match — check predicate filters.
        let
          failedFilter =
            if aspect != null then lib.findFirst (f: !(f.predicate aspect)) null filters else null;
        in
        if failedFilter != null then
          {
            resume = {
              action = "exclude";
              owner = failedFilter.owner;
            };
            inherit state;
          }
        else
          {
            resume = {
              action = "keep";
            };
            inherit state;
          };
  };

  # Accumulates class modules from provide-class effects.
  provideClassHandler = {
    "provide-class" =
      { param, state }:
      let
        identity = param.identity or "<anon>";
        mod = lib.setDefaultModuleLocation "${param.class}@${identity}" param.module;
      in
      {
        resume = null;
        state = state // {
          imports = (state.imports or [ ]) ++ [ mod ];
        };
      };
  };

in
{
  inherit
    parametricHandler
    staticHandler
    contextHandlers
    missingArgError
    ctxSeenHandler
    ctxProviderHandler
    ctxTraverseHandler
    ctxTraceHandler
    ctxEmitHandler
    adapterRegistryHandler
    provideClassHandler
    ;
}
