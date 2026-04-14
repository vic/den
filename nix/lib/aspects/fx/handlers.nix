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
    ;
}
