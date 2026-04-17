# into-transition handler — processes context transitions with scoped sub-computations.
# Handles: into-transition
# Sends: ctx-seen (dedup), resolve-complete (missing transition tombstone),
#        then aspectToEffect in scoped constantHandler(parentCtx // newCtx)
# State reads: currentCtx
# External dependency: den.ctx (context aspect registry, looked up by transition path)
{
  lib,
  den,
  ...
}:
let
  fx = den.lib.fx;
  inherit (den.lib.aspects.fx.handlers) constantHandler;
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

  # Resolve a single context value by running aspectToEffect in a scoped handler.
  resolveContextValue =
    parentCtx: targetAspect: results: newCtx:
    let
      scopedCtx = parentCtx // newCtx;
    in
    fx.bind (fx.effects.scope.stateful (constantHandler scopedCtx) (aspectToEffect targetAspect)) (
      childResult: fx.pure (results ++ [ childResult ])
    );

  # Resolve a single transition: look up target aspect, check dedup, resolve each context value.
  resolveTransition =
    currentCtx: results: transition:
    let
      key = lib.concatStringsSep "/" transition.path;
      # den.ctx is the global context aspect registry (e.g. den.ctx.user, den.ctx.host).
      # If the transition targets a path not in the registry, emit a diagnostic tombstone.
      targetAspect = lib.attrByPath transition.path null (den.ctx or { });
    in
    if targetAspect == null then
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
            fx.bind acc (innerResults: resolveContextValue currentCtx targetAspect innerResults newCtx)
          ) (fx.pure results) transition.contexts
      );

  transitionHandler = {
    "into-transition" =
      { param, state }:
      let
        currentCtx = state.currentCtx or { };
        intoResult = param.intoFn currentCtx;
        transitions = flattenInto intoResult [ ];
      in
      {
        resume = builtins.foldl' (
          acc: transition: fx.bind acc (results: resolveTransition currentCtx results transition)
        ) (fx.pure [ ]) transitions;
        inherit state;
      };
  };

in
{
  inherit transitionHandler;
}
