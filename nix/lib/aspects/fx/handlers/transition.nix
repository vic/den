# into-transition handler — processes context transitions via __ctx tagging.
# Handles: into-transition
# Sends: ctx-seen (dedup), resolve-complete (missing transition tombstone),
#        then aspectToEffect with __ctx-tagged target aspects.
# Cross-providers: if source.provides.${targetKey} exists, it's tagged and resolved alongside.
# State reads: currentCtx
# External dependency: den.ctx (context aspect registry, looked up by transition path)
#
# Context propagation: instead of scope.run (which isolates state), transitions
# tag target aspects with __ctx. aspectToEffect reads __ctx and scopes only the
# bind.fn call, letting all other effects (emit-class, constraints, chain, paths)
# reach root handlers with shared state.
{
  lib,
  den,
  ...
}:
let
  fx = den.lib.fx;
  inherit (den.lib.aspects.fx.aspect) aspectToEffect;

  # Flatten a nested into attrset into a flat list of { path, contexts }.
  flattenInto =
    attrset: prefix:
    lib.concatLists (
      lib.mapAttrsToList (
        name: v:
        let
          path = prefix ++ [ name ];
        in
        if builtins.isList v then
          [
            {
              inherit path;
              contexts = v;
            }
          ]
        else
          flattenInto v path
      ) attrset
    );

  # Resolve a single context value by tagging the target aspect with __ctx
  # and resolving it directly. No scope.run — context flows as data.
  resolveContextValue =
    parentCtx: targetAspect: results: newCtx:
    let
      scopedCtx = parentCtx // newCtx;
      tagged = targetAspect // {
        __ctx = scopedCtx;
      };
      _t = builtins.trace "resolveContextValue: target=${targetAspect.name or "?"} __ctx=${toString (builtins.attrNames scopedCtx)}";
    in
    _t (fx.bind (aspectToEffect tagged) (childResult: fx.pure (results ++ [ childResult ])));

  # Resolve a single transition: look up target aspect, check dedup, resolve each context value.
  # Also emits cross-providers: if sourceAspect.provides.${targetKey} exists,
  # that provider is resolved in the scoped context (e.g. flake-system.provides.flake-packages).
  resolveTransition =
    sourceAspect: currentCtx: results: transition:
    let
      key = lib.concatStringsSep "/" transition.path;
      targetKey = lib.last transition.path;
      targetAspect = lib.attrByPath transition.path null (den.ctx or { });
      sourceProvides = sourceAspect.provides or { };
      crossProvider = sourceProvides.${targetKey} or null;
      # Emit cross-provider result by tagging with __ctx and resolving directly.
      emitCrossProvider =
        scopedCtx: prevResults:
        if crossProvider != null then
          let
            crossResult = crossProvider scopedCtx;
            # Wrap bare functions as parametric aspects for aspectToEffect.
            wrapped =
              if lib.isFunction crossResult && !builtins.isAttrs crossResult then
                {
                  name = "${sourceAspect.name or "?"}.provides.${targetKey}";
                  meta = { };
                  __functor = _: crossResult;
                  __functionArgs = lib.functionArgs crossResult;
                  __ctx = scopedCtx;
                  includes = [ ];
                }
              else
                crossResult // { __ctx = scopedCtx; };
          in
          fx.bind (aspectToEffect wrapped) (crossResolved: fx.pure (prevResults ++ [ crossResolved ]))
        else
          fx.pure prevResults;
    in
    if targetAspect == null && crossProvider == null then
      # No target ctx node and no cross-provider — emit tombstone.
      let
        ts = {
          name = "~<missing-transition:${key}>";
          meta = {
            excluded = true;
            transitionMissing = true;
            transitionPath = key;
          };
          includes = [ ];
        };
      in
      fx.bind (fx.send "resolve-complete" ts) (_: fx.pure (results ++ [ ts ]))
    else
      fx.bind (fx.send "ctx-seen" key) (
        { isFirst }:
        if !isFirst then
          fx.pure results
        else
          builtins.foldl' (
            acc: newCtx:
            fx.bind acc (
              innerResults:
              let
                scopedCtx = currentCtx // newCtx;
                withTarget =
                  if targetAspect != null then
                    resolveContextValue currentCtx targetAspect innerResults newCtx
                  else
                    fx.pure innerResults;
              in
              fx.bind withTarget (targetResults: emitCrossProvider scopedCtx targetResults)
            )
          ) (fx.pure results) transition.contexts
      );

  transitionHandler = {
    "into-transition" =
      { param, state }:
      let
        sourceAspect = param.self;
        # currentCtx is wrapped in a thunk (_: ctx) to survive deepSeq.
        rootCtx = (state.currentCtx or (_: { })) null;
        # Merge __ctx from the source aspect (transition-provided context)
        # with root ctx. This is how nested transitions get their parent's
        # context: flake → flake-system (with { system }) → flake-packages.
        currentCtx = rootCtx // (sourceAspect.__ctx or { });
        intoResult = param.intoFn currentCtx;
        transitions = flattenInto intoResult [ ];
      in
      {
        resume = builtins.foldl' (
          acc: transition: fx.bind acc (results: resolveTransition sourceAspect currentCtx results transition)
        ) (fx.pure [ ]) transitions;
        inherit state;
      };
  };

in
{
  inherit transitionHandler;
}
